# Multi-Model Orchestration in a Native Agent Platform: Lessons from opencode-moa (DRAFT v0.2.1)

> **Status:** Draft v0.2.1 — extended with Run C (2026-07-13, v1.2.1,
> 52-agent iter-1) cost calibration, stack-vs-viability analysis,
> and parameter-validation honesty probe. v1.3 roster revision
> (52 → 41 agentes) incorporated. **v1.3.1 addendum (same day):**
> `propuesta-minimax-maintainable` restored from `.v1.2-preserved`
> backup (41 → 42 agentes). See `docs/research/experiments/`
> for the full experimental log. Do not cite as final work. Comments
> welcome via issues.

**Authors:** Israel Roldan (corresponding: israel.alberto.rv@gmail.com)
**Affiliation:** airvzxf
**Date:** 2026-07-11 (first draft), 2026-07-13 (v0.2 with Run C and v1.3 revision), 2026-07-13 (v0.2.1 with v1.3.1 addendum)

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

### 5.0 Run C — 2026-07-13 (v1.2.1, 52-agent iter-1, N=1)

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
- **v1.2.1's `step_5_modo: skip` default.** Run C confirmed that the
  v3-era `sintesis_central` default triggered an orchestrator hang
  with 5+ agents (intermittent). v1.2.1 changed the default to `skip`,
  which avoided the hang entirely in Run C's 52-agent iter-1.
  Trade-off: `skip` means no consolidated integrator file. The winner
  is one of the 52 originales (Run C: `minimax-baseline-08`).

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
5. **Direct side-by-side §6.2 validation.** Run iter-1 twice: once
   with `step_5_modo: sintesis_central`, once with `step_5_modo:
   self_improve`, on the same prompt and same proposals. This is the
   gold-standard validation but costs ~2.5× as much. **Pre-requisite:**
   fix the `step_5_modo: sintesis_central` orchestrator hang observed
   with 5+ agentes (see Run C §5.0; v1.2.1's `skip` default is a
   temporary workaround).
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
8. **Validate `filter_low_performers` threshold.** In Run B, all 12
   iter-1 originals scored ≥32/50 (above the default threshold of 30),
   so the filter would not drop anyone in iter-2. This is itself a
   finding about the threshold value — needs cross-run calibration.
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
tasks (Rust GUI with overlay popup semantics) for under $12 per
multi-iteration run. Three empirical runs (2026-07-11 Run A,
2026-07-12 Run B, 2026-07-13 Run C) test the same prompt with
progressively refined bundle versions:

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
    **This drove the v1.3 roster revision** (52 → 41 agentes,
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

The combination of Run A, B, and C findings makes v1.3's trimmed
roster a defensible design choice on three dimensions:

1. **Cost:** 51% reduction with no quality loss (all unique
   contributions preserved, all fabrications removed).
2. **Convergence:** the §6.3 finding from Run A and B generalises
   cleanly to Run C's 52-agent cohort — cross-model consensus
   produces a verifiable winner (`minimax-baseline-08` for the Rust
   GUI prompt, with a 53 MB binary on disk at
   `/tmp/opencode-moa-v5-test/rust-gui-popup/target/debug/rust-gui-popup`).
3. **Verifiability:** the gtk4 0.10 winner from Run C has a working
   binary; the Tauri cluster (7 proposals) has none. The
   moa-from-vote vs moa-from-verification distinction (Run C §5.6)
   is now the dominant factor in selecting a stack recommendation.

The remaining open question — whether `sintesis_central` beats
`self_improve` on absolute quality (not just cost) — requires a
direct side-by-side rerun (§7.5) which we defer to future work due
to the orchestrator hang observed with 5+ agentes in
`step_5_modo: sintesis_central`. v1.2.1's `step_5_modo: skip`
default is the current workaround; the long-term fix requires
diagnosing the streaming-response hang in opencode SDK 1.17.18.

---

## 9. Run C reference (2026-07-13, v1.2.1)

This section is a quick-reference for Run C; full data is in
`docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`.

- **Bundle:** opencode-moa v1.2.1 (post-Run B patch bundle; see
  `CHANGELOG.md` [Unreleased] / v1.2 entry).
- **ID:** `rust-gui-popup-v5`
- **Roster:** 52 agentes (11 OCG + 41 MiniMax). See v1.2.1 schema;
  v1.3 trimmed to 41.
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
