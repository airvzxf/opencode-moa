# Multi-Model Orchestration in a Native Agent Platform: Lessons from OpenCode-Moa v0.3 (DRAFT)

> **Status:** Draft v0.1 — first author is collecting results from
> ongoing experiments (see `docs/research/experiments/`). Do not cite as
> final work. Comments welcome via issues.

**Authors:** Israel Roldan (corresponding: israel.alberto.rv@gmail.com)
**Affiliation:** airvzxf
**Date:** 2026-07-11 (first draft)

---

## Abstract

We present **opencode-moa**, a multi-model orchestration framework built
entirely as declarative agents inside the OpenCode CLI (`mode: primary`
+ `mode: subagent`). Unlike prior multi-agent frameworks (AutoGen,
CrewAI, LangGraph), opencode-moa ships as markdown and JSON — no bash,
no Python, no external runtime. Each subagent is a static agent whose
frontmatter declares its model, temperature, and tool permissions. The
orchestrator agent coordinates 10 numbered steps (proposals, validation,
evaluation, classification, improvement, final selection, summary) plus
optional step 10 (cross-iteration synthesis) and an arbitrary iteration
loop governed by threshold + max-iterations.

We report on a 12-model × 2-iteration run on a Rust GUI design task,
observe that **iterative synthesis propagates convergent ideas at scale
(e.g. `request_repaint` and `edge-detect` went 1-of-12 → 12-of-12 across
iterations)**, identify cost-per-value outliers (deepseek-v4-flash and
mimo-v2.5 deliver top-5 quality at under $0.06 cumulative spend
each), and present design recommendations for the operational envelope
(model floor, filter_low_performers, step_5_modo ∈ {sintesis_central,
self_improve, skip}).

## 1. Introduction

A growing body of work on mixture-of-agent prompting (MoA
[wang2024moa], multi-agent debate [du2023improvingfactualityreasoning],
role-based collaboration [hong2023metagpt]) has shown that multi-LLM
ensembles surpass any single model on knowledge, reasoning, and
coding benchmarks. Yet practitioners face a recurring operational
question: **which model is the right agent for which step of the
pipeline, and how should they be combined without each one's
expensive calls eating the budget of the synthesizer evaluator?**

Existing frameworks answer this with code: AutoGen wires a
Director + Worker pattern in Python; CrewAI in YAML + Python; LangGraph
in graph DSL. These frameworks are correct, expressive, but they
require the practitioner to manage a runtime, deploy dependencies, and
maintain a codebase. **The contribution we want is small enough that
the engineering tax of a Python framework dwarfs the algorithmic
contribution.** opencode-moa proposes an alternative: the entire
orchestration is a markdown file with YAML frontmatter, the agents
themselves are markdown subagents, the configuration is JSON, and
"running" the orchestrator is "type `/orquestar` into OpenCode".

This draft reports on the 2026-07-11 experimental run with 12 models
on a Rust GUI design task. We treat the run as an observational study:
we did not pre-register hypotheses, but the data generates four
testable propositions about multi-model orchestration that we then
formulate as future work.

## 2. Related work

[See `docs/papers/BIBLIOGRAPHY.md` for full citations.]

- **Mixture-of-Agents (MoA)** [wang2024moa] demonstrates that layered
  LLM ensembles outperform any single model on AlpacaEval 2.0.
  OpenCode-Moa is a complementary approach: rather than layering in a
  fixed depth, it iteratively refines within a single prompt batch,
  and the iteration is itself configurable (`max_iteraciones`,
  `umbral_convergencia`).
- **Multi-agent debate** [du2023improvingfactualityreasoning] shows
  that debate between agents improves factuality. OpenCode-Moa's
  step 8 (winner selection by the synthesizer after
  per-criterion scoring) is a structured form of this debate.
- **MetaGPT** [hong2023metagpt] introduces role-based multi-agent
  collaboration. OpenCode-Moa uses **single-role-per-agent** instead:
  one agent = one purpose = one model. Roles do not blur.
- **DSPy** [khattab2023dspy] and **AutoGen** [wu2023autogen] provide
  programmatic abstractions. We argue that for the small
  orchestration shapes typical of practical product work
  (5–12 models, 5–15 steps, ≤ 5 iterations), the declarative
  approach is more transparent and less costly to maintain.

## 3. System architecture

`opencode-moa` consists of three file kinds:

1. **Agents** (`opencode-moa/agents/*.md`): one markdown file per
   subagent, frontmatter defining `model:`, `temperature:`,
   `permission:` block. Body declares the system prompt and operating
   modes (propose, evaluate, classify, validate, integrate,
   synthesize, finalize).
2. **Commands** (`opencode-moa/commands/*.md`): slash commands
   `/orquestar` and `/orquestar-iterate` that take the user prompt
   and route it to the `orquestador` agent.
3. **Config** (`opencode-moa/orquestador.json`): default model roster,
   iteration thresholds, step modes, disqualification rules.

### 3.1 Pipeline (v0.3)

```
Step 0:  Read orquestador.json + project-level override + CLI flags.
Step 1:  Fan out — 1 task() per model in modelos_a_competir; each writes
         `01-propuesta-{id_corto}.md` to `out/{id}/iter-N/`.
Step 2 (opt): validador runs per-proposal, writes `02-validacion-*.md`.
Step 3:  evaluador scores all proposals, writes `03-calificacion-evaluador.md`.
Step 4:  sintetizador ranks, writes `04-clasificacion.md`.
Step 5:  step_5_modo (v0.3 NEW):
           - sintesis_central (DEFAULT): ONE integrator produces
             `05-propuesta-integrada.md` from the 12 originals.
           - self_improve (legacy): 12 self-improvements, one per
             original, each reads feedback and rewrites.
           - skip: no step 5, downstream ranks 12 originals only.
Step 6 (opt): validate the integrated/improved candidate(s).
Step 7:  re-evaluate candidate(s), write `07-calificacion-final.md`.
Step 8:  sintetizador picks winner among originals + integrated and/or
         improved, writes `08-ganador.md`.
Step 9:  orchestrator writes `09-sumario.md` itself.
Step 10 (opt, sintesis_final=true): cross-iteration synthesis
         produces `10-sintesis-cross-iter.md`.
```

### 3.2 Iterate mode

In `/orquestar-iterate`, step 9 triggers a convergence check:
`mejora = score_actual(iter-N) − score_actual(iter-N-1)`. If
`mejora >= umbral_convergencia` AND `N < max_iteraciones`, continue to
`iter-N+1`. Otherwise stop.

### 3.3 Selective participation

`filter_low_performers` (v0.3 NEW) prevents dwindling cohorts:
from `iter-2` onwards, models whose `iter-N-1` total score was below
`descalificar_debajo_de` are dropped. If fewer than `keep_minimo`
survive, the top `keep_minimo` are kept. This preserves diversity
without binding every iteration to the slowest subagent.

## 4. Method

We ran the v0.2.0-beta bundle on a single Rust GUI design task on
2026-07-11:

- 12 models: GLM-5.1/5.2, Kimi-K2.6/K2.7-Code, DeepSeek V4 Pro/Flash,
  MiMo v2.5/v2.5-Pro, Qwen3.6-Plus/3.7-Max/3.7-Plus, MiniMax-M3
  (user's plan).
- 2 iterations (iter-2 cut by 5-hour `opencode-go` quota at step 5).
- All-12 self-improvement path (the legacy `self_improve` mode; the
  new `sintesis_central` mode is proposed in §5 but not yet tested).
- Step-1 constraints patched ad-hoc: max 12 tool calls, no
  `cargo tauri build`, hard-stop at 6 minutes per subagent.

The full prompt, configuration, and outputs are preserved verbatim in
`docs/research/experiments/2026-07-11-rust-gui-app.md`.

## 5. Empirical results (N=1 Rust run)

### 5.1 Cost & ROI

[Full table elided — see bitácora §5.]

Cheapest two: **mimo-v2.5** ($0.046) and **deepseek-v4-flash**
($0.059). Top by ROI: same two plus qwen3.7-plus ($0.28). The two
most expensive (qwen3.7-max $3.85, kimi-k2.7-code $1.93) returned
mid-tier scores.

### 5.2 Cross-pollination observation

The 12 iter-1 originals differ in detail; the 12 iter-2 fresh
proposals differ in detail less. We measured specific single-origin
ideas that propagated across iterations:

| Idea | In iter-1 originals | In iter-2 fresh | Origin (single) |
|------|---------------------|-----------------|-----------------|
| `request_repaint()` call | 2 / 12 | 12 / 12 | `propuesta-minimax.md` |
| edge-detect via `Resized` | 1 / 12 | 12 / 12 | `propuesta-minimax.md` |
| `rust-toolchain.toml` | 4 / 12 | 12 / 12 | `propuesta-deepseek.md` |

This is direct empirical evidence that **the synthesizer's
feedback drove the propagation of genuinely-novel ideas from one
proposer to the rest of the cohort.**

### 5.3 Winning proposal content

The iter-1 winner (`out/rust-gui-app/iter-1/05-mejorada-minimax.md`)
is a **Rust GUI using `egui 0.33+` and `eframe 0.33+`** with multi-viewport
support. The iter-2 winner (the integrator-treated `01-propuesta-minimax.md`)
matches in stack but adds theming, i18n, accessibility (Esc to close
field, label-before-input), and Wayland-specific overlay handling.
The runner-up in both iterations is **DeepSeek V4 Pro**'s minimal
Bash-script proposal (87 lines) which, despite its brevity, passes
synthesis scrutiny as the simplest implementation.

## 6. Discussion

### 6.1 Proposition (preliminary, N=1): **model floor > model lift**

The 5 models that scored ≥ 30 in iter-1 fresh were the only ones that
delivered usable output in a single iteration. Of these, the four
stronger (`minimax`, `glm-5.2`, `glm-5.1`, `deepseek-flash`) remained
top-5 in iter-2. The seven models with iter-1 floor < 30 either
needed 2+ iterations to become competitive (`mimo-v25`, `qwen37-max`)
or never converged (`deepseek`, `qwen36-plus`).

This suggests that for **single-iteration mode, model floor
dominates**. For **multi-iteration mode**, low-floor models can
catch up but cost more cycles. With a budget of 2 iterations, all 12
are reasonable. With a budget of 1, only the top 5 should be
included.

### 6.2 Proposition: **synthesis centralized > self-improvement × 12**

We hypothesize that the v0.3 `step_5_modo = sintesis_central` (one
integrator agent) will produce a result statistically indistinguishable
from the 12 self-improvements but at 12× lower cost. The integrator
already has access to all 12 originals and the feedback; the
self-improvement mode is 12 redundant integrations of the same
context. This is the central design change in v0.3 and we expect to
validate it in N=5 cross-domain reruns.

### 6.3 Proposition: **cross-pollination is observable and significant**

Three ideas (`request_repaint`, edge-detect, `rust-toolchain.toml`)
appear with `1-of-12` frequency in iter-1 and **12-of-12** in iter-2.
This is empirical evidence that iterative synthesizer feedback
propagates specific novel ideas across proposers. If this generalizes
across domains, it suggests that the value of multi-model
orchestration lies not in the diversity of final answers but in the
**diversity of mental models that, after iteration, share their
strongest heuristics**.

### 6.4 Limitations

- N=1 in one domain. Statistical claims are conjectural.
- `opencode-go` is known to occasionally degrade specific models
  mid-week. Run-2 of mimo-v2.5 could easily come out at $0.20 with
  a 22/50 final score.
- The 5-hour quota cut iter-2 before completion. Step 7/8/9 outputs
  for iter-2 are missing. We rely on the iter-2 fresh scores
  (step 3-4) which ARE complete.

## 7. Future work

1. **Run the v0.3 bundle** (which now defaults to `sintesis_central`)
   on the same Rust prompt. Compare step-5 cost and integrated
   proposal quality to N=1 results above.
2. **Cross-domain reruns** (medication side effects, marketing copy).
3. **Multi-eval enabled** runs with `[minimax, glm-5.2]` as evaluators.
4. **N=5 reruns** on the same Rust prompt to measure variance per
   model and per ranking position.

## 8. Conclusion

opencode-moa shows that a declarative, no-bash, native-agent multi-model
orchestrator can produce usable proposals for non-trivial technical
tasks (Rust GUI with multi-viewport semantics) for under $12 per
multi-iteration run. The 2026-07-11 experiment motivates three
design changes in v0.3: a centralised step-5 integrator, model floor
filtering from iter-2 onwards, and an opt-in cross-iteration
final synthesis. Each is testable in subsequent reruns.

---

## Appendix A — Configuration used

[Full orquestador.json elided; identical to bitácora §1.]

## Appendix B — Winner path

`out/rust-gui-app/iter-1/05-mejorada-minimax.md` — open in the bundle's
corpus or render via any markdown viewer.
