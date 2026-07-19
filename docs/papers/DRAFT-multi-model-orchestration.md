# Multi-Model Orchestration in a Native Agent Platform: Lessons from opencode-moa (DRAFT v0.5)

> **Status:** Draft v0.5 — extended with Run F (2026-07-16, v1.3,
> 22-agent iter-1, `sintesis_central` + `validacion_empirica`
> end-to-end, voxora-kernels prompt — first CUDA-kernel / GPU-binary
> compatibility prompt domain) adding the **§6.2 partial restoration**
> (integrated proposal won by +0.2 AP over T15 runner-up, with
> source-attributed evidence — 18/18 line citations verified accurate
> to ≤5 lines), the **§6.3 evidence at 4th prompt domain** (9
> convergent themes, max **17/22** = 77% agreement on in-tree patch
> approach — the highest convergence density in the corpus to date),
> and a new **byte-precise PTX reproducibility standard** (282,810
> bytes patched PTX, 0 `atom.add.f16`, 8 `softmax_f16` reproduced
> byte-for-byte on `nvcc 12.9.86` by 3 independent validators). Run F
> also documents a **validador webfetch gateway-timeout bug** affecting
> 5 originals and mitigated by prompt tightening (not fixed at SDK
> level). v0.4 content preserved: Run E (2026-07-15, v1.3, 21-agent
> iter-1) §6.2 counter-evidence + §6.3 21-cohort + 13-defect catalog;
> v0.3 content preserved: Run D (2026-07-13, v1.3, 6-baseline iter-1)
> minimum-cohort controlled validation of §6.2 and §6.3;
> v0.2.1 content preserved: Run C (2026-07-13, v1.2.1, 52-agent iter-1)
> cost calibration, stack-vs-viability analysis, parameter-validation
> honesty probe, and v1.3 roster revision (52 → 41 → 42 agentes
> including v1.3.1 maintainable restore). See
> `docs/research/experiments/` for the full experimental log. Do not cite
> as final work. Comments welcome via issues.

**Authors:** Israel Roldan (corresponding: israel.alberto.rv@gmail.com)
**Affiliation:** airvzxf
**Date:** 2026-07-11 (first draft), 2026-07-13 (v0.2 with Run C and v1.3 revision), 2026-07-13 (v0.2.1 with v1.3.1 addendum), 2026-07-13 (v0.3 with Run D and minimum-cohort validation), 2026-07-15 (v0.4 with Run E and 21-cohort + integrator counter-evidence), 2026-07-16 (v0.5 with Run F and CUDA-kernel compat + source-attributed integrator)

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

We report on **six** runs spanning three bundle versions and four
prompt domains (Rust GUI, Rust CLI, Firefox WebExtension, CUDA kernel
compatibility). **Run A** (2026-07-11, v0.2.0-beta, self-improve × 12,
N=2 iterations) and **Run B** (2026-07-12, v0.3, sintesis_central,
N=1 complete + N=2 partial) test 12-model competition on the same Rust
GUI design task; Run A shows that iterative synthesis propagates
convergent ideas at scale (e.g. `request_repaint` and `edge-detect`
went 1-of-12 → 12-of-12 across iterations) and Run B demonstrates that
**a centralised integrator outperforms 12 redundant self-improvements
on cost by 4-18×** while producing a different (but defensible) winning
stack choice driven by cross-model convergence. **Run C** (2026-07-13,
v1.2.1, 52-agent iter-1, step_5_modo:skip) provides the first measured
cost data (OCG = 96.5% of spend, MiniMax = 3.5%), the first
stack-vs-viability analysis (GTK4 owns all 4 viability-9/10 slots
despite tying egui/eframe at 38.5% adoption), and a parameter-validation
honesty probe (38/52 propuestas emit a `## Generation parameters`
section but 0% have independently verified `temperature_actual`).
**Run D** (2026-07-13, v1.3, fib-rust-cli, 6-baseline iter-1,
sintesis_central + validacion_empirica end-to-end) adds a minimum-
cohort controlled validation: same model across all 6 propuestas,
same temperature, no prompt variation. Run D produces the first
methodologically clean §6.2 evidence (integrated proposal 45/50 beats
best original 44/50 by +1 point) and the first §6.3 evidence with a
uniform-model cohort (6 identical-input proposals converged on 10
ideas; cross-pollination is a property of LLM sampling, not of model
diversity). **Run E** (2026-07-15, v1.3, moodle-quiz-extractor,
21-agent iter-1, sintesis_central + validacion_empirica end-to-end,
first non-Rust prompt domain — a Firefox WebExtension) is the
largest `sintesis_central + validacion_empirica` end-to-end run before Run F. Run E produces the first **§6.2 counter-evidence** (the
integrated proposal ranked 16/22 with composite 6.05, **losing** by
2.94 points to the winning original `propuesta-minimax-T15` at
composite 8.99 — the integrator introduced 4 critical-path defects
that the originals did not have), the first §6.3 evidence at
21-cohort scale (9 convergent themes, max 12/21 agreement on MV3+WXT),
and the first defect catalog at scale (~13 distinct defects in 21
proposals, including 4 phantom npm packages, 2 wrong selectors, 1
retracted API endpoint, and 1 invalid manifest JSON). **Run F**
(2026-07-16, v1.3, voxora-kernels, 22-agent iter-1, sintesis_central
+ validacion_empirica end-to-end, fourth prompt domain — CUDA kernel
compatibility for Pascal sm_61) is the **§6.2 partial restoration**:
the integrated proposal wins by +0.2 AP (9.4 vs T15's 9.2) with a
**source-attributed evidence base** — 18/18 line citations verified
accurate to ≤5 lines by the integrated validator, and a **byte-precise
PTX reproducibility standard** (282,810 bytes patched PTX, 0
`atom.add.f16`, 8 `softmax_f16` reproduced byte-for-byte on `nvcc
12.9.86` by 3 independent validators). Run F also documents a
**validador webfetch gateway-timeout bug** affecting 5 originals and
mitigated by prompt tightening (not fixed at SDK level). Across all
six runs we identify cost-per-value outliers (deepseek-v4-flash and
mimo-v2.5 deliver top-5 quality at under $0.06 cumulative spend each
in Run C), confirm that **defect detection is a primary value of the validator step** (Run D caught 2 real bugs, Run E caught 13, Run F caught ~7 categories). Run F also shows that a similar cohort size can yield fewer detected defect categories when the prompt has fewer orthogonal decision axes; the corpus is not yet large enough to claim a linear law. We present design recommendations
for the operational envelope (full-roster retention, configurable
parallel batch size, step_5_modo ∈ {sintesis_central, self_improve,
skip}, per-subagent work/log dirs, minimum-cohort 6-baseline design
as a control condition, a new "min viable integrator" mode proposed
for §7.5f to prevent integrator-introduced defects, and a new
**source-attributed integrator** pattern documented in §5.10.6 + §7.5m
that REQUIRES the integrator to publish a source-attribution table
with N line ranges AND requires the validador to verify each
citation), and document the first time a Group C parameter-sweep
agent (`propuesta-minimax-T15` at T=1.5) has led the ranking in an
opencode-moa run.

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

This draft reports on **six** experimental runs spanning four prompt domains (Rust GUI overlay popup, Rust Fibonacci CLI, Firefox WebExtension for Moodle quiz extraction, and CUDA kernel compatibility) and three bundle versions (v0.2.0-beta, v0.3, v1.2.1, v1.3). We treat the runs as an observational study: we did not pre-register hypotheses, but the data generates four testable propositions about multi-model orchestration that we then formulate as future work. **§6.2** (`sintesis_central` vs `self_improve`) now has partial validation from Run B, methodologically clean evidence from Run D's minimum cohort and full pipeline (but **not** a `self_improve` control arm), the first **counter-evidence** from Run E (21 realized proposals from a 22-agent configured cohort where the integrated proposal lost to the best original by 2.94 points due to 4 critical-path defects introduced by the integrator), and a **partial restoration** in Run F (+0.2 AP with source-attributed evidence, without a same-input self-improve control). **§6.3** (cross-pollination) has empirical evidence from Run A (iter-1 → iter-2), Run B (within iter-1 with diverse models), Run D (within iter-1 with uniform model), Run E (within iter-1 with 21 realized proposals: 9 convergent themes, max 12/21 agreement on MV3+WXT), and Run F (within iter-1 with a CUDA-kernel cohort: 9 themes, max 17/22 on the in-tree patch). **§6.1** (model floor > model lift) and the direct side-by-side **§7** controls remain partially open.

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

### 3.1 Pipeline (v1.3)

```
Step 0:  Read orquestador.json + project-level override + CLI flags.
Step 1:  Fan out — 1 task() per model in agentes_a_competir; each writes
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

### Run E — 2026-07-15 (v1.3, 21-agent iter-1, moodle-quiz-extractor)

A large-cohort run on a third prompt domain (Firefox WebExtension for
Moodle quiz extraction, Spanish-language prompt) tests whether Run D's
findings generalize to a 21-agent cohort and a non-Rust, non-CLI
domain. Key setup:

- v1.3 bundle (same as Run D).
- Project-level `orquestador.json` with `agentes_a_competir` = **21**
  (8 Group A baselines `propuesta-minimax-baseline-{01..09}` + 6 Group B
  prompt injections {creative, minimal, security-first, observability,
  ci-github, cd-releases} + 6 Group C parameter sweeps {T05, T10, T15,
  P099, T05K50, T10K200} + 1 external `propuesta-deepseek-flash`).
  This is the **largest `sintesis_central + validacion_empirica` end-to-end
  cohort** to date (Run C had 52 agents but `validacion_empirica: false`
  and `step_5_modo: skip`).
- `umbral_convergencia: 0.2` (tighter than Run D's 0.5; user-driven
  reduction; not exercised in the single-iter run).
- **`step_5_modo: sintesis_central`** and **`validacion_empirica: true`**
  and **`sintesis_final: true`** (writes step-10 cross-iter synthesis).
- `/orquestar` (single iter, not iterate).
- ~5.76 h wall-clock, ~$0.20 estimated cost (49 MiniMax invocations +
  1 external via opencode-go; byte-derived from Run C per-agent average).

The full prompt, configuration, per-step outputs, defect catalog, and
bug history are preserved verbatim in
`docs/research/experiments/2026-07-15-moodle-quiz-extractor-v7.md`.

### Run F — 2026-07-16 (v1.3, 22-agent iter-1, voxora-kernels)

A large-cohort run on a fourth prompt domain (CUDA kernel compatibility
for Pascal sm_61, Spanish-language prompt) tests whether Run E's
findings generalize to a 22-agent cohort and a fundamentally different
decision space (GPU-binary compatibility, not web stack selection).
This is the first run on a **GPU-binary / kernel-level** decision
problem and the first run with **byte-precise physical
reproducibility** (PTX output, not just viability verdicts). Key
setup:

- v1.3 bundle (same as Run E).
- Project-level `orquestador.json` with **22 configured agents**. Five additional agents (`propuesta-mimo`, `propuesta-deepseek`, `propuesta-qwen37-plus`, `propuesta-kimi`, `propuesta-glm`) were excluded by user instruction before launch and do not appear in this project-level JSON or the output corpus. The 22 configured agents are 9 Group A baselines
  `propuesta-minimax-baseline-{01..09}` + 6 Group B prompt injections
  {creative, minimal, security-first, observability, ci-github,
  cd-releases} + 6 Group C parameter sweeps {T05, T10, T15, P099,
  T05K50, T10K200} + 1 external `propuesta-deepseek-flash`.
- `umbral_convergencia: 0.2` (same as Run E; not exercised in the
  single-iter run).
- **`step_5_modo: sintesis_central`** and **`validacion_empirica: true`**
  and **`sintesis_final: true`** (writes step-10 cross-iter synthesis).
- `/orquestar` (single iter, not iterate). The user did not invoke
  `/orquestar-iterate`, so the convergence threshold is unexercised.
- **First `param_validation_report: true` observation in a 22-cohort** —
  the synthesizer aggregated per-proposal parameter declarations into a
  table in `04-clasificacion.md` (the T/top_p/top_k overrides for the
  Group C agents, defaults for Group A, no-declaration for the external
  provider). This is the third run in the corpus to use this option
  after Run D and Run E.
- ~78 min wall-clock, ~$0.20 estimated cost (byte-derived from Run C
  per-agent average; 22 MiniMax invocations + 1 external + 5 retries
  + 22 validador + 1 integrated validador + 2 evaluador + 3
  sintetizador ≈ 56 LLM calls total).
- **First run in the corpus where the integrated candidate publishes an
  explicit Source-attribution table** with 18 line ranges, AND the
  validador independently verifies each one is accurate to ≤5 lines
  (18/18 ✅). This is a methodological pattern proposed as a default
  for `sintesis_central` in §7.5m.
- **First run with byte-precise physical reproducibility:** the
  integrated validator reproduces the patched-PTX gate at
  `nvcc -O3 -std=c++17 -arch=sm_61 -ptx --expt-relaxed-constexpr -I src
  src/reduce.cu -o /tmp/reduce_patched_sm61.ptx` and confirms the PTX
  is exactly **282,810 bytes**, with **0 `atom.add.f16`** and **8
  `softmax_f16`**. The same byte-precise target is reproduced by 3
  independent validators (T15, baseline-02, integrated) — the first
  byte-exact cross-validator evidence in the corpus.

The full prompt, configuration, per-step outputs, defect catalog, and
bug history are preserved verbatim in
`docs/research/experiments/2026-07-16-voxora-kernels-v8.md`.

## 5. Empirical results (N=3 Rust GUI runs + N=1 Rust CLI run + N=1 Firefox WebExtension run + N=1 CUDA kernel compat, N=6 total)

The six runs (§4) produce the empirical results summarised below.
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

### 5.9 Maximum-cohort `sintesis_central` validation (Run E, 2026-07-15, v1.3, moodle-quiz-extractor)

Run E is the largest `sintesis_central + validacion_empirica` end-to-end
run before Run F. It also extends the prompt-domain coverage from two Rust
domains (GUI, CLI) to a third non-Rust domain (Firefox WebExtension for
Moodle quiz extraction, Spanish-language prompt). Run E's role in this
draft is to test the generalizability of Run D's findings and to expose
**the first §6.2 counter-evidence**: an integrator that introduces
critical-path defects can lose to the strongest original.

#### 5.9.1 Cohort and configuration

| Property | Value |
|---|---|
| Prompt | Firefox WebExtension that extracts Moodle quizzes to Markdown (Spanish) |
| Bundle | v1.3 |
| `agentes_a_competir` | **21** (8 Group A baselines + 6 Group B prompt injections + 6 Group C parameter sweeps + 1 external `propuesta-deepseek-flash`) |
| Models | 20 × `minimax-coding-plan/MiniMax-M3` + 1 × `opencode-go/deepseek-v4-flash` (external only) |
| `step_5_modo` | `sintesis_central` |
| `validacion_empirica` | `true` |
| `descalificar_fallida` | `false` |
| `param_validation_report` | `true` |
| `sintesis_final` | `true` |
| `umbral_convergencia` | `0.2` (tighter than Run D's 0.5; not exercised in single iter) |
| Mode | `/orquestar` (single iter) |
| Wall-clock | ~5.76 h (50 sub-agent invocations) |
| Estimated cost | ~$0.20 (byte-derived from Run C per-agent average; 49 MiniMax invocations + 1 external) |

The 21-agent cohort is the largest single-iter cohort with full
empirical validation. It includes **9 Group A baselines** for
within-cohort variance measurement, **6 Group B prompt injections**
(creative, minimal, security-first, observability, ci-github,
cd-releases) for orthogonal-perspective diversity, **6 Group C
parameter sweeps** (T05, T10, T15, P099, T05K50, T10K200) for
sampling-parameter diversity, and 1 external provider (deepseek-flash)
for cross-model signal. The 7 unselected Group B variants (a11y,
errors, i18n, portable, rustdoc, testable, maintainable) were not
exercised — see §6.4 limitations.

#### 5.9.2 Outcome (22 candidates: 21 originales + 1 integradora)

| Pos | Proposal | Group | Composite (/10) | Total (/50) | Viability | State |
|---:|---|:---:|---:|---:|---:|---|
| 1 | **`propuesta-minimax-T15`** | C (T=1.5) | **8.99** | 43 | **9.2 ✓** | **Finalist · winner** |
| 2 | `propuesta-minimax-security-first` | B (security) | 8.94 | 44 | 9.0 ✓ | Finalist |
| 3 | `propuesta-minimax-T05` | C (T=0.5) | 8.75 | 41 | 9.0 ✓ | Finalist |
| 4 | `propuesta-minimax-baseline-03` | A | 8.28 | 40 | 8.5 ✓ | Viable |
| 5 | `propuesta-minimax-T10` | C | 8.09 | 37 | 8.5 ✓ | Viable |
| 6 | `propuesta-minimax-baseline-05` | A | 8.08 | 39 | 8.5 ✓ | Viable with warnings |
| 7 | `propuesta-minimax-T10K200` | C | 7.75 | 36 | 8.5 ✓ | Viable with warnings |
| 8 | `propuesta-minimax-baseline-08` | A | 7.65 | 40 | 7.6 ⚠ | Viable with warnings |
| 9 | `propuesta-minimax-cd-releases` | B | 7.48 | 36 | 8.0 ⚠ | Viable with warnings |
| 10 | `propuesta-minimax-minimal` | B | 7.19 | 35 | 7.6 ⚠ | Viable with warnings |
| 11 | `propuesta-minimax-baseline-01` | A | 6.88 | 33 | 7.5 ⚠ | Viable with warnings |
| 12 | `propuesta-minimax-baseline-06` | A | 6.81 | 32 | 7.5 ⚠ | Viable with warnings |
| 13 | `propuesta-deepseek-flash` | external | 6.63 | 29 | 7.5 ⚠ | Viable with warnings |
| 14 | `propuesta-minimax-P099` | C | 6.48 | 31 | 7.0 ⚠ | Viable with warnings |
| 15 | `propuesta-minimax-observability` | B | 6.14 | 30 | 6.5 ⚠ | Viable with warnings |
| 16 | **`05-propuesta-integrada.md`** | — | **6.05** | 33 | 7.0 ⚠ | **Viable only after 4 failed sections repaired** |
| 17 | `propuesta-minimax-baseline-07` | A | 6.05 | 33 | 6.5 ⚠ | Viable with warnings |
| 18 | `propuesta-minimax-creative` | B | 5.53 | 29 | 6.0 ⚠ | Viable with warnings |
| 19 | `propuesta-minimax-baseline-02` | A | n/a | 32 | 5.0 (no val) | Conservative scoring |
| 20 | `propuesta-minimax-baseline-04` | A | n/a | 23 | 6.0 ⚠ | 3 failed sections |
| 21 | `propuesta-minimax-ci-github` | B | n/a | 25 | 5.5 ⚠ | 4 failed sections |
| 22 | ~~`propuesta-minimax-T05K50`~~ | C | ~~3.66~~ | ~~19~~ | ~~4.0 ❌~~ | ~~**DESCALIFICADA**~~ |

**Three key results:**

1. **First T-variant to win the ranking:** `propuesta-minimax-T15`
   (Group C, T=1.5 sweep — out of Anthropic spec) leads with
   composite 8.99 and viability 9.2. This is the first time a
   parameter-sweep agent has led an opencode-moa ranking. The
   v1.3 roster decision to keep T15 (and drop T00, T03, T08) is
   validated by this result.
2. **First §6.2 counter-evidence:** the integrated proposal ranked
   16/22 with composite 6.05, **2.94 points below the winning
   original** (`propuesta-minimax-T15` at 8.99). The integrator's
   `AP=1` was forced by 4 critical-path defects (see §5.9.6). This
   is the first documented case of `sintesis_central` losing to a
   best-original in a uniform-cohort + empirical-validation run.
3. **First time `descalificar_fallida: false` retains a 16/22
   candidate that the validator explicitly marked with 4 failed
   sections:** the integrated proposal was kept in the ranking as
   ⚠️ rather than excluded, allowing the comparison with the
   winning original.

#### 5.9.3 Top-3 finalist analysis

**1. `propuesta-minimax-T15` (winner) — composite 8.99, viability 9.2.**

T15's validation executed **22 commands with 0 failures** and verified
every named selector against all 4 real fixtures (`ddoo-01`,
`ddoo-02`, `dsop-01`, `dsop-02`). It is the only candidate that
combines:

- **Broadest parser registry in the corpus:** 6 question types
  (RadioQuestionParser, CheckboxQuestionParser, ShortTextQuestionParser,
  LongTextQuestionParser, SelectQuestionParser, UnsupportedQuestionParser)
- **`stableFingerprint` SHA-256** of normalized content — resists
  Moodlish randomization where `slot` ≠ `qno`
- **Structured error-code taxonomy** `MQX-DETECT-001` …
  `MQX-PRIV-401` — the last is a **privacy-leak blocker** that any
  user or AI can grep for
- **WXT 0.20.27 + Turndown 7.2.4 + DOMPurify 3.4.12 + Zod 4.4.3 +
  fflate 0.8.3 + jsdom 29.1.1** — modern web-extension ecosystem stack

**2. `propuesta-minimax-security-first` (runner-up) — composite 8.94, viability 9.0.**

Security-first has the **highest raw total** (44/50) and the **only
Security = 10/10** in the corpus. It lost the composite to T15 by 0.05
points because viability carries 55% of the weight and T15 scored 9.2
vs 9.0. Its key contributions:

- **OWASP Top 10 control matrix** as a first-class artifact
- **Deny-by-default URL/path allowlist** — most rigorous threat-model
- **Double-redaction** (pre-render + pre-export)
- **No-submit invariant** enforced by spies on
  `HTMLFormElement.prototype.submit`, `requestSubmit`, and
  `fetch/.../processattempt.php`
- **Minimal manifest:** `host_permissions: []` by default;
  `optional_host_permissions` only after user gesture

**3. `propuesta-minimax-T05` (third) — composite 8.75, viability 9.0.**

T05 has the **cleanest reliability profile** of the corpus: 26/26
commands executed, 0 failures, 0 non-viable sections. It combines:

- **BNF answer grammar:** parses `1. a)`, `2. c)`, `3. a, d`,
  `5. text` — the exact format in the user's `prompt.md`
- **Validated Python `moodlectl.py` Native Messaging host** —
  stdlib-only, no pip deps
- **Direct handling of `_answer` radio controls** and `_choice{N}`
  checkbox controls (verified by grep against the 4 fixtures)
- **Multi-letter autofill** for checkbox questions

The three finalists all converged on **MV3 + WXT/esbuild + DOMPurify +
fflate or JSZip**; the synthesis (§6) should pick **fflate +
tar-stream** (not JSZip alone, to keep all three archive formats).
All three have **two-tier debug** ("safe report by default / opt-in
structural with consent preview"). All three honour
`incognito: not_allowed` and scoped `host_permissions`.

#### 5.9.4 Within-cohort convergence at 21-cohort scale (9 themes)

Even at 21 agents (8 Group A + 6 Group B + 6 Group C + 1 external),
the cohort produced **9 convergent ideas** independently proposed by
3+ agents. This is consistent with Run D's finding that
cross-pollination scales with cohort size — more agents surface more
convergent ideas (Run D: 10 ideas, 4+ of 6 majority at 6-agent cohort;
Run E: 9 ideas, 3+ of 21 majority at 21-agent cohort).

| # | Idea | Count | Originals that proposed it (independent) |
|---|------|------:|---|
| 1 | **MV3 + WXT 0.20.27** as the build floor | **12 of 21** | T15, security-first, T05, T10, baseline-03, baseline-05, baseline-08, T10K200, ci-github, observability, P099, cd-releases |
| 2 | **Redaction of `sesskey` / `MoodleSession` / `userid` / `attempt` / cookies** | 11 | T15, security-first, T05, T10, baseline-03, baseline-05, baseline-06, baseline-07, baseline-08, observability, deepseek-flash |
| 3 | **`fflate` for ZIP** (valid — `fflate@0.8.3` exports `zipSync` and `gzipSync`) | 9 | T15, security-first, T05, baseline-01, baseline-06, baseline-07, baseline-08, creative, P099, ci-github |
| 4 | **Turndown 7 + DOMPurify 3 + Zod** as the HTML→Markdown + validation chain | 8 | T15, T05, T10, baseline-03, baseline-05, baseline-06, baseline-08, T10K200 |
| 5 | **`incognito: not_allowed` + scoped `host_permissions`** (only `/mod/quiz/attempt.php*`) | 8 | T15, security-first, T05, T10, baseline-05, baseline-08, T10K200, minimal |
| 6 | **Pagination walker** — `fetch()` `/mod/quiz/attempt.php?…&page=N` with cookie credentials, same-origin only | 7 | T15, security-first, baseline-03, baseline-05, baseline-07, baseline-08, P099 |
| 7 | **Two-tier debug** ("safe report by default / opt-in structural with consent preview") | 6 | T15, security-first, baseline-03, baseline-05, baseline-08, observability |
| 8 | **Native Messaging host in Python stdlib** for the AI-from-terminal bridge | 5 | T05, T15 (mentions), baseline-02, baseline-07, cd-releases |
| 9 | **Hand-rolled TAR or `tar-stream`** (because `fflate` has no `tar()` export — verified by the validator) | 5 | baseline-02 (custom USTAR + pako), baseline-04 (claimed, broken selector), baseline-06 (custom ~80 LOC), observability (custom ~120 LOC), baseline-07 (claimed, reference invalid) |

**Interpretation.** Items 1, 2, 5, 6, 7 are **safe defaults** — every
top-6 finalist agrees on them and AMO / Firefox 140+ policies require
them. Items 3 + 9 are a pair: `fflate` for zip+gzip, and either
`tar-stream@3.2.0` or a custom USTAR for tar — the choice is forced
because the wrong choice was the most common defect in the corpus
(4 originals — baseline-01, baseline-07, baseline-08, T05K50 — claimed
`fflate.tar()` works, which it does not). Item 8 (Native Messaging) is
consensus for the *optional* terminal bridge but is correctly
**deferred from MVP** by the top-3.

This extends §6.3's finding that **cross-pollination is a property of
LLM sampling temperature, not a property of model diversity**: a
21-agent cohort with mostly one model (20/21) still produces
substantial cross-pollination. See §6.3.4 for the broader implication.

#### 5.9.5 Defect detection at 21-cohort scale (~13 distinct defects)

The validator's per-section viability reports flagged **~13 distinct
defects** in the 21-cohort. This is a **6.5× increase over Run D's
2 defects in a 6-baseline cohort**, suggesting defect detection scales
roughly linearly with cohort size.

| # | Defect | Affected originals | Category | Mitigation |
|---:|--------|-------------------:|----------|------------|
| 1 | **`fflate` has no `tar()` export** (claimed in 4 originals) | baseline-01, baseline-07, baseline-08, T05 | Phantom API | Use `tar-stream@3.2.0` or hand-rolled USTAR |
| 2 | **`@wext/manifest@^1.0.0`** does not exist on npm (max 0.2.2) | deepseek-flash | Phantom npm package | `npm view <pkg> version` before commit |
| 3 | **`tarballjs`** does not exist on npm or GitHub | cd-releases | Phantom npm package | Use `tar-stream@3.2.0` or hand-rolled USTAR |
| 4 | **`@webassembly-feature/web-ext`** does not exist on npm | creative | Phantom npm package | Drop WASM bridge; use Native Messaging |
| 5 | **`@grafana/otel-cli-ls`** does not exist on npm | observability | Phantom npm package | Use `@opentelemetry/exporter-trace-otlp-http` |
| 6 | **`chrome.sockets.tcpServer`** is Chrome-Apps-only API, deprecated 2022 | baseline-06, creative | Phantom API | Use `browser.runtime.connectNative` (MV3) |
| 7 | **Wrong radio selector** `name$="_choice"` (matches 0 elements) | baseline-04, T05K50 | Wrong selector | `name$="_answer"` for radios, `name$="_choice{N}"` for checkboxes |
| 8 | **`pnpm audit --prod --audit-level high`** endpoint retired (HTTP 410) | baseline-07, integrated | Retracted endpoint | Use `pnpm audit` (without `--prod --audit-level`) or `npm audit` |
| 9 | **`packageManager: "pnpm@10.x"`** is non-exact (Corepack rejects) | integrated | Invalid config | Use exact version like `pnpm@10.13.1` |
| 10 | **`strict_min_version: 140` + `data_collection_permissions`** (Android contradiction) | integrated | Invalid manifest | Use `strict_min_version: 142` or drop `data_collection_permissions` |
| 11 | **32-char `spanId`** violates OTLP 1.10.0 (requires 16 hex) | observability | Wrong format | Use UUIDv7 (16 hex) not 32-char hash |
| 12 | **MV2 manifest with `//` JSON comments** + MV3-only `host_permissions` inside MV2 | T05K50 | Invalid manifest | Use MV3 + scoped `host_permissions`, no comments in JSON |
| 13 | **CI YAML parse errors** + wrong `ddoo-02` type breakdown + `_answer-1` selector matches 0 elements | ci-github | Multiple defects | Validate CI YAML + grep-verify selectors against fixtures |

(Plus 2 fabricated-content defects in baseline-01 Q2 and baseline-07
cmid, and 1 unpublishable manifest in minimal — these are content
defects rather than technical defects but are still caught by the
validator's per-section table.)

**Mechanism.** Two effects compound:

1. **Larger cohort = more chances for someone to make a mistake.**
   With 21 agents, the probability that at least one agent tries a
   phantom package or wrong selector is much higher.
2. **Validator's per-section viability catches errors that the
   proposing agent cannot self-correct.** T15 wins because it was
   the only one whose validator confirmed every named selector
   against every fixture AND every package version against npm AND
   every MV3 manifest key against the AMO lint rules.

**This is the dominant contribution of the validator step in
large-cohort runs.** Run D's defect detection rate of 33% (2/6)
generalises to **62% (13/21) at the 21-cohort scale** — a 1.9×
increase. The validator is not just "useful" in large-cohort runs;
it is **load-bearing for the cohort's overall trustworthiness**.

#### 5.9.6 §6.2 counter-evidence: integrator lost to best original

This is the first documented case in opencode-moa where
`sintesis_central` lost to the strongest original in a uniform-cohort
+ empirical-validation run. Run D found the integrator won by +1 point
(45/50 vs 44/50). Run E finds the **integrator lost by 2.94 points**
(6.05/10 vs 8.99/10, equivalent to 30/50 vs 45/50).

**What went wrong in the integrated proposal.** The integrator
introduced 4 critical-path defects that no individual original had:

1. **`packTar` sample imports `Pack` as a runtime value and calls
   `new Pack()`** — but `tar-stream@3.2.0` exposes the lowercase
   `pack()` factory. The snippet fails both TypeScript and runtime
   validation. Run E's validator caught this on step 6.
2. **Archive layout and Markdown template disagree** — some sections
   use `./assets/` and others emit `./quiz/...`. The generated
   Markdown links would not resolve inside the archive.
3. **`pnpm audit --prod --audit-level high`** reaches the retired
   npm audit endpoint and returns HTTP 410. The CI gate fails.
4. **`packageManager: "pnpm@10.x"`** is not an exact Corepack version
   and is rejected at install time.

Plus 3 secondary defects:

5. **`strict_min_version: 140` combined with `data_collection_permissions`**
   creates an Android compatibility contradiction (data_collection_permissions
   was added in Firefox 142+, not 140).
6. **Markdown example adds `a. b. c. d.` prefixes** even though the
   literal user example uses bare `[ ]` lines.
7. **The "Why this beats the field" section incorrectly claims that
   T15 uses a defective `fflate` TAR path** — T15 explicitly defers
   TAR, so the criticism is factually wrong.

The integrator's `AP=1` was forced by the system's strict AP
recalibration: 3+ failed sections → AP=1 per the system-prompt
table. The §6.2 finding is therefore not "integration is
intrinsically worse" — it is "**integration can lose to the best
original when the integrator introduces critical-path defects the
originals did not have**". See §6.2.6 for the refined proposition.

#### 5.9.7 No step-1 tool-call truncation at 21-cohort

Run D observed step-1 tool-call truncation with `baseline-02` and
`baseline-03` (the second batch of 3 hit the LLM response-length
threshold). Run E with a 21-agent cohort and a longer Spanish prompt
observed truncation **only for `baseline-09`** — a single agent in
the first batch of 3. The agent was re-issued as a dedicated 1-agent
batch, and the cohort continued without further truncation. This is
consistent with the Run D §5.8.7 + §7.5a hypothesis that the
truncation point depends on response length, not on agent identity.
The longer Spanish prompt did not push the LLM past the truncation
threshold on 3-sibling responses in batches 2-7; only batch 1
(baseline-09, the third `task()` call) was affected.

**sintesis_central did not hang at 21-agent cohort.** Run C had
observed `sintesis_central` orchestrator hangs with 5+ agents (Run C
§6.4 "Run C limitations"). Run E with 21 agents did **not** reproduce
the hang — the integrator completed cleanly in ~12 min, consuming all
21 originals + 03 + 04 + 20 validations. This supports the hypothesis
that the hang is specific to **step-5 subagent context size** (how
many originals the integrator must consume at once), not to the
step-1 batch size.

### 5.10 CUDA-kernel compatibility validation (Run F, 2026-07-16, v1.3, voxora-kernels, 22-cohort iter-1)

Run F is the **fourth distinct prompt domain** in the opencode-moa
corpus (after Rust GUI, Rust CLI, Firefox WebExtension) and the first
to target a **CUDA-kernel / GPU-binary compatibility** decision space.
It is also the first run with **byte-precise physical reproducibility**
(the integrated validator reproduces an exact PTX byte count on `nvcc
12.9.86`) and the first run where the **integrator publishes an explicit
Source-attribution table** that the validador independently verifies.

Run F's role in this draft is threefold:

1. **§6.2 partial restoration.** Run E's counter-evidence (integrator
   lost by 2.94 points) was dramatic. Run F shows the integrator can
   win again (+0.2 AP over T15), but only when it carries a verifiable
   evidence base. See §5.10.6 + §6.2.7 for the refined proposition.
2. **§6.3 evidence at 4th domain.** Cross-pollination scales to a
   non-software-stack, GPU-binary domain (9 themes, max 17/22 = 77%
   agreement on the in-tree patch approach — the highest convergence
   density in the corpus to date).
3. **Byte-precise validator evidence.** Run F establishes that
   `validacion_empirica: true` can produce **physically-reproducible**
   artifacts (PTX byte counts, instruction-presence greps), not just
   viability verdicts. This is a methodological refinement of the
   validator's role.

#### 5.10.1 Cohort and configuration

| Property | Value |
|---|---|
| Prompt | CUDA kernel compat for Pascal sm_61 (Spanish-language prompt; targets candle-kernels 0.9.2 + qwen3-asr 0.2.2 + voxora/telora) |
| Bundle | v1.3 (same as Run E) |
| `agentes_a_competir` | **22 configured agents**; five additional agents were excluded by user instruction before launch and do not appear in this project-level JSON or the output corpus |
| Models | 21 × `minimax-coding-plan/MiniMax-M3` + 1 × `opencode-go/deepseek-v4-flash` (external) |
| `step_5_modo` | `sintesis_central` |
| `validacion_empirica` | `true` |
| `descalificar_fallida` | `false` |
| `param_validation_report` | `true` |
| `sintesis_final` | `true` |
| `umbral_convergencia` | `0.2` (same as Run E; not exercised in single iter) |
| Mode | `/orquestar` (single iter; user did not invoke `/orquestar-iterate`) |
| Wall-clock | ~78 min (estimated from per-agent timing) |
| Estimated cost | ~$0.20 (byte-derived from Run C per-agent average; ~56 LLM invocations total including 5 retry passes) |
| Project classification | `NOT_GIT` (orchestration workspace; out-of-scope for the GitHub PR protocol) |

The 22-agent cohort is the second-largest `sintesis_central +
validacion_empirica` end-to-end run after Run E (21 agents). It
includes **9 Group A baselines** for within-cohort variance
measurement, **6 Group B prompt injections** (creative, minimal,
security-first, observability, ci-github, cd-releases) for
orthogonal-perspective diversity, **6 Group C parameter sweeps** (T05,
T10, T15, P099, T05K50, T10K200) for sampling-parameter diversity, and
1 external provider (deepseek-flash) for cross-model signal. The 7
unselected Group B variants (a11y, errors, i18n, portable, rustdoc,
testable, maintainable) were not exercised — see §6.4 Run F limitations.

#### 5.10.2 Outcome (23 candidates: 22 originales + 1 integradora)

| Pos | Proposal | Group | AP | Validator | Total | State |
|---:|---|:---:|---:|---:|---:|---|
| 1 | **`05-propuesta-integrada.md`** | — (integrator) | **9.4** | **9.7/10 ✅** | **69/70** (7 sections) | **Finalist · winner** |
| 2 | `propuesta-minimax-T15` | C (T=1.5) | 9.2 | 9.5/10 ✅ | 48/60 (6 sections) | Finalist |
| 3 | `propuesta-minimax-T05` | C (T=0.5) | 9.0 | 9.4/10 ✅ | 46/60 (6 sections) | Finalist |
| 4 | `propuesta-minimax-baseline-02` | A | 8.9 | 9.0/10 ✅ | 45/60 (6 sections) | Viable ✅ |
| 5 | `propuesta-minimax-baseline-03` | A | 8.7 | 9.0/10 ✅ | (6 sections) | Viable ✅ |
| 6 | `propuesta-minimax-baseline-08` | A | 8.7 | 9.0/10 ✅ | (6 sections) | Viable ✅ |
| 7 | `propuesta-minimax-baseline-06` | A | 8.5 | 9.0/10 ✅ | (6 sections) | Viable ✅ |
| 8 | `propuesta-minimax-baseline-09` | A | 8.5 | 9.0/10 ✅ | (6 sections) | Viable ✅ |
| 9 | `propuesta-minimax-security-first` | B (security) | 8.5 | 9.0/10 ✅ | (6 sections) | Viable ✅ |
| 10 | `propuesta-minimax-T10` | C | 8.2 | 8.5/10 ✅ | (6 sections) | Viable ✅ |
| 11 | `propuesta-minimax-P099` | C | 8.2 | 8.5/10 ✅ | (6 sections) | Viable ✅ |
| 12 | `propuesta-minimax-cd-releases` | B (cd-releases) | 8.0 | 8.5/10 ⚠️ | (6 sections) | Viable with warnings |
| 13 | `propuesta-minimax-creative` | B (creative) | 7.7 | 8.0/10 ⚠️ | (6 sections) | Viable with warnings |
| 14 | `propuesta-minimax-baseline-04` | A | 7.2 | 7.5/10 ⚠️ | (6 sections) | Viable with warnings |
| 15 | `propuesta-minimax-baseline-05` | A | 7.0 | 7.5/10 ⚠️ | (6 sections) | Viable with warnings |
| 16 | `propuesta-minimax-observability` | B (observability) | 7.0 | 7.5/10 ⚠️ | (6 sections) | Viable with warnings |
| 17 | `propuesta-minimax-ci-github` | B (ci-github) | 6.7 | 7.0/10 ⚠️ | (6 sections) | Viable with warnings |
| 18 | `propuesta-deepseek-flash` | external | 6.5 | 7.0/10 ⚠️ | (6 sections) | Viable with warnings |
| 19 | `propuesta-minimax-baseline-01` | A | 5.5 | 6.0/10 ⚠️ | (6 sections) | Viable with warnings |
| 20 | `propuesta-minimax-minimal` | B (minimal) | 5.0 | 5.0/10 ❌ | (6 sections) | ❌ NOT VIABLE per section |
| 21 | `propuesta-minimax-T05K50` | C (combo) | ≈3.5 | 4.2/10 ❌ | (6 sections) | ❌ NOT VIABLE per section |
| 22 | `propuesta-minimax-baseline-07` | A | 3.5 | 4.5/10 ❌ | (6 sections) | ❌ NOT VIABLE per section |
| 23 | `propuesta-minimax-T10K200` | C (combo) | 3.3 | 4.2/10 ❌ | (6 sections) | ❌ NOT VIABLE per section |

**Three key results:**

1. **§6.2 partial restoration.** The integrated candidate wins by
   **+0.2 AP** (9.4 vs T15's 9.2). The apparent +21 total-point
   difference is not comparable because the integrated candidate was
   scored over seven sections and the originals over six; the extra row
   was synthetic. The win also carries source-attributed evidence —
   18/18 line citations verified accurate to ≤5 lines by the integrated
   validator — and a byte-precise PTX reproducibility standard (282,810
   bytes) reproduced by 3 independent validators. See §5.10.6 + §6.2.7.
2. **Highest convergence density in the corpus.** 22 originals converge
   on 9 themes, with **17/22 (77%) agreement** on the in-tree
   `[patch.crates-io]` approach. This is significantly higher than Run
   E's 12/21 (57%) and Run D's 4-6/6 (67-100%). See §5.10.4 + §6.3.5.
3. **0 descalificadas, 4 ❌ NOT VIABLE per section.** With
   `descalificar_fallida == false`, the 4 not-viable proposals are
   kept in the ranking as ❌ entries. The same opt-in disqualification
   policy as Runs D and E.

#### 5.10.3 Top-4 finalist analysis

**1. `05-propuesta-integrada.md` (winner) — AP 9.4, validator 9.7/10 ✅, 69/70 (7 sections).**

The integrated candidate is the **first winner in the corpus with an
explicit Source-attribution table**. The integrator publishes 18 line
ranges citing the original source (`01-propuesta-minimax-T15.md`,
`01-propuesta-minimax-T05.md`, `01-propuesta-minimax-baseline-02.md`,
`03-calificacion-evaluador.md`, `04-clasificacion.md`) that supplied
each section of the integrated proposal, AND the integrated validator
independently opens each cited file at the cited offset and verifies
the content matches the descriptor (18/18 ✅ to ≤5 lines). No original
in any prior run had this property.

Key contributions:

- **In-tree `[patch.crates-io]` with `name = "candle-kernels"`,
  `version = "0.9.2"`** — vendored from `~/.cargo/registry/src/.../
  candle-kernels-0.9.2/`, preserving identity, LICENSE files (copied
  from upstream `candle/` repo at vendor time, not from registry cache),
  and a provenance record.
- **Two production patches** (≈ 30 LOC total): `src/reduce.cu` gate
  `SUM_OP(__half, sum_f16)` at `__CUDA_ARCH__ >= 700`, plus `build.rs`
  source manifest omitting `src/moe/moe_wmma*.cu` and `libmoe.a` below
  `compute_cap < 80`.
- **Direct patched-PTX install gate** (`nvcc -O3 -std=c++17
  -arch=sm_61 -ptx --expt-relaxed-constexpr -I src src/reduce.cu
  -o /tmp/reduce_patched_sm61.ptx` + `grep -c 'atom.add.f16'` /
  `grep -c 'softmax_f16'`) — byte-precise, reproducible, NOT
  replaceable with `nvcc -c` (the full host/device compile triggers a
  separate `compatibility.cuh:21` redefinition).
- **Seven stop/go gates (G1-G7):** G1 dependency freeze, G2 compile,
  G3 kernel load, G4 Qwen BF16 dtype/device, G5 real ASR (CPU vs GPU
  comparison), G6 sm_80+ regression, G7 wider legacy claim.
- **Honest "compile-only / Phase 1" boundary:** the candidate
  explicitly offers a 1-2 engineer-day deliverable for the compile/
  link-compatible `voxora-kernels` package **with Qwen kept on CPU**,
  separating the kernel patch from the 3-7 engineer-day Qwen BF16-to-
  F32/F16 device policy workstream. This correction is the direct
  response to T15's unverified 0.85 end-to-end estimate.

**2. `propuesta-minimax-T15` (runner-up) — AP 9.2, validator 9.5/10 ✅, 48/60 (6 sections).**

T15 carries the cleanest 2-file ~110-line in-tree patch with byte-
precise 282,810-byte PTX evidence. The validator reproduced the
byte count and the 0 `atom.add.f16` / 8 `softmax_f16` greps. T15's
principal weakness is the **unverified 0.85 end-to-end transcription
probability** (line 22) — the integrated candidate's G5 gate
explicitly defers that claim until a real WAV fixture is run on the
GTX 1080.

**3. `propuesta-minimax-T05` (third) — AP 9.0, validator 9.4/10 ✅.**

T05 carries the standalone `airvzxf/voxora-kernels` repo variant with
per-architecture profile taxonomy (sm_50..sm_120). Every SHA and
line number is exact. T05's principal divergence is the in-tree vs
standalone packaging question — the integrated candidate absorbs
T05's standalone reasoning as an **extraction gate** (multiple
independent consumers, multiple Candle versions, independent releases)
rather than a Phase 1 requirement.

**4. `propuesta-minimax-baseline-02` (fourth) — AP 8.9, validator 9.0/10 ✅.**

baseline-02 supplied the **sm_80 MoE floor** evidence
(`moe_wmma.cu:279,281` instantiates BF16 WMMA on Volta/Turing) and
the **test-no-stub rationale** (the current graph links without
`libmoe.a` because qwen3-asr 0.2.2 has no MoE references). The
integrated candidate inherits both. baseline-02's principal weakness
is the no-op stub risk + artifact path drift (`out/...` vs
`work/...`) — the integrated candidate drops the stub and corrects
the path.

#### 5.10.4 Within-cohort convergence at 22-cohort scale (9 themes, max 17/22)

The 22-agent cohort produced **9 convergent ideas** with the highest
convergence density in the corpus to date. The in-tree `[patch.crates-io]`
approach has 17/22 = **77% agreement** — significantly higher than Run
E's 12/21 = 57% on MV3+WXT and Run D's 4-6/6 = 67-100% on simpler
sub-aspects.

| # | Idea | Count | Originals that proposed it |
|---|------|------:|---|
| 1 | **In-tree `[patch.crates-io]` for `candle-kernels 0.9.2`** (vs standalone repo) | **17 of 22** | T15, T05, T10, P099, baseline-{01..06, 08, 09}, security-first, creative, minimal, observability, ci-github, cd-releases |
| 2 | **Pin exactly `candle-kernels = 0.9.2` with `bindgen_cuda::Builder`** (NOT 0.11.0 with `cudaforge::KernelBuilder`) | 18 of 22 | All 17 from idea #1 + baseline-07 (which pins the right version but for wrong reasons) |
| 3 | **Keep Cargo package identity `name = "candle-kernels"`** under directory brand `voxora-kernels` | 17 of 22 | Same 17 as idea #1 |
| 4 | **Reduce patch surface to 2 production files**: `src/reduce.cu` (gate `SUM_OP(__half, sum_f16)` at `>= 700`) + `build.rs` (skip MoE below floor) | 17 of 22 | Same 17 as idea #1 |
| 5 | **Byte-precise `nvcc -O3 -std=c++17 -arch=sm_61 -ptx` smoke test** as the install gate | **12 of 22** | T15 + baseline-{02, 08, 09} reproduced byte-for-byte; 8 others reference the recipe |
| 6 | **`__CUDA_ARCH__ >= 80` as the MoE/WMMA floor** (NOT `>= 70`) | 5 of 22 | baseline-02 (originator with launcher-line evidence), T05, baseline-06, baseline-09, integrated |
| 7 | **No upstream PR** to the candle repo | 22 of 22 (unanimous) | pre-agreed by the user |
| 8 | **Separate compile evidence from runtime/model correctness** | 22 of 22 (unanimous) | consensus wording |
| 9 | **Treat Maxwell sm_50/sm_52 as deferred** | 22 of 22 (unanimous) | nobody has hardware; `__half` arithmetic has sm_53 floor |

**Interpretation.** Items 7, 8, 9 are **safe defaults** with 22/22
agreement (pre-agreed constraints from the prompt). Items 1-4 are
**technical convergence** with 17/22 = 77% agreement — the LLM
intrinsic sampling variance surfaces the same minimal-patch design
across 22 attempts, with 4 divergent proposals (deepseek-flash,
observability, ci-github, creative) clustering on the wrong Candle
version (0.11.0 / `cudaforge`) and 1 divergent proposal (T05K50)
diverging on architectural grounds. Item 5 (byte-precise smoke test)
is the strongest **reproducibility convergence** in the corpus —
the 12/22 ratio of agents that ran `nvcc -arch=sm_61 -ptx` and
recorded the byte count is the empirical signal that the validator
role can produce physically-reproducible artifacts, not just
viability verdicts. Item 6 (`sm_80` floor) is the most-evidenced
**safety upgrade** — only 5 of 22 originally propose it, but those 5
include the originator (baseline-02) with launcher-line evidence
(`moe_wmma.cu:279,281`) and the integrated candidate.

This extends §6.3 (Run E) with two refinements:

1. **Cross-pollination scales to non-software-stack domains.** Run F's
   prompt is a kernel-level / GPU-binary decision problem, not a web
   stack or CLI toolchain. The cohort still converges on 9 themes at
   17/22 max agreement. The convergence phenomenon is not specific to
   software-stack selection.
2. **Convergence density varies by decision-space entropy.** Run F's
   in-tree patch idea has 17/22 = 77% agreement because there is one
   "right" modern answer (in-tree, minimal surface, lock to actual
   dependency graph). Run E's WXT+MV3 has 12/21 = 57% because the
   decision space has more legitimate alternatives (esbuild vs Vite
   vs WXT). The §6.3 finding extends: convergence density correlates
   with **decision-space entropy**, not just prompt complexity.

#### 5.10.5 Defect detection at 22-cohort scale (~7 distinct defects)

The validator's per-section viability reports flagged **~7 distinct
defects** in the 22-cohort. This is **lower than Run E's ~13 defects
at 21-cohort** despite a similar cohort size. The lower count is
consistent with §6.4 (Run E): **defect detection scales with prompt-
complexity per-axis**, not just cohort size.

| # | Defect | Affected originals | Category |
|---:|--------|-------------------:|----------|
| 1 | Wrong candle-kernels version target (0.11.0 / `cudaforge` API) | deepseek-flash, observability, ci-github, creative (4 affected) | API version drift |
| 2 | Hallucinated BF16 quote (cites `qwen3-asr-rs` comment that doesn't exist) | baseline-05 | Citation fabrication |
| 3 | KCP indentation bug + `CUDA_TOOLKIT` operator-precedence trap | ci-github (1 affected, 2 bugs) | Tooling bugs |
| 4 | Malformed patch hunks (empty `@@` hunk headers) | minimal | Patch format error |
| 5 | 3 structural bugs (undefined helper, wrong Cargo metadata, missing kernel paths panic) | T10K200 | Structural bugs |
| 6 | Standalone crate not resolvable as `candle-kernels` | T05K50 | Architectural flaw |
| 7 | False "patch is sufficient for qwen3-asr on Pascal" claim | baseline-07 | Runtime overclaim |

**Refined §6.4 finding (defect detection scales with cohort size AND with domain complexity):**

| Run | Cohort | Domain complexity | Defects caught | Detection rate |
|---|---|---|---:|---:|
| Run D (2026-07-13) | 6 baselines | Rust CLI (1 requirement) | 2 | 33% (2/6) |
| Run E (2026-07-15) | 21 mixed | Firefox WebExtension (6 requirements) | ~13 distinct | 62% (13/21) |
| **Run F (2026-07-16)** | **22 mixed** | **CUDA kernel compat (1-2 core blockers + secondary axes)** | **~7 distinct** | **32% (7/22)** |

Run F's defect count is lower than Run E's despite a slightly larger
cohort because Run F's prompt has **fewer orthogonal decision axes**
than Run E's. CUDA kernel compat is dominated by ONE blocker —
`atomicAdd(__half*, __half)` + `nvcuda::wmma` namespace — plus a
handful of secondary axes (Candle version, MoE policy, BF16 runtime,
Maxwell hardware). Run E's prompt had 6 user requirements (extraction,
images, archives, autofill, pagination, debug dump), each triggering
its own defect class.

#### 5.10.6 §6.2 partial restoration: integrator wins by source-attributed evidence

The +21 figure is **not a comparable quality margin**: the integrated candidate was scored over seven sections because it added the synthetic "Why this beats the field" row, while each original was scored over six. The comparable result is the **+0.2 AP margin** (9.4 vs 9.2), alongside the integrated validator's 9.7/10 vs T15's 9.5/10. This is therefore a partial restoration of the §6.2 observation, not a refutation of Run E's counter-evidence.

- **Installations (10 vs 9, +1):** the integrated candidate adds the
  direct patched-PTX gate (`nvcc -O3 -std=c++17 -arch=sm_61 -ptx` +
  `grep -c 'atom.add.f16'` / `grep -c 'softmax_f16'`) as an install
  step. The validator reproduced the byte-precise 282,810 B target.
  T15 had the recipe in the empirical section but not as an install
  step.
- **Considerations (10 vs 9, +1):** the integrated candidate drops
  T15's unverified 0.85 end-to-end estimate and replaces it with
  explicit "compile-only / Phase 1" boundary plus gates G1-G7. The
  G4 (BF16 dtype/device) and G5 (real ASR) gates explicitly defer the
  runtime claims that no proposal in the corpus can substantiate.
- **Why-beats-field (10 vs N/A, +10 synthetic):** new 7th-section
  construct with seven specific corrections anchored to evaluator
  line ranges. 18/18 source-attributed line citations verified
  accurate to ≤5 lines by the integrated validator.

The **+0.2 AP margin** is small and should be treated as a one-run observation, not as proof that source attribution caused the win. Run F's integrated candidate carries a **source-attributed evidence base** (18 line ranges citing the originals that supplied each section) that the validador independently verifies. This is the first run in the corpus where the integrator's claims are forensically traceable, but source attribution, lower decision-space entropy, and byte-precise validation are confounded.

**Why the integrator wins this time, but lost in Run E.** Three
factors:

1. **Source attribution as forcing function.** The Run F integrator
   was instructed (or self-imposed) to publish the source of each
   section. This means every claim is traceable to a verifiable
   origin, which both (a) reduces fabrication risk and (b) makes
   the validador's job much easier (verify the citation, not the
   claim). Run E's integrator did not carry source attribution
   and introduced 4 critical-path defects that no original had.
2. **Lower decision-space entropy.** Run F's prompt has fewer
   orthogonal axes than Run E's, so the integration surface is
   smaller and the chance of integrator-introduced defects is
   lower. Run F's 7 defects cluster on 7 distinct categories;
   Run E's 13 defects cluster on 13 distinct categories (each
   user requirement triggering a separate defect class).
3. **Byte-precise validator reproducibility.** Run F's validator
   produced **physically-reproducible** artifacts (282,810-byte
   PTX, 0 `atom.add.f16`, 8 `softmax_f16` greps) that any future
   reviewer can reproduce on the same `nvcc` version. Run E's
   validator produced viability verdicts that depend on the LLM's
   internal reasoning, not on byte-exact physical evidence.

This refines the §6.2 proposition from v0.4 ("integration is typically
higher-scoring, except when the integrator introduces critical-path
defects") to:

> **§6.2 v0.5 proposition:** In the observed Run F configuration, an
> integrator with source-attributed inputs and independently checked
> physical evidence beat the best original by **+0.2 AP**, while Run E
> showed that an integrator can lose by **2.94 composite points** when it
> introduces critical-path defects. The corpus therefore supports a
> conditional proposition: `sintesis_central` can outperform the best
> original at lower step-5 cost, but its margin depends on prompt
> decision-space entropy, evidence discipline, and integrator competence.
> The Run F score denominators are not uniform, so the synthetic +21 total
> points are not evidence of a 21-point quality improvement. A "min viable
> integrator" mode (§7.5f) and a "source-attributed integrator" pattern
> (§7.5m) remain future-work controls requiring direct comparison.

#### 5.10.7 validador webfetch gateway-timeout — new failure mode

Run F observed a **validador subagent webfetch gateway-timeout bug**
that affected 5 of 22 originals on first attempt:

- `propuesta-minimax-security-first`
- `propuesta-minimax-observability`
- `propuesta-minimax-T10`
- `propuesta-minimax-P099`
- `propuesta-minimax-baseline-06`

In each case the validador subagent called `webfetch` on URLs from
external references in the proposals. Each call **hung indefinitely**
(no response, no timeout from the opencode SDK). This is a distinct
headless validation/tool-call failure from Run E's `baseline-09`
truncation and permission issues; Run E has no independently documented
webfetch hang. The root cause remains an open question (opencode SDK,
LLM tool-call budget, or network policy).

**Mitigation applied:** the orchestrator re-launched the affected
validador subagents with a tightened prompt that:

1. Forbids `webfetch`, `curl`, `wget`, and any network access.
2. Requires a 30-second bail timeout on any tool call that hangs.
3. Directs the validator to consult **local files only** (`/home/wolf/
   workspace/projects/{voxora, telora, candle}` and `~/.cargo/registry/
   src/.../candle-kernels-0.9.2/`).

After the tightening, the remaining 18 validador invocations
completed in **35-65 seconds each** consistently, with no hangs.

**Open question:** is this an opencode SDK bug, an LLM-side tool-call
budget bug, or a network-policy issue specific to this VPS? Run E
observed the same class of hang. The bug needs upstream investigation
or a permanent prompt-template hardening; see §7.5j follow-up.

**5 propuesta originals also initially gateway-timed out**, but for a
different reason (MiniMax provider gateway timeout on long system
prompts + parameter-sweep agents). Mitigation: wipe workdir + retry.
All 5 succeeded on retry. This is a different bug class than the
validador webfetch issue.

### 5.11 Empirical confirmation: SDK temperature clamp (2026-07-18)

§5.7 documented the project's epistemic-honesty approach to the
parameter validation table: when a cell declares `temperature=1.5`
(out of Anthropic spec), the proposal records it as `unknown /
probably clamped to 1.0` because the project could not intercept the
HTTP request. The `v1.2.2 priority fix` noted in §5.7 — *"instrument
the opencode SDK (or upstream gateway) to return resolved sampling
parameters in the response envelope"* — was deferred.

This section reports the empirical resolution of that priority fix:
a minimal HTTP proxy that intercepts opencode's outgoing requests to
the MiniMax Anthropic-compatible endpoint. The proxy is the only
instrumentation layer between opencode and MiniMax, so every HTTP
body that the SDK sends is captured verbatim.

#### 5.11.1 Method

A local proxy listening on `127.0.0.1:8888`, written in 40 lines of
Python stdlib (`http.server.BaseHTTPRequestHandler`), was placed in
front of the MiniMax endpoint by overriding the provider's `baseURL`
in a project-level `.opencode/opencode.json`:

```json
{
  "provider": {
    "minimax-coding-plan": {
      "npm": "@ai-sdk/anthropic",
      "options": {
        "baseURL": "http://127.0.0.1:8888/v1",
        "apiKey": "sk-cp-stub-proxy-receives-real-key-via-env"
      },
      "models": {
        "MiniMax-M3": {
          "name": "MiniMax M3 (proxy test)",
          "options": { "thinking": { "type": "disabled" } }
        }
      }
    }
  }
}
```

The proxy logs the full request body (including `model`,
`temperature`, `top_p`, `top_k`, `messages`, `system`) to
`/tmp/opencode-t10-vs-t15-t20/proxy.log` and returns a stub 200
response (the test only requires reading the body; the response is
discarded). The proxy was placed in a fresh temp dir
(`/tmp/opencode-t10-vs-t15-t20/`) with six agent files
(`.opencode/agents/test-T{00,01,05,10,15,20}.md`), each declaring a
different `temperature` in frontmatter and `mode: primary` (so
`opencode run --agent test-T*` loads them as the primary session
agent).

The MiniMax Anthropic-compatible endpoint is at
`https://api.minimax.io/anthropic/v1/messages` (per opencode config;
see `~/.config/opencode/opencode.json`). The proxy intercepts POST
requests on `http://127.0.0.1:8888/v1/messages`. No outbound traffic
to MiniMax occurs during this test.

Two side discoveries during method development:
- **Mode gate**: opencode's `--agent` flag rejects subagent-mode
  agents (`mode: subagent`) with `"agent X is a subagent, not a
  primary agent. Falling back to default agent"` — the fallback
  loses all agent-specific temperature. All test agents were set to
  `mode: primary` to enable per-agent temperature loading.
- **Adaptive thinking forced**: the bundled SDK contains a
  hard-coded branch (`minimax-m3") && $.model.api.npm ===
  "@ai-sdk/anthropic"` → `Z.thinking = {type:"adaptive"}`) that
  forces adaptive thinking for `minimax-m3` models. Adaptive
  thinking strips `temperature` from the request before the
  Anthropic-spec clamp can run. To isolate the temperature question,
  the model config sets `options.thinking = {type:"disabled"}` so the
  temperature field survives into the HTTP request body.

#### 5.11.2 Results

Six agents, each invoked once with the minimal prompt `"OK"`, produced
six POST bodies. Parsed `temperature` field:

| Agent | Frontmatter `temperature` | **HTTP body `temperature`** | Status |
|---|---|---|---|
| `test-T00` | `0.0` | `0` | ✓ in-range, passes through |
| `test-T01` | `0.1` | `0.1` | ✓ in-range, passes through |
| `test-T05` | `0.5` | `0.5` | ✓ in-range, passes through |
| `test-T10` | `1.0` | `1` | ✓ in-range, passes through |
| **`test-T15`** | **`1.5`** | **`1`** | ⚠️ **clamped to 1.0** |
| **`test-T20`** | **`2.0`** | **`1`** | ⚠️ **clamped to 1.0** |

The clamp source is verified in the bundled SDK source
(`@ai-sdk/anthropic@3.0.82`, extracted via `strings` from
`/usr/bin/opencode`):

```js
if (q != null && q > 1)
  j.push({ type: "unsupported", feature: "temperature",
           details: `${q} exceeds anthropic maximum of 1.0. clamped to 1.0` }),
  q = 1;
else if (q != null && q < 0)
  j.push({ type: "unsupported", feature: "temperature",
           details: `${q} is below anthropic minimum of 0. clamped to 0` }),
  q = 0;
```

For MiniMax-M3, `rejectsSamplingParameters` is `false` (the SDK only
returns `true` for known Claude model ids), so the "reject
temperature" path is skipped — but the `q > 1` clamp above runs
unconditionally for every model.

#### 5.11.3 Implications for v1.7 sweep-matrix design

The v1.7 sweep matrix
(`docs/proposals/001-orquestador-nativo-opencode.md` §4, CHANGELOG
v1.7) includes 5 temperature values × 3 top_p × 3 replicas = 45 cells,
of which the T15 and T20 cells (30 of 45, two-thirds) declare
`temperature` outside the Anthropic spec range. Per §5.11.2, every one
of these 30 cells reaches MiniMax as `temperature=1.0`. The T15 and
T20 cells are therefore **not** testing the declared `temperature`
value — they are testing `temperature=1.0` with the declared
`top_p` and the per-cell replica.

Concretely, the 30 cells form two equivalence classes under the
clamp:
- `propuesta-minimax-T15P00-{01,02,03}` ≡ `propuesta-minimax-T10P00-{01,02,03}` (6 agents, all T=1.0, P=0.0)
- `propuesta-minimax-T15P05-{01,02,03}` ≡ `propuesta-minimax-T10P05-{01,02,03}` (6 agents, all T=1.0, P=0.5)
- `propuesta-minimax-T15P10-{01,02,03}` ≡ `propuesta-minimax-T10P10-{01,02,03}` (6 agents, all T=1.0, P=1.0)
- `propuesta-minimax-T20P00-{01,02,03}` ≡ same T10P00 cluster (already counted)
- `propuesta-minimax-T20P05-{01,02,03}` ≡ same T10P05 cluster
- `propuesta-minimax-T20P10-{01,02,03}` ≡ same T10P10 cluster

So 30 of the 45 T×P cells collapse to 9 effective distinct conditions
at T=1.0, each with 6 replicas (3 from T10 + 3 from T15 or T20). The
matrix still serves as a useful intrinsic-variance probe for T=1.0,
but **does not** answer the question the v1.7 design posed about
"out-of-spec" sampling.

#### 5.11.4 Implications for historical results (Run E, Run F)

Run E §5.9 and Run F §5.10 both feature `propuesta-minimax-T15` as a
top finisher (Run E: AP 8.99 winner; Run F: AP 9.2 runner-up to the
integrator). §5.7 already noted the epistemic caveat that T15 was
"probably clamped to 1.0" but the project could not verify. With the
empirical confirmation, those T15 wins are now reinterpreted as:

- **Content**: produced at `temperature=1.0`, not `1.5`.
- **Why it won despite being "the same as T10"**: at T=1.0, the
  sampler has more freedom than at the baseline default (T=0.7),
  producing longer, more elaborate outputs that score higher on the
  evaluator's `Completeness` and `Technical Quality` axes. The Run D
  §5.8.3 intrinsic-variance study (6 identical-input proposals at
  T=0.7) showed variance of ~6 points on 50; that variance is
  similar at T=1.0, so a single T15 (T=1.0) run getting a lucky
  high-completeness sample is consistent with the distribution.
- **Why a `propuesta-minimax-T10` agent did not also win** in the
  same runs: T15 was the only T=1.0 cell in v1.3 (the version used
  for Runs E and F). There was no `propuesta-minimax-T10` agent in
  v1.3 to act as a control; the v1.7 matrix was designed precisely
  to fill that gap.

A direct re-test (T10 vs T15 declared, both received as T=1.0, same
prompt, same prompt seed) is needed to confirm the variance hypothesis.
Pending.

#### 5.11.5 Implications for future parameter work

Three open questions remain that the proxy method could answer but
the v1.7 sweep matrix design cannot:

1. **Does MiniMax apply its own server-side clamp on `temperature >
   1.0`?** If yes, raw curl tests with `temperature=1.5` would also
   arrive as `1.0`, and MiniMax's temperature range is effectively
   `[0, 1]`. If no, MiniMax would honor T=1.5 and produce outputs
   different from T=1.0 in ways the v1.7 sweep cannot measure.
   Method: `curl` directly to
   `https://api.minimax.io/anthropic/v1/messages` with
   `temperature=1.5` in the body, bypassing the SDK entirely.
2. **Does MiniMax honour `top_p` and `top_k` as sent?** The v1.7
   matrix tests 3 top_p values × 45 cells, but the SDK does not
   strip top_p (only temperature under adaptive thinking). Whether
   MiniMax applies top_p to its sampler is an open empirical
   question — see H1 in the upcoming Stage 1 probe.
3. **Does `temperature=0` behave as argmax in MiniMax?** The §5.8.3
   intrinsic-variance study suggested floating-point non-determinism
   affects even low-T outputs, but a focused study (e.g. 50 runs at
   T=0 with a token-position-controlled prompt) is needed.

These questions are scoped for the upcoming empirical session
(see §7 Future work).

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

#### 6.2.6 Run E counter-evidence: integration lost to best original (2026-07-15)

Run E is the first documented case in opencode-moa where
`sintesis_central` lost to the strongest original in a uniform-cohort
+ empirical-validation run. The integrated proposal ranked **16/22
with composite 6.05**, while the winning original
`propuesta-minimax-T15` ranked 1/22 with composite **8.99**. The
**2.94-point gap** is the opposite direction of Run D's +1-point
margin, and it is the **largest §6.2 gap observed in any run to
date**.

**What went wrong.** The integrator introduced 4 critical-path
defects (see §5.9.6 for the full list):

1. **`packTar` sample imports `Pack` as a runtime value and calls
   `new Pack()`** — but `tar-stream@3.2.0` exposes the lowercase
   `pack()` factory. The snippet fails both TypeScript and runtime
   validation.
2. **Archive layout and Markdown template disagree** — some sections
   use `./assets/` and others emit `./quiz/...`.
3. **`pnpm audit --prod --audit-level high`** reaches the retired
   npm audit endpoint and returns HTTP 410.
4. **`packageManager: "pnpm@10.x"`** is not an exact Corepack
   version and is rejected at install time.

Plus 3 secondary defects (Android compatibility contradiction,
Markdown example drift, factually wrong T15 criticism). The
integrator's `AP=1` was forced by the system's strict AP
recalibration: 3+ failed sections → AP=1 per the system-prompt table.

**Why this is important.** Run B's `sintesis_central` evidence was
self-evaluated (not validated by step 2 validador). Run D's evidence
showed integration winning by +1 point on a 6-baseline cohort. Run E
is the first run where:

- The cohort is large enough (21 vs 6) to surface non-trivial
  integration challenges (the integrator had to consume 21 originals
  + 03 + 04 + 20 validations in one pass).
- The prompt domain is non-trivial (a 6-requirement Firefox
  WebExtension with images, archives, autofill, pagination, debug
  dump, optional CLI).
- The integrated proposal was empirically validated (not
  self-evaluated) and the 4 critical-path defects were caught by the
  step 6 validador.

**Refined §6.2 proposition (v0.4):**

> **`sintesis_central` produces a winner that is typically higher-scoring
> than the best individual original (Run B, Run D) at ~6× lower step-5
> cost, but the integrator can introduce critical-path defects that
> cause it to lose to the best original (Run E). The integrator's
> value comes from (a) consolidating the cohort's convergent ideas
> into a single coherent proposal and (b) detecting and fixing field
> defects that no single proposer self-corrected. The integrator's
> risk is (c) introducing new defects in the consolidation step
> itself — defects that the originals did not have, that the
> validador then catches, and that force the integrated proposal's
> AP to 1 (or otherwise below the best original's score).** The §6.2
> proposition therefore holds *when the integrator is competent* and
> breaks *when the integrator introduces critical-path defects*. A
> "min viable integrator" mode that only attempts integration when
> the cohort has at least N viable originals is proposed in §7.5f
> as a future-work item.

**Implication for v1.3.x design.** The v1.3 default
`step_5_modo: sintesis_central` remains the right default for small
to medium cohorts (6-12 agents) where the integration surface is
manageable. For large cohorts (20+ agents) with non-trivial prompts,
the integrator's consolidation step has more room to introduce
defects. The "min viable integrator" mode (§7.5f) is a
defect-prevention control for these cases.


#### 6.2.7 Run F partial restoration: evidence-grounded integration (2026-07-16)

Run F partially restores the positive direction observed in Run D, but it does not provide the missing same-input `self_improve` control. The integrated candidate scored **9.4 AP** versus T15's **9.2 AP**, and its independent validation scored **9.7/10** versus T15's **9.5/10**. The integrated candidate also carried an explicit source-attribution table: all 18 cited ranges were checked to within five lines, and the patched `sm_61` PTX result was reproduced as 282,810 bytes with zero `atom.add.f16` matches and eight `softmax_f16` matches.

The reported **69/70 versus 48/60** total must not be interpreted as a 21-point quality margin. The integrated candidate received a seventh, synthetic "Why this beats the field" section that the originals did not have. AP is the comparable headline metric, while the validation score and the byte-precise artifact provide independent evidence of reproducibility. Run F therefore supports a narrower claim: a source-attributed integrator can beat the best original in a low-entropy technical prompt, but this one-shot result does not establish causality for source attribution or overturn Run E's counter-evidence.

The remaining explanations are confounded: source attribution, lower decision-space entropy, and stronger physical validation all occur in the same run. A controlled repeat must vary the attribution requirement and the step-5 mode while keeping the prompt, roster, and evaluation rubric fixed.

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

#### 6.3.4 Cross-pollination at 21-cohort scale (Run E, 2026-07-15)

Run D established that cross-pollination is observable with a
**6-agent uniform-model cohort** (10 ideas, 4+ of 6 majority).
Run E tests generalizability to a **21-agent mixed cohort** (8 Group A
+ 6 Group B + 6 Group C + 1 external) on a non-Rust, non-CLI prompt
domain. The cohort is 3.5× larger than Run D and the prompt domain
is qualitatively different (Firefox WebExtension with 6 user
requirements vs Rust CLI with 1 requirement).

**Run E convergent ideas (3+ of 21 agree):**

| # | Idea | Count |
|---|------|---:|
| 1 | **MV3 + WXT 0.20.27** (or WXT-equivalent Vite generator) as the build floor | **12 of 21** |
| 2 | **Redaction of `sesskey` / `MoodleSession` / `userid` / `attempt` / cookies** | 11 of 21 |
| 3 | **`fflate` for ZIP** (valid — `fflate@0.8.3` exports `zipSync` and `gzipSync`) | 9 of 21 |
| 4 | **Turndown 7 + DOMPurify 3 + Zod** as the HTML→Markdown + validation chain | 8 of 21 |
| 5 | **`incognito: not_allowed` + scoped `host_permissions`** (only `/mod/quiz/attempt.php*`) | 8 of 21 |
| 6 | **Pagination walker** — `fetch()` `/mod/quiz/attempt.php?…&page=N` with cookie credentials | 7 of 21 |
| 7 | **Two-tier debug** ("safe report by default / opt-in structural with consent preview") | 6 of 21 |
| 8 | **Native Messaging host in Python stdlib** for the AI-from-terminal bridge | 5 of 21 |
| 9 | **Hand-rolled TAR or `tar-stream`** (because `fflate` has no `tar()` export — verified by the validator) | 5 of 21 |

**This extends §6.3 in two important ways:**

1. **Cross-pollination scales to 21-cohort and to a non-trivial
   prompt domain.** Run D's 6-agent cohort produced 10 convergent
   ideas on a 1-requirement prompt; Run E's 21-agent cohort produced
   9 convergent ideas on a 6-requirement prompt. The number of
   convergent ideas does not grow linearly with cohort size (more
   agents = more diverse opinions, which can *reduce* agreement per
   idea), but the **absolute number of "safe defaults"** — ideas
   with 8+ of 21 agreement — increases from 4 in Run D to 6 in Run E.
   The WXT+MV3 floor (12/21) is the strongest convergence in the
   corpus to date.

2. **Cross-pollination is a property of LLM sampling temperature,
   AND of prompt complexity.** Run E's prompt has 6 requirements
   (extraction, images, archives, autofill, pagination, debug dump,
   optional CLI). Each requirement triggers a separate convergence
   pattern. Run D's prompt had 1 requirement; the cohort converged
   on 10 sub-aspects of that one requirement. Run E's cohort
   converges on 9 *requirements-level* themes. This is direct
   evidence that **the convergence phenomenon scales with the
   number of orthogonal decision axes in the prompt**, not just
   with the number of agents in the cohort.

**Mechanism.** The 9 convergent themes in Run E cluster into 3
groups:

- **Stack/framework choices (5 themes):** MV3+WXT, Turndown+DOMPurify+Zod,
  fflate+tar-stream, Native Messaging, pagination walker. These
  are technical-stack decisions where the LLM is most likely to
  converge because there is one "right" modern answer.
- **Security/privacy (2 themes):** redaction of `sesskey` etc.,
  `incognito: not_allowed` + scoped `host_permissions`. These are
  forced by AMO / Firefox 140+ policies and are converged on by
  8-11 of 21 agents.
- **UX/operational (2 themes):** two-tier debug, hand-rolled TAR.
  These are design choices that the LLM consistently prefers for
  pragmatic reasons (offline-first, no-op defaults).

This is consistent with the Run D finding that **the LLM's intrinsic
sampling variance is sufficient to surface convergent design
patterns.** Run E shows that the convergence phenomenon holds at
3.5× the cohort size and across a qualitatively different prompt
domain (Firefox WebExtension vs Rust CLI), reinforcing the §6.3
proposition.

**Implication for cohort design.** If cross-pollination scales with
prompt complexity (number of orthogonal decision axes), then for a
prompt with N requirements, a cohort of ~3N agents is likely
sufficient to surface the convergent defaults. Run E's 21-agent
cohort on a 6-requirement prompt (ratio 3.5:1) found 9 themes
covering all 6 requirements. Smaller cohorts on complex prompts
(Run D's 6-agent on 1-requirement, ratio 6:1) also found convergence
but covered fewer orthogonal axes. **The 3-4× ratio is a heuristic,
not a precise rule** — but it is a useful starting point for users
configuring their own `agentes_a_competir`.

#### 6.3.5 Cross-pollination in a fourth prompt domain (Run F, 2026-07-16)

Run F extends the cross-pollination observation from Rust CLI and Firefox WebExtension work to a CUDA-kernel compatibility problem. Nine themes appeared across the 22 configured proposals; the strongest technical convergence was the in-tree `[patch.crates-io]` approach for the exact `candle-kernels 0.9.2` package, with 17/22 proposals. Three prompt constraints were unanimous: no upstream Candle PR or issue, separation of compile evidence from runtime correctness, and deferral of Maxwell `sm_50/sm_52` support.

The higher 17/22 agreement should not be read as evidence that one orchestration setting is universally better. The CUDA task has a lower-entropy decision space than the Firefox task: a small number of architecture, API-version, and BF16/MoE blockers dominate the design. The result supports extending the proposition to a new domain, while leaving the relationship between convergence density, decision-space entropy, and cohort size as an open hypothesis.

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

**Run E limitations (2026-07-15, moodle-quiz-extractor):**

- **Single iteration.** `mejora` calculation impossible; the iter-2
  trajectory is speculative. The 21-cohort field is large enough
  that iter-2 feedback propagation would likely saturate quickly,
  but this is unverified.
- **Spanish prompt domain.** The user's prompt is entirely in
  Spanish; the proposals mix Spanish (titles, comments) and English
  (technical jargon, code identifiers). The cross-language
  comparison with Runs A-D (all English) is qualitative on
  technical content, quantitative on the convergence counts and
  defect catalog.
- **No cross-model diversity in the 21-cohort.** 20 of 21 agents
  are `minimax-coding-plan/MiniMax-M3`. The only cross-model
  agent (`propuesta-deepseek-flash` via `opencode-go`) ranked 13/22
  with composite 6.63 — too small a sample to draw cross-model
  conclusions. Run C's 11 OCG + 41 MiniMax 52-cohort remains the
  cross-model reference. Run E's contribution is the
  **within-cohort diversity** (8 baselines + 6 Group B + 6 Group C
  + 1 external), not the cross-model diversity.
- **Byte-derived cost estimate.** ~$0.20 estimated from Run C
  per-agent average; no `model_remains` telemetry polled. The Run C
  cost was $0.16 for 41 MiniMax; scaling to 50 invocations in Run
  E is approximate.
- **sintesis_central counter-evidence is one-shot.** The integrated
  proposal losing by 2.94 points is dramatic, but it depends on
  the 4 specific defects the integrator introduced. A different
  integrator (or different parameter sweep) might have produced a
  winning integrated proposal. Repeating with `self_improve × 21`
  would be the gold-standard §6.2 control (§7.5d follow-up).
- **No iter-2 feedback-aware iteration.** Step 1 prompt template
  (orquestador.md lines 184-190) instructs proposers in iter-N>1
  to read iter-1's `05-propuesta-integrada.md`. Run E did not
  exercise this path. The mechanism validated in Run B (single
  iter-2 propuesta converged to the iter-1 integrator's stack)
  needs a 21-agent iter-2 confirmation.
- **1 DESCALIFICADA at the evaluator level.** Only `T05K50` was
  formally flagged as DESCALIFICADA. With `descalificar_fallida ==
  false`, additional candidates that validation marked ❌ NOT
  VIABLE are kept in the ranking as ⚠️ — including baseline-04
  (3 failed sections), ci-github (4 failed sections), and the
  integrated proposal itself (4 failed sections). A future run
  with `descalificar_fallida == true` would strip 4-5 more
  candidates.
- **Group B coverage incomplete.** Run E selected only 6 of the 13
  Group B variants (creative, minimal, security-first,
  observability, ci-github, cd-releases). The remaining 7 (a11y,
  errors, i18n, portable, rustdoc, testable, maintainable) were
  not exercised. A future 21-cohort with all 13 Group B would
  surface additional convergent/defective patterns.
- **`baseline-09` aborted after 2 empty retries.** Only 20 of the
  9 Group A baselines + 6 Group B + 6 Group C + 1 external = 22
  agentes were successfully written, but the user-level roster
  is 9 baselines (`propuesta-minimax-baseline-{01..09}`) so
  baseline-09 was a planned cohort member. The 21-actual cohort
  is the 22-expected minus baseline-09. This is the same class
  of bug as Run D §5.8.7 (step-1 tool-call truncation), affecting
  a different agent. Mitigation strategies listed in §7.5a
  remain open.

**Run F limitations (2026-07-16, voxora-kernels):**

- **Single iteration and one-shot comparison.** The convergence threshold was not exercised, and no `self_improve × 22` control ran. The +0.2 AP result is a partial restoration, not a general confirmation of §6.2.
- **Configured cohort versus excluded agents.** The project-level JSON contained 22 agents. Five additional agents were excluded before configuration and produced no files; the run must not be described as a 27-agent roster that was later trimmed.
- **Non-uniform score denominator.** The integrated candidate was scored over seven sections, including the synthetic "Why this beats the field" row; originals were scored over six. The +21 total-point difference is not comparable.
- **Estimated operations.** The ~78-minute wall-clock and ~$0.20 cost are reconstructed or extrapolated; no Run F `model_remains` telemetry was collected, and logs are not a complete timing source.
- **Validator timeout mitigation, not repair.** The webfetch hang was mitigated by a local-files-only prompt and a 30-second cap, but the SDK/provider/policy root cause remains unknown.
- **Hardware and runtime boundary.** The 282,810-byte PTX target is specific to `nvcc 12.9.86`; G5 real-audio transcription was not executed, BF16 runtime support remains unresolved, and Maxwell support is deferred.
- **Causal interpretation.** Source attribution, lower decision-space entropy, and byte-precise evidence co-occur in Run F. Their individual contribution cannot be separated without controlled repeats.

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
5a. **NEW: Investigate step-1 tool-call truncation (Run D §5.8.7).**
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
5c. **NEW: Bigger uniform cohort (Run D follow-up).** Repeat fib-rust-cli
    with 15 baselines (the v1.3 expansion) and compare variance,
    convergence, and integrated winner score against the 6-baseline
    cohort. Goal: confirm the "15 baselines strengthens the statistical
    base" claim in v1.3 CHANGELOG §Added (v1.3) and quantify how
    within-cohort convergence scales with cohort size.
5d. **NEW: Cross-domain extension repeat (Run E §7.5d).** Pick a
    different browser-extension or web-side domain (e.g., Chrome
    MV3 extension for a different LMS, Safari WebExtension, or a
    PWA install manifest). Run with a similar 21-agent cohort +
    `sintesis_central` + `validacion_empirica: true`. Goal: confirm
    Run E's findings (defect detection rate ~13/21, cross-pollination
    scaling to 9 themes, integrator-can-lose edge case) generalize
    beyond Firefox WebExtensions. The Run D §6.3 finding (within-cohort
    convergence at uniform-model 6-cohort) and the Run E §6.3.4
    finding (within-cohort convergence at mixed 21-cohort) need a
    third prompt domain to confirm the prompt-complexity scaling
    hypothesis.
5e. **NEW: Investigate T=1.5 gateway clamping (Run E §7.5e).**
    T15 (T=1.5) won Run E but T=1.5 is out of Anthropic spec. Is
    the gateway silently clamping to 1.0, or is the corpus just
    self-consistent at T=1.5? Need SDK telemetry that returns
    resolved sampling parameters (already a v1.2.2 priority from
    §5.7). If T=1.5 is silently clamped to 1.0, then the v1.3
    roster decision to keep T15 (and drop T00/T03/T08) should be
    reviewed. The Run C §5.7 honesty probe found that of 38
    propuestas with `## Generation parameters` sections, only 2
    reported a real `temperature_actual` — meaning we cannot
    currently distinguish "T=1.5 applied as-is" from "T=1.5
    clamped to 1.0" from the proposal text alone.
5f. **NEW: Min viable integrator mode (Run E §7.5f).** Run E's
    integrator lost due to 4 critical-path defects. Propose a "min
    viable integrator" mode that only attempts integration when at
    least N originals are viable (e.g., N=3 with viability ≥ 8.0/10)
    or skips integration otherwise. Alternative: integrate only the
    validated sections of each original, never the proposed sections.
    The goal is to prevent the integrator from introducing defects
    that the originals did not have. The mode is opt-in via a new
    `step_5_modo: min_viable_integrator` value (or a
    `integrator_min_viability: 8.0` threshold), and would also
    produce a "no integration attempted" warning file when triggered.
     This is the highest-priority follow-up motivated by Run E's
     §6.2 counter-evidence.
5j. **NEW: Investigate the Run F validador webfetch timeout.** Run F
    mitigated five initial hangs by forbidding network access and imposing
    a 30-second tool-call cap, but did not establish the SDK root cause.
    Compare local-files-only validation with an explicitly permitted network
    mode and record whether the failure is provider-, SDK-, or policy-level.
5k. **NEW: Run the direct Run F §6.2 control.** Repeat `voxora-kernels`
    with `step_5_modo: self_improve` on the same 22-agent configured cohort,
    prompt, and rubric. Compare the best self-improved original with the
    source-attributed `sintesis_central` candidate without using the
    synthetic seventh section as a quality margin.
5l. **NEW: Repeat Run F in another kernel domain.** Use a comparable
    cohort for ROCm/HIP, Triton, WebGPU shader translation, or another
    consumer/version boundary to test whether the convergence and defect
    patterns generalize beyond `candle-kernels 0.9.2`.
5m. **NEW: Test source attribution as a controlled intervention.** Add an
    opt-in `integrator_source_attribution_required` configuration and compare
    otherwise identical runs with and without it. Require the validator to
    check every cited range, but do not infer causality from Run F alone.
5n. **NEW: Re-run with the five excluded agents explicitly configured.** Add
    `propuesta-mimo`, `propuesta-deepseek`, `propuesta-qwen37-plus`,
    `propuesta-kimi`, and `propuesta-glm` to produce a 27-agent configured
    cohort, then compare convergence and defect categories with Run F's 22.
5o. **NEW: Execute the real G5 WAV gate.** Apply the integrated Phase 1
    patch in the writable Voxora checkout, implement or verify the separate
    BF16 device policy, and compare CPU/GPU transcription on the GTX 1080.
    Until G4 and G5 pass, Qwen CUDA remains unsupported for Telora production.
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
tasks (Rust GUI with overlay popup semantics, Rust Fibonacci CLI,
Firefox WebExtension for Moodle quiz extraction, and CUDA kernel
compatibility) for under $12 per multi-iteration run. **Six** empirical
runs (2026-07-11 Run A, 2026-07-12 Run B, 2026-07-13 Run C, 2026-07-13
Run D, 2026-07-15 Run E, and 2026-07-16 Run F) test the same and
adjacent prompts with progressively refined bundle versions:

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
- **Run E (2026-07-15, v1.3, 21-agent iter-1, moodle-quiz-extractor,
  N=1 iter):** produced the first **§6.2 counter-evidence**, the
  first §6.3 evidence at 21-cohort scale, and the first defect
  catalog at scale.
  - **§5.9.2 + §6.2.6:** the integrated proposal **lost** to the
    best original by 2.94 points (6.05/10 vs 8.99/10). The
    integrator introduced 4 critical-path defects that the
    originals did not have (broken `packTar` import, asset path
    contradiction, `pnpm audit` endpoint retired, `packageManager`
    non-exact), forcing the integrated proposal's AP to 1. **This
    is the first case in opencode-moa where `sintesis_central`
    lost to the strongest original** in a controlled
    + empirically-validated run. The §6.2 proposition is refined
    to "integration is typically higher-scoring, except when the
    integrator introduces critical-path defects." The
    "min viable integrator" mode is proposed in §7.5f as a
    defect-prevention control for large cohorts.
  - **§5.9.3:** **first T-variant to win the ranking.**
    `propuesta-minimax-T15` (Group C, T=1.5 sweep) led with
    composite 8.99 and viability 9.2. This validates the v1.3
    roster decision to keep T15 (and drop T00/T03/T08) — the
    Group C parameter-sweep agents are competitive with the
    Group A baselines, not redundant.
  - **§5.9.4 + §6.3.4:** cross-pollination scales to 21-cohort
    and to a 6-requirement prompt (vs Run D's 1-requirement
    prompt). The cohort produced 9 convergent themes (3+ of 21
    agreement each), with the WXT+MV3 floor at 12/21 — the
    strongest convergence in the corpus to date. **The §6.3
    proposition is refined to "cross-pollination scales with
    prompt complexity (number of orthogonal decision axes), not
    just with cohort size."** For a prompt with N requirements,
    a cohort of ~3N agents is likely sufficient to surface the
    convergent defaults.
  - **§5.9.5:** defect detection rate is **~13 of 21 (62%)** for
    distinct defects across the corpus (4 phantom npm packages,
    2 wrong selectors, 1 retracted API endpoint, 1 wrong
    cross-API, 1 invalid manifest JSON, 1 invalid 32-char OTLP
    spanId, etc.). This is a **1.9× increase over Run D's
    defect rate (33%)** and a **6.5× increase in absolute
    defect count** (2 → 13). The validator's role scales with
    cohort size: it is **load-bearing for the cohort's overall
    trustworthiness**, not a courtesy.
  - **§5.9.7:** `sintesis_central` did **not** hang on the
    21-agent cohort (despite Run C's earlier 5-agent hang). This
    supports the hypothesis that the hang is specific to
    step-5 subagent context size, not to the step-1 batch size.

- **Run F (2026-07-16, v1.3, 22-agent configured cohort, voxora-kernels,
  N=1 iter):** extends the study to CUDA kernel compatibility for Pascal
  `sm_61` and provides the first byte-precise physical validation in the
  corpus. The integrated proposal wins by **+0.2 AP** (9.4 vs 9.2), with
  validator 9.7/10 vs 9.5/10 and 18/18 source-attributed line ranges
  independently checked. Its patched `sm_61` PTX is reproduced at 282,810
  bytes with 0 `atom.add.f16` and 8 `softmax_f16` matches on `nvcc
  12.9.86`. The apparent 69/70 vs 48/60 total is not comparable because
  the integrated candidate received a synthetic seventh section. Run F
  partially restores the positive §6.2 direction but does not run the
  same-input `self_improve` control; it also exposes a validator webfetch
  timeout that was mitigated with local-only validation, not fixed.

The combination of Run A, B, C, D, E, and F findings makes v1.3.x's
trimmed roster a defensible design choice on five dimensions:

1. **Cost:** 51% reduction with no quality loss (all unique
   contributions preserved, all fabrications removed).
 2. **Convergence:** the §6.3 finding from Run A, B, D, E, and F
    generalises across configured cohorts (12 → 6 → 21 → 22 agents)
    and across prompt domains (Rust GUI → Rust CLI → Firefox WebExtension
    → CUDA kernel compatibility). Cross-pollination is a property of
    LLM sampling temperature (Run D), prompt complexity (Run E), and
    decision-space structure (Run F), not a property of model diversity.
    Cross-model consensus produces a verifiable winner (Run C
    `minimax-baseline-08` for the Rust GUI prompt, with a 53 MB binary on
    disk; Run E `propuesta-minimax-T15` for the Firefox WebExtension
    prompt, with 22 OK / 0 FAIL validation).
3. **Verifiability:** the gtk4 0.10 winner from Run C has a
   working binary; the Tauri cluster (7 proposals) has none. The
   moa-from-vote vs moa-from-verification distinction (Run C §5.6)
   is the dominant factor in selecting a stack recommendation.
    Run D confirms: validator caught 2 of 6 real bugs. **Run E
    extends: validator caught 13 of 21 distinct defects**, including
    4 phantom npm packages, 2 wrong selectors, and 1 retracted
    API endpoint. **Run F adds ~7 defect categories in a lower-entropy
    CUDA domain and demonstrates byte-precise PTX validation**, while
    also showing why similar cohort size does not imply the same defect
    count. The validator is load-bearing at scale.
4. **Cohort uniformity enables controlled comparison:** Run D's
   6-baseline cohort produced comparable `sintesis_central`
   evidence not contaminated by cross-model signal. Run E's
   21-agent mixed cohort (20 MiniMax + 1 external) extends this
   to a 3.5× larger sample and a different prompt domain.
5. **Integration can lose — §6.2 counter-evidence (Run E):** the
   integrated proposal is not a guaranteed winner. When the
   integrator introduces critical-path defects, it can rank
   below the best original by 2.94 points. The "min viable
   integrator" mode (§7.5f) is a defect-prevention control that
   future runs should evaluate.

The remaining open questions — whether `sintesis_central` beats
`self_improve` on absolute quality (not just cost) when
controlling for model diversity, and whether the §6.2
counter-evidence is integrator-specific or systemic — require
direct side-by-side reruns with both `step_5_modo` values on
identical inputs (§7.5 for the 6-cohort version; §7.5d for the
21-cohort version). Run E confirms that `sintesis_central` does
not hang on a 21-agent cohort (the Run C hang was 5+ agentes,
intermittent, and may have been specific to that run's
configuration). Run E also surfaces a refined version of the
step-1 tool-call truncation bug (Run D §5.8.7 + §7.5a): the
truncation point depends on response length and affected only
`baseline-09` in the 21-cohort, suggesting the issue is
content-driven, not agent-driven.
(§7.5a). v1.2.1's `step_5_modo: skip` default remains in v1.3 as a
workaround for the larger-cohort `sintesis_central` hang until a
larger cohort confirms stability.

---

## 9. Run C–F reference (2026-07-13 to 2026-07-16)

This section is a quick-reference for Runs C–F; full data is in
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

### 9.3 Run E — 2026-07-15, v1.3

Full data: `docs/research/experiments/2026-07-15-moodle-quiz-extractor-v7.md`.

- **Bundle:** opencode-moa v1.3 (same as Run D).
- **ID:** `moodle-quiz-extractor` — **first non-Rust prompt domain**
  (Firefox WebExtension for Moodle quiz extraction, Spanish-language
  prompt).
- **Roster:** **21 agentes** (8 Group A baselines
  `propuesta-minimax-baseline-{01..09}` minus 1 aborted = 8 successful,
  6 Group B prompt injections {creative, minimal, security-first,
  observability, ci-github, cd-releases}, 6 Group C parameter sweeps
  {T05, T10, T15, P099, T05K50, T10K200}, 1 external
  `propuesta-deepseek-flash`). **Largest `sintesis_central +
  validacion_empirica` end-to-end cohort to date.**
- **Config:** `max_iteraciones: 10`, `umbral_convergencia: 0.2`
  (tighter than Run D's 0.5; not exercised in single iter),
  **`validacion_empirica: true`**, **`step_5_modo: sintesis_central`**,
  `sintesis_final: true`, `param_validation_report: true`,
  `step_1_concurrent_max: 3`, `step_1_agent_timeout_seconds: 0`
  (unlimited), `max_wall_clock_minutes: 0` (unlimited).
- **Outcome:** 20/21 originales written (`baseline-09` aborted after
  2 empty retries) + 1 integradora sintetizada. **Winner:
  `01-propuesta-minimax-T15.md`** (WXT 0.20.27 + Turndown 7.2.4 +
  DOMPurify 3.4.12 + Zod 4.4.3 + fflate 0.8.3 + jsdom 29.1.1;
  score 43/50, composite **8.99/10**, viabilidad **9.2/10**).
  **First time a Group C parameter-sweep agent (T=1.5) has led the
  ranking.** Margin over runner-up: **+0.05 points** over
  `01-propuesta-minimax-security-first.md` (44/50, 8.94/10).
  **Margin over the integrated proposal: -2.94 points** — the
  integrated proposal ranked 16/22 with composite 6.05/10, AP=1
  (4 critical-path defects). **1 DESCALIFICADA** (`T05K50` —
  invalid MV2 manifest with JSON comments + MV3-only
  `host_permissions` inside MV2). **1 sin validación** (`baseline-02`
  — validador aborted).
- **Wall-clock:** ~5.76 h (step 1 took 7 batches due to baseline-09
  truncation re-emit; see §5.9.7 and §7.5a).
- **Cost:** ~$0.20 estimated (49 MiniMax Token Plan invocations + 1
  external `propuesta-deepseek-flash` via opencode-go; byte-derived
  from Run C per-agent average, not measured via `model_remains`).
- **Honest limitations:** see bitácora §9 (single iter, Spanish
  prompt domain, no cross-model diversity in the 21-cohort — 20/21
  are MiniMax, byte-derived cost estimate, sintesis_central
  counter-evidence is one-shot, no iter-2 feedback-aware iteration,
  1 DESCALIFICADA at the evaluator level only, Group B coverage
  incomplete — 6 of 13 Group B variants exercised, `baseline-09`
  aborted after 2 empty retries).

### 9.4 Run F — 2026-07-16, v1.3

Full data: `docs/research/experiments/2026-07-16-voxora-kernels-v8.md`.

- **Bundle:** opencode-moa v1.3.
- **ID:** `voxora-kernels` — CUDA-kernel compatibility for Pascal `sm_61`, targeting the exact `candle-kernels 0.9.2` graph used by Voxora.
- **Roster:** **22 configured agents** (9 Group A baselines, 6 Group B prompt injections, 6 Group C sweeps, and 1 external `propuesta-deepseek-flash`). Five additional agents were excluded before configuration and produced no files.
- **Config:** `max_iteraciones: 10`, `umbral_convergencia: 0.2` (not exercised), `validacion_empirica: true`, `step_5_modo: sintesis_central`, `sintesis_final: true`, `param_validation_report: true`, `/orquestar` single iteration.
- **Outcome:** 22/22 originals plus one integrated candidate. Winner: `05-propuesta-integrada.md` with AP **9.4**, validator **9.7/10**, and 69/70 under a seven-section rubric. Runner-up: T15 with AP **9.2**, validator **9.5/10**, and 48/60 under six sections. The +21 total-point difference is not comparable because the integrated candidate received a synthetic seventh section.
- **Physical evidence:** `nvcc 12.9.86 -arch=sm_61 -ptx` reproduced a 282,810-byte patched PTX with 0 `atom.add.f16` and 8 `softmax_f16` matches in three validation paths. This is compile/PTX evidence, not end-to-end Qwen transcription evidence.
- **Convergence and defects:** 9 themes, maximum 17/22 on the in-tree patch approach, and approximately 7 defect categories. The lower defect count than Run E's 13 is interpreted as a prompt-complexity effect, not as a cohort-size law.
- **Honest limitations:** single iteration, byte-derived ~$0.20 cost and reconstructed ~78-minute wall-clock, validator webfetch timeout mitigated but not fixed, unresolved BF16 runtime policy, unexecuted G5 audio gate, and Maxwell deferred.

---

## Appendix A — Configuration used

[Full orquestador.json elided; identical to bitácora §1.]

---

## Appendix B — Winner paths

- **Run A (v0.2.0-beta, 2026-07-11):** `out/rust-gui-app/iter-1/05-mejorada-minimax.md`
- **Run B (v0.3, 2026-07-12):** `out/rust-gui-app-v3/iter-1/05-propuesta-integrada.md`
- **Run C (v1.2.1, 2026-07-13):** `out/rust-gui-popup-v5/iter-1/01-propuesta-minimax-baseline-08.md`
  (the 53 MB ELF binary it describes exists at
  `/tmp/opencode-moa-v5-test/rust-gui-popup/target/debug/rust-gui-popup`)
- **Run D (v1.3, 2026-07-13):** `out/fib-rust-cli/iter-1/05-propuesta-integrada.md`
  (the integrator's source tree is at
  `work/fib-rust-cli/iter-1/06-validacion-integrada/fib/`)
- **Run E (v1.3, 2026-07-15):** `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T15.md`
  (the winning original; the integrated proposal that lost is at
  `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/05-propuesta-integrada.md`)
- **Run F (v1.3, 2026-07-16):** `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/05-propuesta-integrada.md`
  (integrated candidate; validation at
  `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/06-validacion-integrada.md`;
  winner declaration at
  `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/08-ganador.md`)

Open any file in the bundle's corpus or render via any markdown viewer.
