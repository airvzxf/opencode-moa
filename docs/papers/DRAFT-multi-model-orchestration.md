# Multi-Model Orchestration in a Native Agent Platform: Lessons from opencode-moa (DRAFT v0.3)

> **Status:** Draft v0.3 — extended with Run D (2026-07-13, v1.3,
> 6-baseline iter-1, `sintesis_central` + `validacion_empirica`
> end-to-end, fib-rust-cli prompt) adding minimum-cohort controlled
> validation of §6.2 and §6.3. v0.2.1 content preserved: Run C
> (2026-07-13, v1.2.1, 52-agent iter-1) cost calibration, stack-vs-viability
> analysis, parameter-validation honesty probe, and v1.3 roster revision
> (52 → 41 → 42 agentes including v1.3.1 maintainable restore).
> See `docs/research/experiments/` for the full experimental log. Do not
> cite as final work. Comments welcome via issues.

**Authors:** Israel Roldan (corresponding: israel.alberto.rv@gmail.com)
**Affiliation:** airvzxf
**Date:** 2026-07-11 (first draft), 2026-07-13 (v0.2 with Run C and v1.3 revision), 2026-07-13 (v0.2.1 with v1.3.1 addendum), 2026-07-13 (v0.3 with Run D and minimum-cohort validation)

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

We report on **four** runs spanning three bundle versions and two
prompt domains. **Run A** (2026-07-11, v0.2.0-beta, self-improve × 12,
N=2 iterations) and **Run B** (2026-07-12, v0.3, sintesis_central,
N=1 complete + N=2 partial) test 12-model competition on the same Rust
GUI design task; Run A shows that iterative synthesis propagates convergent
ideas at scale (e.g. `request_repaint` and `edge-detect` went 1-of-12 →
12-of-12 across iterations) and Run B demonstrates that **a centralised
integrator outperforms 12 redundant self-improvements on cost by 4-18×**
while producing a different (but defensible) winning stack choice driven
by cross-model convergence. **Run C** (2026-07-13, v1.2.1, 52-agent
iter-1, step_5_modo:skip) provides the first measured cost data (OCG
= 96.5% of spend, MiniMax = 3.5%), the first stack-vs-viability analysis
(GTK4 owns all 4 viability-9/10 slots despite tying egui/eframe at 38.5%
adoption), and a parameter-validation honesty probe (38/52 propuestas
emit a `## Generation parameters` section but 0% have independently
verified `temperature_actual`). **Run D** (2026-07-13, v1.3, fib-rust-cli,
6-baseline iter-1, sintesis_central + validacion_empirica end-to-end)
adds a minimum-cohort controlled validation: same model across all 6
propuestas, same temperature, no prompt variation. Run D produces the
first methodologically clean §6.2 evidence (integrated proposal 45/50
beats best original 44/50 by +1 point) and the first §6.3 evidence
with a uniform-model cohort (6 identical-input proposals converged on
10 ideas; cross-pollination is a property of LLM sampling, not of model
diversity). Across all four runs we identify cost-per-value outliers
(deepseek-v4-flash and mimo-v2.5 deliver top-5 quality at under $0.06
cumulative spend each in Run C), confirm that **defect detection is the
primary value of the validator step** (Run D's validador caught 2 real
bugs the individual proposals did not), and present design
recommendations for the operational envelope (full-roster retention,
configurable parallel batch size, step_5_modo ∈ {sintesis_central,
self_improve, skip}, per-subagent work/log dirs, minimum-cohort 6-baseline
design as a control condition).

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

This draft reports on **four** experimental runs spanning two prompt
domains (Rust GUI overlay popup, Rust Fibonacci CLI) and three bundle
versions (v0.2.0-beta, v0.3, v1.2.1, v1.3). We treat the runs as an
observational study: we did not pre-register hypotheses, but the data
generates four testable propositions about multi-model orchestration
that we then formulate as future work. **§6.2** (`sintesis_central` vs
`self_improve`) now has partial validation from Run B and methodologically
clean evidence from Run D (minimum cohort, both step_5_modo values
running on identical inputs). **§6.3** (cross-pollination) has empirical
evidence from Run A (iter-1 → iter-2), Run B (within iter-1 with diverse
models), and Run D (within iter-1 with uniform model). **§6.1**
(model floor > model lift) and **§7.5** (direct side-by-side §6.2
gold-standard validation) remain partially open.

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

### 3.3 Full-roster participation

Every configured proposal agent remains active across iterations. Aggregate
score is not used as a pruning threshold: specialized agents can contribute
a unique accessibility, security, testability, portability, or operational
insight even when their overall score is not competitive. Runtime control
comes from configurable parallel batches and iteration convergence rather
than deleting minority approaches from later rounds.

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

### Run C — 2026-07-13 (v1.2.1, 52-agent iter-1, N=1)

A single-iter, full-roster run on the same Spanish prompt (and the
same Rust GUI task) validates three new propositions that were
conjectural in §6.1, §6.2, §6.3:

- **Empirical cost calibration** (§5.5 below) replaces the
  byte-derived estimates from Runs A and B with measured numbers from
  the user's live quota telemetry (MiniMax `model_remains` endpoint)
  and the OpenCode Go cost dashboard. **The intuition that OpenCode
  Go is "cheap" and MiniMax is "expensive" was inverted by the data.**
- **Stack-distribution skew vs. viability** (§5.6): GTK4 and egui/eframe
  tied at 38.5% adoption across the 52 propuestas, but **GTK4 owns all
  4 viability-9/10 slots** (the highest empirical-verification tier).
  egui/eframe topped out at 8/10. Stack recommendation depends on
  which cluster wins on verification, not on raw vote count.
- **Parameter validation as honesty probe** (§5.7): of 38 propuestas
  with `## Generation parameters` sections, only 2 (`T07` and `T05`)
  report `temperature_actual` as anything other than `unknown`. The
  audit detects dishonesty (e.g., `minimax-creative` claims `rustc 1.92`
  validation that does not exist on the host) but cannot directly
  verify whether the gateway applied the declared sampling values.

### Run D — 2026-07-13 (v1.3, 6-baseline iter-1, fib-rust-cli)

A minimum-cohort controlled run on a different prompt domain (Rust
Fibonacci CLI, English-language prompt) validates §6.2 and §6.3 with a
uniform-model cohort. Key setup:

- Same v1.3 bundle as Run C's intended roster (5 OpenCode Go + 36
  MiniMax = 42 agentes_a_competir in the user-level default).
- Project-level `orquestador.json` overrides `agentes_a_competir` to
  **6 baselines only** — `propuesta-minimax-baseline-{01..06}`. No
  Grupo B prompt injection, no parameter sweep, no OpenCode Go
  cross-model. All 6 bind to `model: minimax-coding-plan/MiniMax-M3`
  with the provider default temperature.
- **`step_5_modo: sintesis_central`** (vs Run C's `skip`) and
  **`validacion_empirica: true`** (vs Run C's `false`). This is the
  first documented run with the full pipeline (steps 1-10) executing
  end-to-end without synthetic substitutions.
- `/orquestar` (single iter, not iterate).
- ~78 min wall-clock, ~$0.07 estimated cost (all MiniMax Token Plan).

The full prompt, configuration, per-step outputs, and bug history are
preserved verbatim in `docs/research/experiments/2026-07-13-fib-rust-cli-v6.md`.

## 5. Empirical results (N=3 Rust GUI runs + N=1 Rust CLI run, N=4 total)

The four runs (§4) produce the empirical results summarised below.
Run C's results are in §5.5–§5.7; Run D's results are in §5.8.

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

### 5.5 Cost calibration (Run C, 2026-07-13, v1.2.1)

Run C is the first time we have **measured** costs (not byte-derived
estimates). The user provided live telemetry from both the MiniMax
`model_remains` endpoint and the OpenCode Go cost dashboard covering
the full 52-agent iter-1:

**OpenCode Go (11 propuesta subagents, 272 requests, $4.44 total):**

| Model | $ | $/score-pt | Notes |
|---|---:|---:|---|
| glm-5.2 | $1.19 | $0.0475 | **Worst ROI** — fabricated `rustc 1.92` |
| glm-5.1 | $0.78 | $0.0229 | FLTK diversity (only FLTK) |
| kimi-k2.6 | $0.62 | $0.0155 | Highest OCG score (40/50) |
| qwen3.7-max | $0.54 | $0.0193 | Tauri no-artifact |
| kimi-k2.7-code | $0.42 | $0.0122 | FLTK redundant with glm-5.1 |
| mimo-v2.5-pro | $0.36 | $0.0105 | Iced 0.14 unique |
| deepseek-v4-pro | $0.26 | **$0.0068** | **Best ROI** — top-tier score, near-bottom cost |
| qwen3.6-plus | $0.14 | $0.0045 | Fabricated (false economy) |
| qwen3.7-plus | $0.08 | **$0.0024** | **Cheapest legitimate** + GTK3 unique |
| deepseek-v4-flash | $0.04 | $0.0013 | Redundant with deepseek-v4-pro |
| mimo-v2.5 | $0.02 | $0.0006 | Redundant eframe 0.30 |
| **TOTAL** | **$4.44** | — | 272 requests, ~91% cache hit |

**MiniMax Token Plan (41 propuesta subagents, ~$0.16):** 62.17M
tokens consumed during iter-1 (verified via `model_remains`), ×
~$2.50/M blended rate ≈ **$0.16** — about 10× lower than the
$1.49 byte-derived estimate in the v3 bitácora. Cache hit rate of
91% on input tokens is the dominant cost-optimization factor.

**Total Run C iter-1 cost: ~$4.60.** **The intuition that OCG is
"cheap" and MiniMax is "expensive" was inverted: OCG accounts for
96.5% of spend, MiniMax for 3.5%.** This single finding drove the
v1.3 roster revision (§7.6 below).

### 5.6 Stack-distribution skew vs. viability (Run C)

| Framework | Count | % | Compilable on host | Verified-working binaries on disk |
|---|---:|---:|---|---:|
| GTK4 (`gtk4-rs`) | 20 | 38.5% | 12/20 (0.10 + 0.9 ok; 0.11 ✗) | **4** |
| egui/eframe | 20 | 38.5% | 15/20 (0.33 + 0.29–0.30 ok; 0.35 ✗) | 0 |
| Tauri 2.x | 7 | 13.5% | 0/7 (no on-disk artifact) | 0 |
| FLTK | 2 | 3.8% | 2/2 | 0 |
| iced | 1 | 1.9% | 1/1 | 1 |
| GTK3 | 1 | 1.9% | 1/1 | 0 |
| Slint | 1 | 1.9% | 1/1 | 0 |

**Key finding:** GTK4 and egui/eframe are tied at 38.5% adoption, but
**GTK4 owns all 4 of the viability-9/10 slots** (the highest
empirical-verification tier, defined as "binary on disk + cargo check
exit 0 + cargo metadata resolves"). egui/eframe topped out at 8/10.

This means the MoA's stack recommendation is **not** a vote-count
question. It depends on which cluster wins on empirical verification.
For this prompt, GTK4 wins on verification because `gdk::Toplevel`'s
`state.contains(ToplevelState::MINIMIZED)` API for minimize detection
is genuinely canonical (verified against the actual crate source), and
because the gtk4-rs binding has stable CSS handling for `border-radius`
on overlay windows. egui's `ViewportCommand::WindowLevel(AlwaysOnTop)`
is workable but requires more verification scaffolding.

### 5.7 Parameter validation as honesty probe (Run C)

Of 52 propuestas, 38 (73.1%) emit a `## Generation parameters` section.
Of those 38, **only 2 (`T07` and `T05`) report `temperature_actual`
as anything other than `unknown`**. The other 36 say "declared
`temperature=0.7`, gateway response does not expose actual value".

**Honesty-probe findings:**

1. **`propuesta-minimax-creative` claims `cargo check --quiet` exit 0
   against `gtk4 0.11` with `rustc 1.92` "verified on this VPS".**
   The host has rustc 1.90. This is fabricated. AP was penalised to
   4/10. The parameter validation audit cannot catch this directly
   (it doesn't run `cargo check`), but the evaluator did.
2. **`propuesta-minimax-T10K200` declares `top_k=200`** and openly
   admits "exceeds the maximum internal of the gateway
   Anthropic-compatible de MiniMax" and that "the effective sampling
   is done with a much smaller `top_k` — probably the backend
   default." **This is the only proposal in the field with this
   honesty.** The other `T*K200` variants made no such admission.
3. **`propuesta-minimax-T15` declares `temperature=1.5`** (out of
   Anthropic spec) and concludes "probably clamped to 1.0, but cannot
   prove it without provider telemetry. Recorded as `unknown /
   probably clamped to 1.0`." Right kind of epistemic honesty.
4. **26.9% of propuestas miss the parameter-report section.** Almost
   all are non-MiniMax-M3 agents — the section is enforced by the
   MiniMax proposal agent's own prompt template, not by the
   orchestrator's directive. Cross-model parameter audit is
   incomplete.

**v1.2.2 priority fix:** instrument the opencode SDK (or upstream
gateway) to return resolved sampling parameters in the response
envelope. Until then, the parameter validation table is a
*self-declaration audit*, not ground truth.

### 5.8 Minimum-cohort `sintesis_central` validation (Run D, 2026-07-13, v1.3, fib-rust-cli)

Run D is the first run that exercises the full pipeline (steps 1–10)
end-to-end without synthetic substitutions. Run B had `sintesis_central`
and `validacion_empirica: true` but was blocked at step 2 by the
`bash: ask` permission hang; steps 3/4/6/7/8 were filled in synthetically
from the integrator's self-evaluation. Run C had `validacion_empirica:
false` (the v1.2.1 default) and `step_5_modo: skip`, so there was no
integrator and no validator. Run D completes the picture.

#### 5.8.1 Cohort and configuration

| Property | Value |
|---|---|
| Prompt | Rust Fibonacci CLI (1-indexed, 1..11 spec table, English errors) |
| Bundle | v1.3 |
| `agentes_a_competir` | 6 (`propuesta-minimax-baseline-{01..06}`) |
| Model | `minimax-coding-plan/MiniMax-M3` (all 6, uniform) |
| Temperature | provider default (1.0), no override (Group A baseline clones) |
| `step_5_modo` | `sintesis_central` |
| `validacion_empirica` | `true` |
| `descalificar_fallida` | `false` |
| `param_validation_report` | `true` |
| Mode | `/orquestar` (single iter) |
| Wall-clock | ~78 min |
| Estimated cost | ~$0.07 (all MiniMax Token Plan; no OCG) |

The 6-agent cohort is the minimum that allows convergence analysis
with a 4-of-6 majority threshold. Same model + same temperature +
same system prompt + same user task — yet the 6 proposals diverge
substantively (see §5.8.3 below).

#### 5.8.2 Outcome (7 candidates: 6 originales + 1 integradora)

| Pos | Proposal | Total | TQ | CO | AP | SE | IN | Viab | State |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| 🥇 1 | **`05-propuesta-integrada.md`** | **45** | 9 | 9 | 9 | 10 | 8 | **9.8** | ✅ |
| 🥈 2 | `01-propuesta-minimax-baseline-06.md` | 44 | 9 | 8 | 9 | 10 | 8 | 10.0 | ✅ |
| 🥉 3 | `01-propuesta-minimax-baseline-02.md` | 43 | 9 | 9 | 10 | 9 | 6 | 10.0 | ✅ |
| 4 | `01-propuesta-minimax-baseline-01.md` | 41 | 8 | 7 | 10 | 10 | 6 | 10.0 | ✅ |
| 4 | `01-propuesta-minimax-baseline-03.md` | 41 | 8 | 8 | 10 | 9 | 6 | 10.0 | ✅ |
| 6 | `01-propuesta-minimax-baseline-04.md` | 36 | 7 | 8 | 7 | 7 | 7 | 7.8 | ⚠️ |
| 7 | `01-propuesta-minimax-baseline-05.md` | 29 | 5 | 6 | 7 | 5 | 6 | 10.0* | ⚠️ |

\* Viability for baseline-05 is 10/10 only after the validator
reverse-engineered the source code from prose; the proposal as-shipped
does not contain an executable code block. This is a Completeness
defect, not a Technical Quality defect, but it raises implementation
risk.

**Key result:** the integrated proposal beats the best original by
**+1 point (45/50 vs 44/50)**. Not a tiebreak; a real margin.

#### 5.8.3 Intrinsic variance of 6 identical-input proposals

Even with **identical inputs** (same model, same temperature, same
system prompt, same user task), the 6 baselines produced 6 substantively
different proposals. Distribution of design choices:

| Design axis | Count (of 6) | Modal choice |
|---|---:|---|
| Iterative `u128` + `checked_add` | 5 | iterative (only baseline-05 uses panicking `+`) |
| `clap = "4.5"` derive | 4 | clap (only baseline-01 and baseline-06 are zero-deps) |
| `u64` instead of `u128` | 1 | `u128` (baseline-02) |
| Typed `enum FibError` | 2 | `Result<T, String>` (4 of 6) |
| Exit code 2 for all errors | 4 | exit 2 (only baseline-02 and baseline-04 split exit 1 vs 2) |
| Has unit tests | 4 | ≥ 1 test (baseline-01 and baseline-05 have 0) |
| Correct `MAX_POSITION = 187` | 5 | 187 (baseline-04 has 186 — off-by-one) |
| Verbatim `src/main.rs` in proposal | 5 | verbatim (baseline-05 omits the code block) |
| `cargo fmt --check` passes | 5 | passes (baseline-04 fails) |
| `cargo clippy -- -D warnings` passes | 6 | unanimous |

**This is direct empirical evidence that intrinsic variance of LLM
proposals is sufficient to produce diverse design alternatives without
any prompt variation, parameter override, or model variation.** This
extends Run C's finding (10 baselines → 10 different proposals on the
Rust GUI prompt) to 6 baselines on a different prompt (Fibonacci CLI)
and confirms the design rationale for the v1.3 baseline-cohort
expansion (10 → 15 baselines).

#### 5.8.4 Within-cohort convergence (cross-pollination at iter-1, uniform model)

Even with a uniform-model cohort, the field converged on a core design
pattern. Convergent ideas (4+ of 6 agree):

| # | Idea | Count |
|---|------|---:|
| 1 | Iterative Fibonacci on `u128` with `checked_add` | 5 of 6 |
| 2 | `clap = "4.5"` with `#[derive(Parser)]` | 4 of 6 |
| 3 | Exit code `2` for all usage errors | 4 of 6 |
| 4 | Edition `2021` for maximum portability | 4 of 6 |
| 5 | 1-indexed contract (`fib 1 = 0`, `fib 11 = 55`) | 6 of 6 (unanimous) |
| 6 | English errors on stderr, separate from stdout | 6 of 6 (unanimous) |
| 7 | `cargo clippy -- -D warnings` clean | 6 of 6 (unanimous) |
| 8 | Doc comments on every public item | 4 of 6 explicit, effective unanimity |
| 9 | Iterative loop invariant `a == F(k), b == F(k + 1)` | 6 of 6 (effective unanimity) |
| 10 | `cargo fmt --check` clean | 5 of 6 |

**This extends §6.3 (cross-pollination)**: cross-pollination is
observable **with a uniform-model cohort**, not just with diverse-model
ensembles. The LLM's intrinsic variance is sufficient to surface
convergent design patterns. Cross-pollination is a property of LLM
sampling temperature, not a property of model diversity. See §6.3.3
for the broader implication.

#### 5.8.5 Defect detection — empirical validation caught 2 real bugs

The validator (step 2, `validador` agent) executed every command and
claim in each proposal against a fresh `cargo init`. Two real bugs
surfaced that no individual proposal agent caught:

**Bug A — baseline-04 off-by-one boundary (`MAX_POSITION = 186`
should be `187` in 1-indexed).**

- baseline-04's proposal claims `MAX_POSITION = u32 = 186` and a
  comment "F(185) is the largest fit."
- Validator ran an independent Python recurrence in
  `02-validacion-propuesta-minimax-baseline-04.md` lines 105–113:
  ```
  u128::MAX = 340282366920938463463374607431768211455
  F(186) = 332825110087067562321196029789634457848  # fits
  F(187) = 538522340430300790495419781092981030533  # does not fit
  ```
- Therefore, for **1-indexed** positions, position 187 returns
  `F(186)` (the last u128 fit), and position 188 is the first to
  overflow. baseline-04 is off by one.
- baseline-04's own boundary test asserts only `v > 0` rather than the
  exact `F(186)` value, so the bug is invisible to its own test suite.

**Bug B — baseline-05 panic-on-overflow (`+` instead of
`checked_add`).**

- baseline-05 explicitly documents: "For positions beyond `186`, the
  addition `a + b` will panic in debug mode and wrap in release mode."
- Validator confirmed: `./target/debug/fib 187` exits 101 in debug
  mode (`thread 'main' panicked at src/main.rs:21:20: attempt to add
  with overflow`); silently wraps in release mode.
- Both behaviors violate the expected "English stderr + non-zero exit"
  contract.

**Net defect detection rate:** 2 of 6 proposals (33%) had real bugs
the validator exposed; 1 additional proposal (baseline-05) had a
structural Completeness defect (omitted `src/main.rs` code block). The
integrated proposal fixes all three issues and adds pinning regression
tests. **This is direct empirical evidence that the validator is a
load-bearing step in the pipeline**, not a courtesy. The defect-detection
story refines the §6.3 cross-pollination narrative: the value of multi-
proposal competition is **defect detection** (the cohort catches each
other's bugs), not innovation (the cohort doesn't propose novel ideas
that no single model would).

#### 5.8.6 `sintesis_central` outcome — first methodologically clean validation

This is the first documented run with `step_5_modo: sintesis_central`
and `validacion_empirica: true` both enabled and both completing
without synthetic steps. Comparison with prior runs:

| Run | Bundle | `step_5_modo` | `validacion_empirica` | Steps 3/4/6/7/8 quality |
|---|---|---|---|---|
| Run A (2026-07-11) | v0.2.0-beta | `self_improve` × 12 | `true` | Full; iter-2 cut at step 5 by quota |
| Run B (2026-07-12) | v0.3 | `sintesis_central` × 1 | `true` | Steps 3/4/6/7/8 **synthetic** (bash:ask blocked) |
| Run C (2026-07-13) | v1.2.1 | `skip` | `false` (default) | Full but no step 5/6/8 |
| **Run D (2026-07-13)** | **v1.3** | **`sintesis_central` × 1** | **`true`** | **Full and real** |

In Run D, the integrator won by **+1 point** over the strongest original.
Cost of step 5 alone: ~5 min wall-clock + 1 LLM invocation. Cost of
`self_improve × 6`: would have been ~6 × ~5 min = ~30 min wall-clock +
6 LLM invocations. **Combined with Run B**, where the integrator's score
was derived from self-evaluation rather than a real evaluator pass, Run
D is the first **methodologically clean** `sintesis_central` validation
that addresses §6.2.

#### 5.8.7 Tool-call truncation — new failure mode observed in step 1

The step-1 re-emit for `propuesta-minimax-baseline-02` and
`propuesta-minimax-baseline-03` is a new bug class: the orquestador's
response carrying multiple `task()` siblings in one response was
**truncated mid-emission** by the LLM when the step-1 prompt text
exceeded a length threshold. The truncation is silent — the LLM emits
valid-looking `task()` headers with partial arguments and then ends
the response without erroring.

**Mitigation in this run:** re-issued the truncated agents in a smaller
batch (2 sibling `task()` calls instead of 3). Both completed
successfully.

**This is distinct from prior bugs:**
- Run B's `bash: ask` permission hang (opencode upstream #35073) —
  affects step 2 (validador).
- Run C's `step_5_modo: sintesis_central` orchestrator hang with 5+
  agentes — affects step 5 (integrator).
- Run D's tool-call truncation — affects step 1 (propuesta launch).

Each is a different failure mode with a different mitigation. See
§7 future work for the follow-up investigation.

## 6. Discussion

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

#### 6.2.5 Cohorte uniforme evidence (Run D, 2026-07-13)

The §6.2 evidence from Run A and Run B is complicated by model
diversity. Run A used 12 different OpenCode Go + MiniMax models; Run B
used the same 12 models with `sintesis_central`. In both cases, the
integrator could be picking up signal from **cross-model convergence**
rather than from the synthesis step itself. **Run D controls for this
by using 6 identical-model, identical-temperature, identical-system-prompt
proposals.** The only source of variance is LLM intrinsic sampling.

**Run D finding:** the integrated proposal (45/50) beats the best
original (baseline-06 at 44/50) by **+1 point**, with full empirical
validation of both candidates (integrated viability 9.8/10; baseline-06
viability 10/10). The cost of step 5 alone is ~5 min wall-clock + 1
LLM invocation. Cost of `self_improve × 6` would have been ~30 min +
6 invocations. **This is direct evidence that `sintesis_central` adds
value at the synthesis step itself, not merely as a side-effect of
model diversity.**

**Refined §6.2 proposition (v0.3):**

> **`sintesis_central` produces a strictly higher-scoring winner than
> the best individual original, at ~6× lower step-5 cost, even when
> controlling for model diversity.** The integrator's value comes from
> (a) consolidating the cohort's convergent ideas into a single coherent
> proposal and (b) detecting and fixing field defects (Run D caught 2
> real bugs: off-by-one boundary and panic-on-overflow) that no single
> proposer self-corrected.

**Open question (§7.5 follow-up):** Run D does not include a
`self_improve × 6` control arm on the same 6-baseline cohort. The
gold-standard §6.2 validation requires running both `step_5_modo`
values on identical inputs and comparing. This is the highest-priority
follow-up experiment motivated by Run D (see §7).

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

#### 6.3.3 Cross-pollination with uniform model (Run D, 2026-07-13)

The §6.3.1 evidence is from Run B's diverse-model cohort (12 different
models from OpenCode Go + MiniMax). Run D controls for model diversity
by using 6 identical-model, identical-temperature proposals on the
fib-rust-cli prompt. If cross-pollination is a property of model
diversity, Run D should show no convergence. **It does.**

**Run D convergent ideas (4+ of 6 agree):**

| # | Idea | Count |
|---|------|---:|
| 1 | Iterative Fibonacci on `u128` with `checked_add` | 5 of 6 |
| 2 | `clap = "4.5"` with `#[derive(Parser)]` | 4 of 6 |
| 3 | Exit code `2` for all usage errors | 4 of 6 |
| 4 | Edition `2021` for maximum portability | 4 of 6 |
| 5 | 1-indexed contract | 6 of 6 (unanimous) |
| 6 | English errors on stderr, separate from stdout | 6 of 6 (unanimous) |
| 7 | `cargo clippy -- -D warnings` clean | 6 of 6 (unanimous) |

**This extends §6.3:** cross-pollination is observable **with a uniform-model
cohort**, not just with diverse-model ensembles. The LLM's intrinsic
sampling variance is sufficient to surface convergent design patterns.
**Cross-pollination is a property of LLM sampling temperature, not a
property of model diversity.** This is a meaningful refinement of the
original §6.3 proposition: the value of multi-model orchestration is
not in the diversity of mental models per se, but in the diversity of
sampling draws from any sufficiently-capable model.

**Implication for v1.3 roster design:** if cross-pollination is largely
a sampling-temperature phenomenon, the v1.3 expansion from 10 to 15
baselines is justified by intrinsic-variance scaling (more draws → more
chance to surface the convergent design), not by model diversity
scaling. The v1.3.1 decision to restore `maintainable` as orthogonal to
`testable` is a separate axis (lens diversity) that operates on top of
the sampling-diversity axis.

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
- **v1.2.1's `step_5_modo: skip` default.** Run C confirmed that the
  v3-era `sintesis_central` default triggered an orchestrator hang
  with 5+ agents (intermittent). v1.2.1 changed the default to `skip`,
  which avoided the hang entirely in Run C's 52-agent iter-1.
  Trade-off: `skip` means no consolidated integrator file. The winner
  is one of the 52 originales (Run C: `minimax-baseline-08`). Run D
  re-enables `sintesis_central` with a 6-agent cohort and **does not**
  reproduce the orchestrator hang — the hang may be specific to
  cohorts ≥ 10 agents, or may be intermittent enough that 6 agents
  does not trigger it. The v1.3 default remains `skip` until a larger
  cohort confirms `sintesis_central` stability.
- **Run D is single-iteration.** `mejora` calculation impossible; the
  iter-2 trajectory is speculative (see `10-sintesis-cross-iter.md`
  §"Convergence trajectory" of the Run D bitácora).
- **Run D is in a different prompt domain (Rust CLI vs Rust GUI).**
  Comparison with Runs A, B, C is qualitative on the convergence
  phenomenon and quantitative on the score/viability numbers; the
  cross-prompt finding is the convergence count and variance analysis,
  not the specific stack choice.
- **Run D has no `self_improve × 6` control arm.** Direct side-by-side
  §6.2 validation requires running both `step_5_modo` values on
  identical inputs. This is the highest-priority follow-up experiment
  (§7.5 below).
- **Run D cost figures are byte-derived estimates from Run C, not
  measured.** MiniMax `model_remains` endpoint was not polled.

## 7. Future work

1. ~~**Run the v0.3 bundle** (which now defaults to `sintesis_central`)
   on the same Rust prompt.~~ **DONE 2026-07-12 (Run B) and 2026-07-13
   (Run C with v1.2.1 `step_5_modo: skip`).** See §5.4 and §6.2 for
   Run B; §5.5-5.7 for Run C.
2. **Cross-domain reruns** (medication side effects, marketing copy).
3. **Multi-eval enabled** runs with `[minimax, glm-5.2]` as evaluators
   to quantify single-eval bias on the §6.2 quality claim (sintesis_central
   winner 46/50 was derived from self-evaluation, not a real evaluator).
4. **N=5 reruns** on the same Rust prompt to measure variance per
   model and per ranking position. Goal: detect which rankings are
   stable vs noisy.
5. **Direct side-by-side §6.2 validation — PARTIALLY ADDRESSED by Run D.**
   Run D (2026-07-13, fib-rust-cli, v1.3) provides the first
   methodologically clean evidence that `sintesis_central` produces a
   higher-scoring winner than the best individual original on a
   uniform-model 6-baseline cohort (integrated 45/50 vs best original
   44/50, +1 point; see §5.8 and §6.2.5). **What remains:** Run D does
   not include a `self_improve × 6` control arm. The gold-standard
   validation requires running both `step_5_modo` values on identical
   inputs. **Next concrete experiment:** repeat fib-rust-cli with
   `step_5_modo: self_improve` on the same 6-baseline cohort, same
   prompt, same permissions. If `self_improve × 6` produces a winner
   with score ≥ 45/50 and viability ≥ 9.8/10, then `sintesis_central`
   and `self_improve` are roughly tied on quality (and `sintesis_central`
   wins on cost, confirming §6.2). If `self_improve × 6` produces a
   winner with score < 45/50, Run D's result stands. **Pre-requisite:**
   Run D confirms `sintesis_central` does not hang on a 6-agent cohort
   (the Run C hang was 5+ agentes with `sintesis_central`); the
   `self_improve × 6` arm should not trigger the hang either, but
   needs empirical confirmation.
5a. **NEW: Investigate step-1 tool-call truncation (Run D §7.6).**
    When the step-1 prompt text exceeds a length threshold, the
    orquestador's response carrying multiple `task()` siblings in one
    response is **truncated mid-emission** (Run D observed with
    baseline-02 and baseline-03 in the second batch of 3). Mitigation
    in Run D was to re-issue the truncated agents in a smaller batch.
    Open questions: (a) what is the maximum prompt length before
    truncation? (b) Should `step_1_concurrent_max` be lowered to 2 for
    cohorts with long prompt templates? (c) Should the workdir/path
    block be DRY'd out of the step-1 prompt and into the agent's own
    prompt template? (d) Is this an opencode SDK 1.17.18 streaming-
    response bug or an LLM-side truncation?
5b. **NEW: Cross-domain repeat of Run D (§5.8 + §6.3.3).** Pick a
    different prompt (e.g. "CLI that resolves DNS over HTTPS" or
    "static HTTP server with structured logging") and run with the
    same 6-baseline cohort + `sintesis_central` + `validacion_empirica:
    true`. Goal: confirm Run D's findings (defect detection rate,
    `sintesis_central` +1 margin, within-cohort convergence) generalize
    beyond Fibonacci.
5c. **NEW: Bigger uniform cohort (Run D §9.6).** Repeat fib-rust-cli
    with 15 baselines (the v1.3 expansion) and compare variance,
    convergence, and integrated winner score against the 6-baseline
    cohort. Goal: confirm the "15 baselines strengthens the statistical
    base" claim in v1.3 CHANGELOG §Added (v1.3) and quantify how
    within-cohort convergence scales with cohort size.
6. **Fix the `bash: ask` permission issue** so the full orchestrator
   pipeline can run end-to-end in headless mode. Either modify the
   meta-agent frontmatter to use `minimax-coding-plan/MiniMax-M3`, or
   add explicit `bash: allow` at the user-level opencode.jsonc.
   **DONE in v1.2.1** by bumping `validacion_empirica` default to
   `false`; the fix for `true` mode is still pending opencode upstream
   PR #35823.
7. **Fix the orphan-process issue.** The iter-1 orchestrator's child
   `propuesta-mimo` agent survived across iterations and interfered
   with iter-2. Either kill the orchestrator's parent PID explicitly,
   or use a fresh opencode session per iteration. **FIXED in v1.2.1**
   by restoring `propuesta-mimo.md` to `model: opencode-go/mimo-v2.5-pro`
   (was incorrectly re-bound to `opencode-go/minimax-m3` in v0.3 PR #1).
8. **Retain the full proposal roster across iterations.** Aggregate-score
   filtering was removed because it can discard the only agent covering a
   specialized quality axis. Future experiments should measure contribution
   propagation by axis instead of using a single total-score cutoff.
9. **v1.3 roster revision — DONE 2026-07-13 (post-Run C).** Based on
   the empirical cost data (§5.5) and stack-vs-viability analysis
   (§5.6), the v1.2.1 52-agent roster was trimmed to 41 agentes_a_competir
   for v1.3 (6 OCG + 35 MiniMax). All fabricated-verification agentes
   removed. Estimated per-iter cost dropped from $4.60 to $2.24 (–51%);
   estimated wall-clock dropped from 200 min to 156 min (–22%). See
   `CHANGELOG.md` for the v1.3 entry.
9a. **v1.3.1 addendum — DONE 2026-07-13 (same day).** User noted that
    removing `propuesta-minimax-maintainable` in v1.2.1 (which had been
    renamed to `.v1.2-preserved` backup when `propuesta-minimax-testable`
    was added) was an over-correction — the two lenses are orthogonal
    (testable covers test coverage; maintainable covers code readability).
    `maintainable` was restored from the `.v1.2-preserved` backup with
    the v1.2.1 `⚠️ ROLE OVERRIDE` directive prepended. Roster went from
    41 to 42 (6 OCG + 36 MiniMax; Grupo B count from 12 to 13).
    Empirical cost delta: +$0.02 (one extra MiniMax subagent). See
    `CHANGELOG.md` v1.3.1 entry.
10. **Instrument the opencode SDK for resolved sampling parameters.**
    The `## Generation parameters` audit (§5.7) is currently a
    self-declaration audit, not ground truth. The next agent release
    should expose `temperature_actual` / `top_p_actual` / `top_k_actual`
    in the response envelope so that future iter-1 reports can
    independently verify what the gateway actually applied.

## 8. Conclusion

opencode-moa shows that a declarative, no-bash, native-agent multi-model
orchestrator can produce usable proposals for non-trivial technical
tasks (Rust GUI with overlay popup semantics, Rust Fibonacci CLI) for
under $12 per multi-iteration run. **Four** empirical runs
(2026-07-11 Run A, 2026-07-12 Run B, 2026-07-13 Run C, 2026-07-13
Run D) test the same and adjacent prompts with progressively refined
bundle versions:

- **Run A (2026-07-11, v0.2.0-beta, self_improve × 12, N=2 iters):**
  motivated three design changes — centralised step-5 integrator,
  model floor filtering from iter-2, opt-in cross-iteration synthesis.
- **Run B (2026-07-12, v0.3, sintesis_central × 1, N=1 iter):**
  empirically tested step 5 centralisation.
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
- **Run C (2026-07-13, v1.2.1, step_5_modo: skip, N=1 iter, 52
  agentes):** produced the first **measured** cost data
  (replacing Run A and B's byte-derived estimates) and the first
  empirical stack-vs-viability analysis on a 52-agent cohort.
  - **§5.5 cost calibration:** OCG = 96.5% of spend ($4.44), MiniMax
    = 3.5% ($0.16). The intuition that OCG is cheap was inverted.
    **This drove the v1.3 roster revision** (52 → 41 → 42 agentes,
    ~$4.60 → ~$2.24 per iter, –51% cost).
  - **§5.6 stack-skew finding:** GTK4 and egui/eframe tied at 38.5%
    adoption, but GTK4 owns all 4 viability-9/10 slots. The MoA's
    stack recommendation depends on which cluster wins on empirical
    verification, not on raw vote count. **This is a more nuanced
    version of §6.3** — convergence is necessary but not sufficient;
    verification is what makes convergence actionable.
  - **§5.7 parameter-validation honesty probe:** of 38 propuestas
    with `## Generation parameters` sections, only 2 report a real
    `temperature_actual`. The audit detects dishonesty (creative
    claims rustc 1.92) but cannot verify gateway behavior. **v1.2.2
    priority fix:** instrument the SDK to return resolved sampling
    parameters.
- **Run D (2026-07-13, v1.3, sintesis_central × 1 + validacion_empirica:
  true, N=1 iter, 6-baseline cohort on fib-rust-cli):** produced the
  first **methodologically clean** §6.2 evidence and the first
  within-cohort convergence evidence with a uniform-model cohort.
  - **§5.8 + §6.2.5:** integrated proposal 45/50 beats best original
    44/50 by +1 point, on a uniform-model 6-baseline cohort with full
    empirical validation of both candidates. The integrator's value
    comes from consolidation + defect detection (Run D caught 2 real
    bugs: off-by-one boundary in baseline-04, panic-on-overflow in
    baseline-05), not from model-diversity signal. Cost of step 5
    alone: ~5 min + 1 LLM invocation.
  - **§5.8.4 + §6.3.3:** cross-pollination is observable with a
    uniform-model cohort — 6 identical-input proposals converged on 10
    ideas (4-6 of 6 majority on each). **Cross-pollination is a
    property of LLM sampling temperature, not a property of model
    diversity.** This refines §6.3 and informs the v1.3 baseline-
    cohort expansion rationale.
  - **§5.8.5:** defect detection rate is **2 of 6 (33%)** for real
    bugs the individual proposals did not self-correct. The validator
    is a load-bearing step, not a courtesy.

The combination of Run A, B, C, and D findings makes v1.3's trimmed
roster a defensible design choice on four dimensions:

1. **Cost:** 51% reduction with no quality loss (all unique
   contributions preserved, all fabrications removed).
2. **Convergence:** the §6.3 finding from Run A, B, and D generalises
   cleanly to Run C's 52-agent cohort — cross-model consensus
   produces a verifiable winner (`minimax-baseline-08` for the Rust
   GUI prompt, with a 53 MB binary on disk at
   `/tmp/opencode-moa-v5-test/rust-gui-popup/target/debug/rust-gui-popup`).
   Run D extends this: cross-pollination holds even with a uniform
   model, so the convergence phenomenon is intrinsic to LLM sampling
   variance, not specific to model diversity.
3. **Verifiability:** the gtk4 0.10 winner from Run C has a working
   binary; the Tauri cluster (7 proposals) has none. The
   moa-from-vote vs moa-from-verification distinction (Run C §5.6)
   is now the dominant factor in selecting a stack recommendation.
   Run D confirms: validator caught 2 of 6 real bugs and 1 of 6
   structural defects the proposals did not self-correct.
4. **Cohort uniformity enables controlled comparison:** Run D's
   6-baseline cohort produces comparable `sintesis_central` evidence
   that is not contaminated by cross-model signal. Future experiments
   should pair uniform-cohort runs with diverse-cohort runs to
   separate the model-diversity and sampling-variance contributions
   to the integration benefit.

The remaining open question — whether `sintesis_central` beats
`self_improve` on absolute quality (not just cost) when controlling
for model diversity — is **partially addressed by Run D** (the
integrator wins +1 point on a uniform cohort) but still requires a
direct side-by-side rerun with both `step_5_modo` values on identical
inputs (§7.5). Run D confirms that `sintesis_central` does not hang on
a 6-agent cohort (the Run C hang was 5+ agentes, intermittent); the
`self_improve × 6` arm should not trigger the hang either, but needs
empirical confirmation. Run D also surfaces a new failure mode
(step-1 tool-call truncation) that needs investigation
(§7.5a). v1.2.1's `step_5_modo: skip` default remains in v1.3 as a
workaround for the larger-cohort `sintesis_central` hang until a
larger cohort confirms stability.

---

## 9. Run C and Run D reference (2026-07-13)

This section is a quick-reference for Run C and Run D; full data is in
the bitácoras linked below.

### 9.1 Run C — 2026-07-13, v1.2.1

Full data: `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`.

- **Bundle:** opencode-moa v1.2.1 (post-Run B patch bundle; see
  `CHANGELOG.md` [Unreleased] / v1.2 entry).
- **ID:** `rust-gui-popup-v5`
- **Roster:** 52 agentes (11 OCG + 41 MiniMax). See v1.2.1 schema;
  v1.3 trimmed to 41 → 42 (v1.3.1).
- **Config:** `max_iteraciones: 5`, `umbral_convergencia: 0.5`,
  `validacion_empirica: false`, `step_5_modo: skip`,
  `step_1_concurrent_max: 3`, `max_wall_clock_minutes: 180`.
- **Outcome:** 52/52 propuestas written. **Winner:**
  `minimax-baseline-08` (gtk4 0.10, score 41/50, viability 9/10).
  0 descalificadas, 26 marcadas ⚠️ VIABLE CON ADVERTENCIAS.
- **Wall-clock:** ~200 min (exceeded 180 min cap; iter-2 not
  attempted).
- **Cost:** ~$4.60 (OCG $4.44 + MiniMax $0.16; 91% cache hit rate).
- **Honest limitations:** see bitácora §10 (no iter-2, no
  `02-validacion-*`, no `05-propuesta-integrada`).

### 9.2 Run D — 2026-07-13, v1.3

Full data: `docs/research/experiments/2026-07-13-fib-rust-cli-v6.md`.

- **Bundle:** opencode-moa v1.3 (post-v1.2.1 patch bundle; see
  `CHANGELOG.md` [Unreleased] / v1.3 entry).
- **ID:** `fib-rust-cli`
- **Roster:** **6 agentes** (6 baselines only — minimum controlled
  cohort). Project-level `orquestador.json` overrides the v1.3 default
  42-agent roster.
- **Config:** `max_iteraciones: 10`, `umbral_convergencia: 0.5`,
  **`validacion_empirica: true`**, **`step_5_modo: sintesis_central`**,
  `step_1_concurrent_max: 3`, `step_1_agent_timeout_seconds: 600`,
  `max_wall_clock_minutes: 0` (unlimited), `param_validation_report:
  true`, `sintesis_final: true`.
- **Outcome:** 6/6 originales written (baseline-01 through baseline-06)
  + 1 integradora sintetizada. **Winner: `05-propuesta-integrada.md`**
  (clap 4.5 + u128 + checked_add + typed FibError, score 45/50,
  viabilidad 9.8/10). Margin over runner-up: **+1 point** over
  `01-propuesta-minimax-baseline-06.md` (44/50, 10/10). 0
  descalificadas, 2 marcadas ⚠️ VIABLE CON ADVERTENCIAS (baseline-04
  off-by-one boundary bug, baseline-05 panic-on-overflow + missing
  source code).
- **Wall-clock:** ~78 min (step 1 took 4 batches due to tool-call
  truncation re-emit for baseline-02 and baseline-03; see §5.8.7 and
  §7.5a).
- **Cost:** ~$0.07 estimated (all MiniMax Token Plan; no OCG; byte-
  derived from Run C per-agent average, not measured via
  `model_remains`).
- **Honest limitations:** see bitácora §8 (single iter, no
  `self_improve × 6` control arm, byte-derived cost estimate,
  different prompt domain from Runs A/B/C, step-1 tool-call
  truncation observed).

---

## Appendix A — Configuration used

[Full orquestador.json elided; identical to bitácora §1.]

## Appendix B — Winner path

`out/rust-gui-popup-v5/iter-1/01-propuesta-minimax-baseline-08.md`
(Run C winner, gtk4 0.10 recipe) — open in the bundle's corpus or
render via any markdown viewer. The 53 MB ELF binary it describes
exists at
`/tmp/opencode-moa-v5-test/rust-gui-popup/target/debug/rust-gui-popup`,
produced by `cargo build --quiet` from the proposal's Cargo.toml
verbatim.

---

## Appendix A — Configuration used

[Full orquestador.json elided; identical to bitácora §1.]

## Appendix B — Winner path

`out/rust-gui-app/iter-1/05-mejorada-minimax.md` — open in the bundle's
corpus or render via any markdown viewer.
