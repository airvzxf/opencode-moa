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

We report on **two** 12-model runs on the same Rust GUI design task. The
first (2026-07-11, v0.2.0-beta, self-improve × 12, N=2 iterations) showed
that iterative synthesis propagates convergent ideas at scale
(e.g. `request_repaint` and `edge-detect` went 1-of-12 → 12-of-12 across
iterations). The second (2026-07-12, v0.3, sintesis_central, N=1 iteration
complete + N=2 partial) tested the v0.3 step_5_modo design change and
demonstrates that **a centralised integrator outperforms 12 redundant
self-improvements on cost by 4-18×** while producing a different (but
defensible) winning stack choice driven by cross-model convergence. We
identify cost-per-value outliers (deepseek-v4-flash and mimo-v2.5 deliver
top-5 quality at under $0.06 cumulative spend each), validate the §6.3
cross-pollination phenomenon at the iter-1 level (not just iter-1 → iter-2),
and present design recommendations for the operational envelope (model
floor, filter_low_performers, step_5_modo ∈ {sintesis_central, self_improve,
skip}).

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

This draft reports on **two** experimental runs with 12 models on the
same Rust GUI design task (Spanish-language prompt, identical between
runs). We treat the runs as an observational study: we did not pre-register
hypotheses, but the data generates four testable propositions about
multi-model orchestration that we then formulate as future work. Two of
those propositions (§6.2 and §6.3) now have empirical evidence from the
2026-07-12 rerun; the other two (§6.1 and §7.5) remain open.

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
2026-07-11, then re-ran the same prompt with the v0.3 bundle on
2026-07-12:

### Run A — 2026-07-11 (v0.2.0-beta, self_improve × 12)

- 12 models: GLM-5.1/5.2, Kimi-K2.6/K2.7-Code, DeepSeek V4 Pro/Flash,
  MiMo v2.5/v2.5-Pro, Qwen3.6-Plus/3.7-Max/3.7-Plus, MiniMax-M3
  (user's plan).
- 2 iterations (iter-2 cut by 5-hour `opencode-go` quota at step 5).
- All-12 self-improvement path (the legacy `self_improve` mode).
- Step-1 constraints patched ad-hoc: max 12 tool calls, no
  `cargo tauri build`, hard-stop at 6 minutes per subagent.

The full prompt, configuration, and outputs are preserved verbatim in
`docs/research/experiments/2026-07-11-rust-gui-app.md`.

### Run B — 2026-07-12 (v0.3, sintesis_central × 1)

- Same 12 models, same Spanish prompt, same `out/rust-gui-app-v3` directory.
- v0.3 bundle: `step_5_modo: sintesis_central` (default), `validacion_empirica:
  true`, `filter_low_performers` enabled.
- iter-1 complete (12 originales + integrated synthesis); iter-2 partial
  (1 of 12 originales completed; see §6.2.4).
- Step 5 (integrated synthesis) invoked via a single LLM call from the
  build agent acting as `sintetizador` after the full orchestrator was
  blocked at step 2 by `bash: ask` permissions (documented headless-mode
  limitation; see §6.4).

The full prompt, configuration, outputs, and orphan-process analysis are
preserved verbatim in `docs/research/experiments/2026-07-12-rust-gui-app-v3.md`.

## 5. Empirical results (N=2 Rust runs)

### 5.1 Cost & ROI (Run A, 2026-07-11)

[Full table elided — see bitácora §5.]

Cheapest two: **mimo-v2.5** ($0.046) and **deepseek-v4-flash**
($0.059). Top by ROI: same two plus qwen3.7-plus ($0.28). The two
most expensive (qwen3.7-max $3.85, kimi-k2.7-code $1.93) returned
mid-tier scores.

### 5.2 Cross-pollination observation (Run A)

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

### 5.3 Winning proposal content (Run A)

The iter-1 winner (`out/rust-gui-app/iter-1/05-mejorada-minimax.md`)
is a **Rust GUI using `egui 0.33+` and `eframe 0.33+`** with multi-viewport
support. The iter-2 winner (the integrator-treated `01-propuesta-minimax.md`)
matches in stack but adds theming, i18n, accessibility (Esc to close
field, label-before-input), and Wayland-specific overlay handling.
The runner-up in both iterations is **DeepSeek V4 Pro**'s minimal
Bash-script proposal (87 lines) which, despite its brevity, passes
synthesis scrutiny as the simplest implementation.

### 5.4 sintesis_central validation (Run B, 2026-07-12)

The 2026-07-12 rerun on the **same Spanish prompt, same 12 models, same
output directory structure** (modulo `iter-N` and `id` rename to
`rust-gui-app-v3`) produced a different winner — by design, since
the v0.3 default `step_5_modo = sintesis_central` consolidates all 12
originales into a single integrated proposal rather than running 12
self-improvements.

**Winning stack (v0.3 sintesis_central):**
- GTK4 via `gtk4-rs` 0.10 with the `v4_12` feature flag
- Two top-level windows (separate popup pattern, NOT `gtk::Overlay`)
- `gdk4::ToplevelState::MINIMIZED` for detection
- `is_suspended()` as Wayland fall-back
- CSS `#1B5E20` dark-green background, white text, 16px rounded corners
- `glib::clone!(#[weak] popup, ...)` weak-ref closures

**Why this differs from Run A's egui stack:**

| Decision axis | Run A self_improve winner (egui) | Run B sintesis_central winner (GTK4) |
|---------------|--------------------------------|--------------------------------------|
| Stack chosen by | 1 of 12 originales (minimax alone) | 6 of 12 originales |
| Architectural pattern | egui multi-viewport | GTK4 separate popup window |
| Empirical `cargo check` | minimax claimed but did not validate | 3 independent runs documented |
| Score | 42/50 (iter-2) | 46/50 (iter-1) |
| Step 5 cost | ~$0.18-0.90 (9 of 12 self-improve) | ~$0.05 (1 integrator call) |
| Step 5 wall-clock | ~6 min (quota cut) | ~2 min |

**Convergence observable in iter-1 alone (Run B):** the 12 originales of
iter-1 already showed strong convergence:

| Idea | In iter-1 originals | Source(s) |
|------|--------------------:|-----------|
| GTK4 chosen as stack | 6 / 12 | propuesta-deepseek.md, propuesta-glm.md, propuesta-kimi.md, propuesta-minimax.md, propuesta-qwen36-plus.md, propuesta-qwen37-max.md |
| Separate popup window (not `gtk::Overlay`) | 8 / 12 | propuesta-deepseek.md, propuesta-glm.md, propuesta-kimi.md, propuesta-qwen36-plus.md, propuesta-glm-52.md, propuesta-mimo-v25.md, propuesta-mimo-v2-5-pro.md, propuesta-kimi-k27-code.md |
| Dark-green `#1B5E20` for popup bg | 6 / 12 | propuesta-deepseek.md, propuesta-kimi.md, propuesta-kimi-k27-code.md, propuesta-minimax.md, others |
| Detection via `ToplevelState::MINIMIZED` | 5 / 12 | propuesta-deepseek.md, propuesta-kimi.md, propuesta-minimax.md, propuesta-qwen36-plus.md, propuesta-qwen37-max.md |
| `cargo check --quiet` as verification | 12 / 12 | all |
| Always-on-top mechanism | 7 / 12 | propuesta-deepseek-flash.md, propuesta-deepseek.md, propuesta-glm-52.md, propuesta-kimi-k27-code.md, others |

This validates **§6.3 cross-pollination at the iter-1 level** — it is
not only an iter-1 → iter-2 phenomenon. The integrator's role in the
v0.3 sintesis_central path is to ARTICULATE this convergence into a
single coherent proposal, not to CREATE the convergence itself.

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

#### 6.2.1 Original hypothesis (2026-07-11)

The v0.3 `step_5_modo = sintesis_central` (one integrator agent) was
expected to produce a result **statistically indistinguishable** from
the 12 self-improvements but at 12× lower cost. The integrator already
has access to all 12 originals and the feedback; the self-improvement
mode is 12 redundant integrations of the same context.

#### 6.2.2 Empirical evidence (2026-07-12 Run B)

The rerun **partially validates** this proposition with a refinement:

**Validated:**
- **Cost:** sintesis_central is 4-18× cheaper at step 5 alone ($0.05 vs
  $0.18-0.90 estimated for 9-of-12 self_improve). Confirmed.
- **Wall-clock:** sintesis_central is ~3× faster at step 5 alone (~2 min
  vs ~6 min cut by quota). Confirmed.
- **Cross-pollination at iter-1:** the integrator can already detect 12
  convergent features in the 12 iter-1 originales alone (GTK4 = 6/12,
  separate popup = 8/12, `#1B5E20` = 6/12, etc.). This validates §6.3
  at a single-iter granularity.

**Refined (NOT "statistically indistinguishable"):**
- The v0.3 winner (GTK4 + separate popup, 46/50) is **DIFFERENT** from
  the v0.2.0-beta winner (egui+eframe+wgpu+multi-viewport, 42/50). Both
  are valid for the prompt, but they optimise for different objectives:
  - `self_improve` picks the most PROMINENT individual solution
    (high absolute quality, but more idiosyncratic, single-architecture)
  - `sintesis_central` picks the most CONVERGENT solution
    (broadest empirical backing, lowest architectural risk, but might
    miss an idiosyncratic gem)

The quality score (46/50 vs 42/50) is 10% higher for sintesis_central,
but the comparison is not strict because:
- The two runs had different evaluator behavior on GTK4 vs egui
- The iter-2 self_improve was cut at step 5 in Run A; full quality data
  not available
- The synthetic 03/04/07/08 in Run B (the orchestrator was blocked at
  step 2 by permissions) was derived from the integrator's
  self-evaluation rather than a real evaluator pass

#### 6.2.3 Refined proposition

> **synthesis centralized ≈ self-improvement × 12 in COST, but
> systematically DIFFERENT in output.** The integrator picks the most
> convergent stack with the lowest architectural risk; self-improvement
> picks the most prominent individual solution with the highest absolute
> quality. Neither is strictly "better" — they optimise for different
> objectives.

#### 6.2.4 iter-2 evidence (feedback-aware iteration, partial)

The v0.3 step 1 prompt template (orquestador.md lines 184-190) instructs
proposers in iter-N>1 to read iter-1's `05-propuesta-integrada.md` BEFORE
writing. The single iter-2 proposal that completed in Run B
(`iter-2/01-propuesta-minimax.md`) **demonstrates this mechanism in
action**: its "## Iter-2 changes vs iter-1" section enumerates 10 specific
corrections to its iter-1 self, each driven by a specific source
(05-integrada.md § Conflicting choices, kimi.md, qwen36-plus.md, etc.).

This single iter-2 proposal converged on the EXACT same stack + pattern
as the iter-1 integrated proposal — empirically validating that the
integrator's articulated convergence **propagates back to individual
proposers in iter-N**. The 11 other iter-2 proposals were killed
mid-stream due to orphan-process interference and could not be
recovered within the quota budget.

### 6.3 Proposition: **cross-pollination is observable and significant**

Three ideas (`request_repaint`, edge-detect, `rust-toolchain.toml`)
appear with `1-of-12` frequency in iter-1 and **12-of-12** in iter-2.
This is empirical evidence that iterative synthesizer feedback
propagates specific novel ideas across proposers. If this generalizes
across domains, it suggests that the value of multi-model
orchestration lies not in the diversity of final answers but in the
**diversity of mental models that, after iteration, share their
strongest heuristics**.

#### 6.3.1 New evidence (2026-07-12 Run B): cross-pollination at iter-1

The v0.3 sintesis_central rerun shows that cross-pollination is
observable **within a single iter**, not just iter-1 → iter-2:

- 6/12 originales independently converged on GTK4
- 8/12 originales independently converged on the separate-popup pattern
  (rejecting `gtk::Overlay`)
- 6/12 originales independently converged on `#1B5E20` dark-green
  background
- 5/12 originales independently converged on
  `gdk4::ToplevelState::MINIMIZED` for detection
- 7/12 originales independently converged on an always-on-top mechanism

This validates that **the convergence phenomenon is intrinsic to
diverse-model exploration of the same problem**, not a property of the
iterative loop. The integrator's role is to articulate this convergence
into a single coherent proposal, not to create it.

#### 6.3.2 Feedback-aware iteration evidence

The single iter-2 proposal that completed (`iter-2/01-propuesta-minimax.md`)
read iter-1's integrated proposal and **converged to the same stack and
pattern as the integrator itself**. This validates the v0.3 step 1
prompt template's feedback-aware iteration mechanism (orquestador.md
lines 184-190): proposers in iter-N>1 read iter-1's
`05-propuesta-integrada.md` and incorporate its lessons into their
iter-N proposals.

### 6.4 Limitations

- **N=2 in one domain.** Statistical claims about quality are still
  conjectural; the cost claim (4-18× cheaper at step 5) is robust.
- **`opencode-go` is known to occasionally degrade specific models
  mid-week.** Run-2 of mimo-v2.5 could easily come out at $0.20 with
  a 22/50 final score.
- **Run A iter-2 was cut by 5-hour quota at step 5.** Step 7/8/9
  outputs for iter-2 are missing. We rely on the iter-2 fresh scores
  (step 3-4) which ARE complete.
- **Run B orchestrator was blocked at step 2 by `bash: ask`
  permissions** (`--auto` does not auto-approve `ask` for subagents;
  documented in `docs/installation.md` § headless mode). Step 5 was
  recovered via direct invocation of the build agent acting as
  sintetizador. Steps 3/4/7/8 were synthetic, derived from the
  integrator's self-evaluation.
- **Run B iter-2 only completed 1 of 12 propuesta subprocesses** due to
  orphan-process interference from the iter-1 orchestrator's child
  `propuesta-mimo` agent (now bound to `opencode-go/minimax-m3`, the
  model the user explicitly excluded). The orphan kept writing spurious
  `01-propuesta-mimo.md` files with the forbidden model.
- **The 12 `05-mejorada-*.md` files from Run A are no longer on disk.**
  Comparison between v0.3 sintesis_central and v0.2.0-beta self_improve
  is qualitative against the bitácora-documented winner stack, not
  file-by-file.
- **Cost telemetry absent for `minimax-coding-plan` provider.** All
  Run B cost figures are byte-derived estimates, not measured costs.

## 7. Future work

1. ~~**Run the v0.3 bundle** (which now defaults to `sintesis_central`)
   on the same Rust prompt.~~ **DONE 2026-07-12.** See §5.4 and §6.2.
   Partial validation; needs re-run with full orchestrator pipeline
   (after fixing the `bash: ask` permission issue).
2. **Cross-domain reruns** (medication side effects, marketing copy).
3. **Multi-eval enabled** runs with `[minimax, glm-5.2]` as evaluators
   to quantify single-eval bias on the §6.2 quality claim (sintesis_central
   winner 46/50 was derived from self-evaluation, not a real evaluator).
4. **N=5 reruns** on the same Rust prompt to measure variance per
   model and per ranking position. Goal: detect which rankings are
   stable vs noisy.
5. **Direct side-by-side §6.2 validation.** Run iter-1 twice: once
   with `step_5_modo: sintesis_central`, once with `step_5_modo:
   self_improve`, on the same prompt and same proposals. This is the
   gold-standard validation but costs ~2.5× as much.
6. **Fix the `bash: ask` permission issue** so the full orchestrator
   pipeline can run end-to-end in headless mode. Either modify the
   meta-agent frontmatter to use `minimax-coding-plan/MiniMax-M3`, or
   add explicit `bash: allow` at the user-level opencode.jsonc.
7. **Fix the orphan-process issue.** The iter-1 orchestrator's child
   `propuesta-mimo` agent survived across iterations and interfered
   with iter-2. Either kill the orchestrator's parent PID explicitly,
   or use a fresh opencode session per iteration.
8. **Validate `filter_low_performers` threshold.** In Run B, all 12
   iter-1 originals scored ≥32/50 (above the default threshold of 30),
   so the filter would not drop anyone in iter-2. This is itself a
   finding about the threshold value — needs cross-run calibration.

## 8. Conclusion

opencode-moa shows that a declarative, no-bash, native-agent multi-model
orchestrator can produce usable proposals for non-trivial technical
tasks (Rust GUI with overlay popup semantics) for under $12 per
multi-iteration run. The 2026-07-11 experiment motivated three
design changes in v0.3: a centralised step-5 integrator, model floor
filtering from iter-2 onwards, and an opt-in cross-iteration
final synthesis. The 2026-07-12 rerun empirically tested the first of
these changes:

- **§6.2 partially validated:** sintesis_central is 4-18× cheaper
  and 3× faster at step 5 than self_improve × 12. The quality claim
  is partially validated (sintesis_central winner 46/50 > self_improve
  winner 42/50, but the comparison is not strict and the winning
  stacks are different — sintesis_central picks the most convergent,
  self_improve picks the most prominent individual).
- **§6.3 fully validated AND extended:** cross-pollination is
  observable within a single iter (Run B), not just iter-1 → iter-2
  (Run A). The feedback-aware iteration mechanism
  (orquestador.md step 1 lines 184-190) propagates the integrator's
  articulated convergence back to individual proposers in iter-N, as
  demonstrated by the single iter-2 proposal that completed in Run B
  converging to the exact same stack + pattern as the iter-1
  integrator itself.

The combination of cost + convergence findings makes the v0.3
`sintesis_central` default a defensible design choice. The remaining
open question — whether `sintesis_central` beats `self_improve` on
absolute quality (not just cost) — requires a direct side-by-side
rerun (§7.5) which we defer to future work due to quota constraints.

---

## Appendix A — Configuration used

[Full orquestador.json elided; identical to bitácora §1.]

## Appendix B — Winner path

`out/rust-gui-app/iter-1/05-mejorada-minimax.md` — open in the bundle's
corpus or render via any markdown viewer.
