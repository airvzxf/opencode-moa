# Changelog

All notable changes to `opencode-moa` are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Housekeeping

- Removed `opencode-moa/agents/orquestador.md.pre-fix3.bak` (25 KB / 615
  lines). The pre-fix3 backup of `orquestador.md` (now 863 lines) was a
  v0.3 snapshot no longer referenced by any code, config, or bitácora;
  its history is preserved in git (`48c57d5`, PR #7).

### Run F — 2026-07-16 voxora-kernels v1.3 (22-agent CUDA kernel compatibility cohort)

- **ID:** `voxora-kernels` — first CUDA-kernel / GPU-binary compatibility
  prompt domain, targeting Pascal `sm_61` and the exact
  `candle-kernels 0.9.2` graph used by Voxora.
- **Configured cohort:** 22 agents (9 Group A baselines, 6 Group B prompt
  injections, 6 Group C sweeps, and 1 external `propuesta-deepseek-flash`).
  Five additional proposer agents were excluded by user instruction before
  configuration and produced no files; they were not part of this roster.
- **Config:** `validacion_empirica: true`, `step_5_modo: sintesis_central`,
  `sintesis_final: true`, `param_validation_report: true`, one `/orquestar`
  iteration. The convergence threshold was not exercised.
- **Outcome:** 22/22 originals plus one integrated candidate. Winner:
  `05-propuesta-integrada.md` (AP **9.4**, validator **9.7/10**, 69/70 over
  seven sections); runner-up T15 (AP **9.2**, validator **9.5/10**, 48/60
  over six sections). The comparable margin is **+0.2 AP**; the apparent
  +21 total-point difference is not comparable because the integrated
  candidate received a synthetic seventh section.
- **Physical evidence:** three validation paths reproduced a patched
  `sm_61` PTX target of 282,810 bytes with 0 `atom.add.f16` and 8
  `softmax_f16` matches under `nvcc 12.9.86`. This is compile/PTX evidence,
  not proof of end-to-end Qwen transcription.
- **Findings:** 9 convergent themes with a maximum of 17/22 on the in-tree
  patch approach; approximately 7 defect categories; unresolved BF16
  runtime policy; Maxwell deferred; validator webfetch timeout mitigated by
  local-only validation but not fixed at SDK/provider level.
- **Documentation:** full bitácora in
  `docs/research/experiments/2026-07-16-voxora-kernels-v8.md`; paper draft
  bumped to **v0.5** with §5.10, §6.2.7, §6.3.5, Run F limitations,
  future-work items 5j–5o, §8, and §9.4.

### Run E — 2026-07-15 moodle-quiz-extractor v1.3 (21-agent Firefox WebExtension cohort)

- **ID:** `moodle-quiz-extractor` — **first non-Rust prompt domain**
  (Firefox WebExtension for Moodle quiz extraction, Spanish-language
  prompt).
- **Roster:** **21 agentes** (8 Group A baselines
  `propuesta-minimax-baseline-{01..09}` minus 1 aborted = 8 successful,
  6 Group B prompt injections {creative, minimal, security-first,
  observability, ci-github, cd-releases}, 6 Group C parameter sweeps
  {T05, T10, T15, P099, T05K50, T10K200}, 1 external
  `propuesta-deepseek-flash`). **Largest `sintesis_central +
  validacion_empirica` end-to-end cohort to date** (Run C had 52
  agentes but `validacion_empirica: false` and `step_5_modo: skip`).
- **Config:** `validacion_empirica: true`, `step_5_modo: sintesis_central`,
  `sintesis_final: true`, `umbral_convergencia: 0.2` (tighter than Run
  D's 0.5; not exercised in single iter), `max_iteraciones: 10`,
  `max_wall_clock_minutes: 0` (unlimited), `param_validation_report:
  true`, single iter (`/orquestar`).
- **Outcome:** 20/21 originales written (`baseline-09` aborted after
  2 empty retries) + 1 integradora sintetizada. **Winner:
  `propuesta-minimax-T15`** (Group C, T=1.5 sweep; WXT 0.20.27 +
  Turndown 7.2.4 + DOMPurify 3.4.12 + Zod 4.4.3 + fflate 0.8.3 + jsdom
  29.1.1; score 43/50, composite **8.99/10**, viabilidad **9.2/10**).
  **First time a Group C parameter-sweep agent has led an
  opencode-moa ranking.** Top-3: T15 (8.99) > security-first (8.94)
  > T05 (8.75). Margin over runner-up: **+0.05 points** over
  `propuesta-minimax-security-first`. **Margin over the integrated
  proposal: -2.94 points** — the integrated proposal ranked 16/22
  with composite 6.05/10, AP=1 (4 critical-path defects). 1
  **DESCALIFICADA** (`T05K50` — invalid MV2 manifest with JSON
  comments + MV3-only `host_permissions` inside MV2). 1 **sin
  validación** (`baseline-02` — validador aborted; conservatively
  scored AP=5, Viability=5).
- **Wall-clock:** ~5.76 h (50 sub-agent invocations).
- **Cost:** ~$0.20 estimated (49 MiniMax Token Plan + 1 external
  `propuesta-deepseek-flash` via opencode-go; byte-derived from Run
  C per-agent average, not measured via `model_remains`).
- **Key findings:**
  - **§6.3 cross-pollination scales to 21-cohort and to a
    non-trivial prompt domain.** 9 convergent themes (3+ of 21
    agreement each), with WXT+MV3 floor at 12/21 — the strongest
    convergence in the corpus to date. **Cross-pollination scales
    with prompt complexity (number of orthogonal decision axes),
    not just with cohort size.** For a prompt with N
    requirements, a cohort of ~3N agents is likely sufficient to
    surface the convergent defaults.
  - **§6.2 counter-evidence (first in opencode-moa).** The
    integrated proposal **lost** to the best original by 2.94
    points (6.05/10 vs 8.99/10). The integrator introduced 4
    critical-path defects that the originals did not have: (a)
    broken `packTar` import (`new Pack()` vs lowercase `pack()`),
    (b) asset path contradiction (`./assets/` vs `./quiz/...`),
    (c) `pnpm audit --prod --audit-level high` endpoint retired
    (HTTP 410), (d) `packageManager: "pnpm@10.x"` non-exact
    (Corepack rejects). Plus 3 secondary defects. The §6.2
    proposition is refined to "integration is typically
    higher-scoring, except when the integrator introduces
    critical-path defects." A "min viable integrator" mode is
    proposed in v1.3.x §7.5f follow-ups.
  - **First T-variant to win the ranking.** T15 (T=1.5) wins
    with composite 8.99. Validates the v1.3 roster decision to
    keep T15 (and drop T00/T03/T08) — the Group C parameter-sweep
    agents are competitive with Group A baselines.
  - **Defect detection scales roughly linearly with cohort size.**
    Run D: 2 of 6 (33%) at 6-cohort. Run E: 13 of 21 (62%) at
    21-cohort. ~13 distinct defects: 4 phantom npm packages
    (`@wext/manifest`, `tarballjs`, `@webassembly-feature/web-ext`,
    `@grafana/otel-cli-ls`), 2 wrong selectors (`_choice` vs
    `_answer`), 1 Chrome-Apps-only API (`chrome.sockets.tcpServer`),
    1 retracted endpoint (`pnpm audit --prod`), 1 invalid
    `packageManager`, 1 wrong `strict_min_version`, 1 invalid
    32-char OTLP `spanId`, 1 invalid manifest JSON (`//`
    comments), 1 fabricated cmid, 1 fabricated Q2 example
    content, 1 unpublishable manifest (`ADDON_ID_REQUIRED`).
    The validator is **load-bearing for the cohort's overall
    trustworthiness**, not a courtesy.
  - **`sintesis_central` did not hang on the 21-agent cohort**
    (despite Run C's earlier 5-agent hang). The hang is likely
    specific to step-5 subagent context size, not to the
    step-1 batch size.
  - **Step-1 tool-call truncation observed only for `baseline-09`**
    (the 3rd `task()` call in the first batch of 3 truncated).
    Mitigation: re-issued as a dedicated 1-agent batch. The
    truncation point depends on response length, not on agent
    identity (Run D §5.8.7 hypothesis confirmed).
- **Reference:** `docs/research/experiments/2026-07-15-moodle-quiz-extractor-v7.md`
  (full bitácora with setup, roster, wall-clock timeline, outputs,
  cost, outcome, convergent themes, defect catalog, limitations,
  next experiments). Paper draft bumped to **v0.4** with §5.9 (Run E
  results, 7 subsections), §6.2.6 (counter-evidence), §6.3.4
  (21-cohort cross-pollination), §6.4 (Run E limitations), §7
  items 5d/5e/5f (cross-domain repeat, T=1.5 gateway clamp, min
  viable integrator), §8 extended (5-run synthesis), §9.3 Run E
  reference.

### Added (per-subagent work directory convention)

Three first-class sibling directories are now created by the orchestrator
in step 0 for every iteration:

- `out/{id}/iter-{N}/` — existing, reports (.md) only.
- `work/{id}/iter-{N}/{step-prefix}/` — NEW, empirical scratch space for
  each subagent (cargo scaffolds, downloaded dependencies, compiled
  binaries, intermediate files).
- `logs/{id}/iter-{N}/{step-prefix}.log` — NEW first-class, bash session
  log captured for each subagent invocation.

Naming rule: the work subdirectory uses the same prefix as the output
file (without `.md`). Example for `id = fib-rust-cli`, `iter-1`,
`agent = propuesta-minimax-baseline-04`:

- Proposal:   `out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04.md`
- Work dir:   `work/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04/`
- Log file:   `logs/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04.log`

Same pattern across all 10 steps (see `opencode-moa/AGENTS.md` §12 for
the full table). Step 9 (summary) is written by the orchestrator
directly and uses neither work dir nor log file.

### Changed

- Each `task()` prompt emitted by the orchestrator now includes the
  subagent's absolute work directory and log path in a
  `=== WORK DIRECTORY ===` block. The subagent is explicitly told to
  use it exclusively for empirical artifacts and NEVER use `/tmp`,
  the workspace root, or any path under `out/{id}/iter-{N}/` for those.
- All 42 `propuesta-*.md` agents received a "## Work directory"
  section right before `# Role` (after the ROLE OVERRIDE block in the
  Grupo B variants, so the override directive still wins).
- `validador.md`, `evaluador.md`, and `sintetizador.md` received
  role-specific "## Work directory" sections with the exact paths
  for each of their modes (steps 2/6, 3/7, 4/5/8/10 respectively).
- `--force` flag now removes ALL THREE sibling directories for that
  iteration (`out/`, `work/`, `logs/`) before recreating them, so
  re-running a failed iteration starts from a clean slate.
- `orquestador.md` gained a "Per-subagent work directory" section
  under Fundamental rules with the full naming table and the rule
  that step 0 must create all three.

### Notes

- Backward compatible: existing runs in `out/` are untouched. The
  convention applies to runs started after this change. Older runs
  that scattered artifacts in `/tmp/opencode-moa-v5-test/{project}/`
  etc. are left as-is — they remain as historical evidence in
  `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`.

### Changed

- Removed all line-count quotas from proposal agents, the evaluator, the validator, the synthesizer, and the orchestrator prompts. Output length now follows the scope and completeness requirements of each task instead of fixed minimums or maximums.
- Replaced line-count-based resumability checks in the design specification with content-based validation of required sections and substantive Markdown output.
- Removed proposal-level tool-call budgets, predicted build-duration gates, dependency-count cutoffs, and score-based roster filtering. Proposers may use the research and validation work their scope requires while every configured agent remains available in later iterations.
- `step_1_concurrent_max` now drives the actual batch size. Each response must emit exactly `min(batch_size, remaining_agents)` sibling `task()` calls, restoring parallel execution within batches while numbered steps remain sequential.
- Removed the invalid jq model lookup and silent MiniMax fallback; each task now uses the validated `agente_modelos` map from step 0 and aborts when an agent lacks a model.
- Restored `max_wall_clock_minutes: 0` as the unlimited default. Positive values remain available as an explicit opt-in global cutoff.
- Strengthened the orchestrator's step-1 parallelism contract. The response that contains sibling `task()` calls must be 100% tool calls — zero prose, zero planning, zero status log lines — and all planning must live in the prior response. The "STRICTLY SEQUENTIAL" wording that biased the LLM toward serialization is replaced with a data-dependency model: steps form a DAG by file outputs, not by ordinal number. Orchestrator `temperature` lowered from 0.2 to 0.0 to reduce spontaneous prose that previously truncated batch 0 of step 1 mid-emission. Validated against a 42-agent run on 2026-07-13 (opencode 1.17.20): batches 1..13 now emit 3 sibling `task()` calls per response with identical creation timestamps in the opencode session DB.

### Changed (v1.3 — 2026-07-13, in local testing, not yet released)

**Roster trimmed from 52 to 41 agentes_a_competir based on empirical cost + quality data from the 2026-07-13 v5 experiment.** See `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md` §4.1, §8 for the analysis that drove this change.

**OpenCode Go: 11 → 6 agents.** Dropped:
- `propuesta-glm-52` — score 25/50, fabricated `rustc 1.92` claim; cost $1.19 (worst ROI at $0.0475/score-pt)
- `propuesta-kimi-k27-code` — score 34/50, FLTK stack redundant with `propuesta-glm`; cost $0.42
- `propuesta-mimo-v25` — score 34/50, eframe 0.30 stack redundant with the eframe 0.33 cluster; cost $0.02
- `propuesta-qwen36-plus` — score 31/50, hallucinated `rustc 1.92` claim; cost $0.14 (false economy)
- `propuesta-qwen37-max` — score 28/50, Tauri proposal with no on-disk artifact; cost $0.54

Kept: `propuesta-kimi`, `propuesta-deepseek`, `propuesta-deepseek-flash`, `propuesta-glm`, `propuesta-mimo`, `propuesta-qwen37-plus`. These preserve stack diversity (gtk4 0.10, gtk4 0.9, eframe 0.33, FLTK, iced, GTK3) and the cheapest legitimate performer (`qwen37-plus` at $0.08).

**MiniMax Token Plan: 41 → 35 agents.** Dropped:
- `propuesta-minimax-maintainable` (active file) — replaced by `propuesta-minimax-testable` in v1.2.1; active file removed, historical backup kept as `propuesta-minimax-maintainable.md.v1.2-preserved`
- `propuesta-minimax-performance-focused` (Grupo B) — score 25/50, no unique contribution
- `propuesta-minimax-T00`, `T03`, `T08` (temperature) — T00/T03 chose incompatible toolchains; T08 single-window egui::Window violates "encima de todo"
- `propuesta-minimax-P01`, `P05`, `P09` (top_p) — P01/P05 + Tauri no-artifact; P09 redundant
- All 4 `propuesta-minimax-K*` (top_k) — no unique winning contribution; clamp-discovery lives in `T10K200` combo
- `propuesta-minimax-T00P01`, `T03P05`, `T07P09`, `T10P099`, `T00K01`, `T00P01K01`, `T07P09K100`, `T10P099K200` (combos) — redundant or incompatible

Kept: `propuesta-minimax`, 10 baselines, 4 Grupo B (creative, security-first, minimal, testable), 4 temperature (T05, T07, T10, T15), 1 top_p (P099), 2 combos (T05K50, T10K200).

### Added (v1.3)

**15 baselines (was 10).** Added `propuesta-minimax-baseline-11` … `-15`. Per the v5 bitácora §4 the 10-baseline cohort already produced 10 substantively different proposals (intrinsic variance is the value of the baseline cohort); expanding to 15 strengthens the statistical base for picking the strongest "consensus-recipe" baseline without bias toward whichever baseline happened to win this run.

**8 new Grupo B prompt-injection variants** (was 4, now 12). All use the v1.3 `⚠️ ROLE OVERRIDE` directive prepended at the top of the agent file:

- `propuesta-minimax-a11y` — accessibility-first (AT-SPI/UI Automation/NSAccessibility, WCAG 2.2 AA, keyboard navigation, screen-reader contracts)
- `propuesta-minimax-errors` — error-handling-first (`Result<T,E>` + `thiserror`, `#![deny(clippy::unwrap_used)]`, error-path unit tests)
- `propuesta-minimax-portable` — cross-platform portability-first (Linux/macOS/Windows matrix, `#[cfg(target_os)]` discipline, CI matrix)
- `propuesta-minimax-i18n` — internationalization-first (Fluent/gettext catalogs, ICU4X formatters, RTL locale support)
- `propuesta-minimax-rustdoc` — documentation-completeness-first (`#![deny(missing_docs)]`, doctests on every public fn, `cargo doc --no-deps`)
- `propuesta-minimax-observability` — structured-tracing-first (`tracing` not `println!`, JSON logs, `metrics` + Prometheus exporter)
- `propuesta-minimax-ci-github` — CI-first (GitHub Actions matrix on stable+MSRV+nightly × Linux+macOS+Windows, `cargo deny`, `cargo audit`, `cargo llvm-cov`)
- `propuesta-minimax-cd-releases` — distribution-first (`cargo-dist`, AppImage/.deb/.rpm/.dmg/.msi, cosign signing, SBOM, `release-plz`)

Together with the 4 existing Grupo B (creative, security-first, minimal, testable), the v1.3 Grupo B roster covers 12 orthogonal quality axes: creativity, security, simplicity, testability, accessibility, error handling, portability, i18n, documentation, observability, CI, CD.

### Changed (v1.3 cost/quality)

- **Estimated per-iter cost: $4.60 → $2.24** (–51%) based on §4.1 empirical OCG telemetry + MiniMax quota telemetry.
- **Estimated per-iter wall-clock: 200 min → 156 min** (–22%) at `step_1_concurrent_max: 3`.
- **All agents with fabricated verifications are removed** (v1.2.1 carried `propuesta-glm-52`, `propuesta-qwen36-plus`, and 4 MiniMax `gtk4 0.11` agentes with `rustc 1.92` hallucinations; all gone in v1.3).
- **Stack coverage preserved:** GTK4 (0.10 + 0.9 + layer-shell in 2 of the 12 Grupo B), egui 0.33, FLTK, iced, GTK3, Slint all still represented.

### Added (v1.3.1 addendum, 2026-07-13 — same day)

**`propuesta-minimax-maintainable` restored from `.v1.2-preserved` backup to active status.** Group B roster now has 13 variants (was 12 in v1.3 initial). The restored file applies the v1.2.1 `⚠️ ROLE OVERRIDE` directive prepended at the top — same format as the 4 original Grupo B variants (creative, security-first, minimal, testable) and the 8 new v1.3 variants.

**Rationale:** the v1.2.1 patch (2026-07-13) had renamed `propuesta-minimax-maintainable` → `propuesta-minimax-testable` because the `maintainable` proposal was structurally similar to baselines (style-focused, not test-focused). v1.2.1 created `testable` as a new agent, which is correct. However, **removing `maintainable` entirely was an over-correction** — the two lenses are orthogonal:

- `testable` covers test coverage: every public interface has a concrete test inline, test framework stated, runner invocation documented, expected output asserted.
- `maintainable` covers code readability: docstrings on every public fn with usage examples, boring documented libraries preferred, explicit-over-clever, English identifiers, design rationale inline.

Both lenses independently produce useful variants and the within-cohort signal is stronger with both than with either alone. **Restored `maintainable` brings Grupo B count from 12 to 13.** Updated `agentes_a_competir` from 41 to 42 entries (6 OCG + 36 MiniMax). Estimated per-iter cost delta: +$0.02 (one extra propuesta subagent; OCG unchanged, MiniMax cost was already ~$0.16 with the 35-agent cohort).

**File changes:**
- `opencode-moa/agents/propuesta-minimax-maintainable.md.v1.2-preserved` → `propuesta-minimax-maintainable.md` (both bundle and user-level)
- `~/.config/opencode/orquestador.json` and `opencode-moa/orquestador.json`: added `propuesta-minimax-maintainable` to `agentes_a_competir` (right after `propuesta-minimax-testable`)
- `opencode-moa/agents/orquestador.md` default roster section updated
- `opencode-moa/AGENTS.md` §1 + §11 updated (roster count 41 → 42; Grupo B count 12 → 13; new row in §11 variants table)

### Changed (v1.3 schema)

- `~/.config/opencode/orquestador.json` `$schema` updated to `v1.3.json`, `version` field to `1.3`. Schema fields unchanged from v1.2.1; the change is the roster content + new agent files.
- `max_wall_clock_minutes` remains at 180 (carried from v1.2.1's bump; appropriate for the trimmed 41-agent roster).

### Run D — 2026-07-13 fib-rust-cli v1.3 (6-baseline `sintesis_central` validation)

**First documented run with the full pipeline (steps 1–10) executing end-to-end without synthetic substitutions.** Run B had `sintesis_central` + `validacion_empirica: true` but was blocked at step 2 by the `bash: ask` permission hang (steps 3/4/6/7/8 were filled in synthetically). Run C had `validacion_empirica: false` (v1.2.1 default) and `step_5_modo: skip`. Run D completes the picture on a different prompt domain (Rust Fibonacci CLI vs Rust GUI).

- **ID:** `fib-rust-cli`
- **Roster:** 6 baselines only (`propuesta-minimax-baseline-{01..06}`), overriding the v1.3.1 42-agent default. All 6 bind to `model: minimax-coding-plan/MiniMax-M3` with provider default temperature. No Grupo B, no parameter sweep, no OpenCode Go cross-model — minimum controlled cohort for variance measurement.
- **Config:** `validacion_empirica: true`, `step_5_modo: sintesis_central`, `sintesis_final: true`, `param_validation_report: true`, `step_1_concurrent_max: 3`, `step_1_agent_timeout_seconds: 600`, `max_wall_clock_minutes: 0`.
- **Outcome:** 6/6 originales written + 1 integradora sintetizada. **Winner: `05-propuesta-integrada.md`** (45/50, viabilidad 9.8/10). Margin over runner-up: **+1 point** over `01-propuesta-minimax-baseline-06.md` (44/50, 10/10). 0 descalificadas, 2 marcadas ⚠️ VIABLE CON ADVERTENCIAS (baseline-04 off-by-one boundary bug, baseline-05 panic-on-overflow + missing source).
- **Wall-clock:** ~78 min (step 1 took 4 batches due to tool-call truncation re-emit; see below).
- **Cost:** ~$0.07 estimated (all MiniMax Token Plan; byte-derived from Run C per-agent average, not measured via `model_remains`).

**Key findings:**

1. **§6.2 evidence at last:** integrated proposal (45/50) beats best original (44/50) by +1 point on a uniform-model 6-baseline cohort with full empirical validation of both candidates. **First methodologically clean §6.2 evidence.** The integrator's value is consolidation + defect detection, not model-diversity signal.
2. **§6.3 evidence with uniform model:** 6 identical-input proposals converged on 10 ideas (4-6 of 6 majority on each). **Cross-pollination is a property of LLM sampling temperature, not a property of model diversity.** This refines §6.3 and informs the v1.3 baseline-cohort expansion rationale.
3. **Defect detection rate:** 2 of 6 (33%) had real bugs the individual proposals did not self-correct (off-by-one boundary, panic-on-overflow). Plus 1 of 6 had a structural Completeness defect (omitted `src/main.rs`). The validator is a load-bearing step.

**Bugs / observations to track:**

- **NEW: step-1 tool-call truncation.** When the step-1 prompt text exceeds a length threshold, the orquestador's response carrying multiple `task()` siblings in one response is **truncated mid-emission** (observed with baseline-02 and baseline-03 in the second batch of 3). Mitigation in Run D: re-issue in a smaller batch. Open questions for v1.3.x follow-up: max prompt length before truncation, impact of `step_1_concurrent_max: 2` for long-prompt cohorts, DRY opportunity for the workdir/path block.
- **`sintesis_central` did NOT hang on 6-agent cohort** (vs Run C's hang with 5+ agentes). Suggests the hang is intermittent or cohort-size-dependent. v1.3 default remains `step_5_modo: skip` until a larger cohort confirms stability.
- **Per-subagent work/log dirs validated end-to-end.** The v1.3 `work/{id}/iter-1/{step-prefix}/` + `logs/{id}/iter-1/{step-prefix}.log` convention worked as designed: each of the 6 propuesta agents + 6 validador agents + 1 integradora validator had their own scratch subdir, and the integrator's source tree at `work/fib-rust-cli/iter-1/06-validacion-integrada/fib/` is the byte-exact reproduction of the proposed `src/main.rs`.

**Reference:** `docs/research/experiments/2026-07-13-fib-rust-cli-v6.md` (full bitácora: setup, roster, wall-clock timeline, outputs, cost, outcome, variance analysis, within-cohort convergence, defect detection, sintesis_central validation, tool-call truncation, limitations, next experiments).

**Paper draft updated:** `docs/papers/DRAFT-multi-model-orchestration.md` bumped to v0.3 with Run D added as §5.8 (results), §6.2.5 (cohorte uniforme §6.2 evidence), §6.3.3 (cross-pollination uniform model), §6.4 (Run D limitations), §7 future work items 5a/5b/5c (tool-call truncation, cross-domain repeat, bigger uniform cohort), §8 conclusion extended, §9 split into §9.1 Run C reference and §9.2 Run D reference.

### Planned for v0.3.0 (carry-over)

- Multi-eval opt-in: support `evaluador-{model}.md` variants for users who want multi-model evaluation
- `idioma_output` config to allow Spanish output messages
- Auto-detection of `propuesta-{model}.md` files based on `agentes_a_competir`
- Git integration: optional auto-commit of `out/` after each iteration
- Cost estimation per iteration (track token usage)

### Reference

- `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md` — full bitácora of the experiment that drove v1.3 (52-agent run, $4.60 cost, 200 min wall-clock, gtk4 0.10 winner)
- `docs/papers/DRAFT-multi-model-orchestration.md` — paper draft updated with v5 / v1.3 findings (§X "MoA cost-side empirical calibration")

### Changed (v1.2 — 2026-07-13, in local testing, not yet released)

**Schema migration v1.1 → v1.2: `agentes_a_competir` replaces
`modelos_a_competir`.** Breaking change.

The roster is now an array of agent filenames (e.g.
`"propuesta-minimax-T15"`, `"propuesta-minimax-baseline-01"`) instead
of model strings. The orchestrator reads each agent's `model:` field
from its own frontmatter. This decouples agent identity from model
identity, enabling multi-variant experiments of the same model.

**40 MiniMax M3 agents added** (the v1.2 default roster):

| Group | # agents | Naming |
|---|---:|---|
| Original | 1 | `propuesta-minimax` (untouched) |
| A — Baselines | 10 | `propuesta-minimax-baseline-{01..10}` (clones for variance measurement) |
| B — Prompt injection | 5 | `propuesta-minimax-{creative,security-first,performance-focused,minimal,maintainable}` |
| C — Temperature sweep | 7 | `propuesta-minimax-T{00,03,05,07,08,10,15}` |
| C — top_p sweep | 4 | `propuesta-minimax-P{01,05,09,099}` |
| C — top_k sweep | 4 | `propuesta-minimax-K{01,05,50,200}` |
| C — temp×top_p combos | 4 | `propuesta-minimax-T{00P01,03P05,07P09,10P099}` |
| C — temp×top_k combos | 3 | `propuesta-minimax-T{00K01,05K50,10K200}` |
| C — Triples | 3 | `propuesta-minimax-T{00P01K01,07P09K100,10P099K200}` |
| **Total** | **40** | |

All 40 agents bind to `model: minimax-coding-plan/MiniMax-M3`. The
parameter-sweep agents (Group C) use Anthropic-compatible parameters
(`temperature`, `top_p`, `top_k`) which OpenCode passes through to
the provider per its "Additional" agent-config option.

**Concurrency protection (`step_1_concurrent_max`, default 3).** Step
1 of the orchestrator now launches propuesta subagents in batches of
3 instead of all-at-once. With 40 agents in the roster, step 1 spans
14 batches of ~90s each = ~21 min wall time. Peak concurrent MiniMax
agents never exceeds `step_1_concurrent_max + 1` (the +1 accounts for
the evaluador/sintetizador spawned in subsequent steps). This protects
the user's Max-tier Token Plan budget (4-5 concurrent agents sustained).

**Per-agent timeout (`step_1_agent_timeout_seconds`, default 600).**
Hard cap of 10 min per propuesta subagent. Subagents exceeding the
timeout are ABORTED and the batch continues with whatever proposals
did complete.

**Parameter validation report (`param_validation_report`, default true).**
v1.2 introduces a triple-validation strategy for parameter-sweep
agents:

1. Each Grupo C agent appends a `## Generation parameters` section
   to its output proposal, reporting declared vs observed parameters.
2. The sintetizador (step 4) aggregates per-proposal reports into a
   table in `04-clasificacion.md` (section `## Parameter validation
   report`).
3. The round-1 smoke test
   (`/orquestar --smoke-test=true "List the 7 colors of the rainbow"`
   on `id=arco-iris-40`) measures whether MiniMax actually honors
   `temperature=0.0` (greedy → identical proposals) vs
   `temperature=1.5` (extreme → divergent proposals).

**Default `validacion_empirica` flipped from `true` to `false`.** With
40 agentes_a_competir, step 2 (validador) would spawn 40 parallel
empirical-validation subagents. Per the 2026-07-12 bitácora, the
validador subagent hangs on `bash: ask` permissions (opencode upstream
bug #35073, fix PR #35823 not yet released). Empirical validation
remains opt-in via project-level `orquestador.json` override.

**Default `max_wall_clock_minutes` set to 90** (was 0 = unlimited).
Worst-case scenario for a 40-agent iter is ~21 min for step 1 +
~10-15 min for steps 3-9 = ~35 min. 90 min provides ample headroom.

### Planned for v0.3.0 (carry-over)

- Multi-eval opt-in: support `evaluador-{model}.md` variants for users who want multi-model evaluation
- `idioma_output` config to allow Spanish output messages
- Auto-detection of `propuesta-{model}.md` files based on `agentes_a_competir`
- Git integration: optional auto-commit of `out/` after each iteration
- Cost estimation per iteration (track token usage)

### Fixed (validated by 2026-07-12 v0.3 rerun — PR #4)

**The `propuesta-mimo.md` model-binding conflict (HIGH severity).**
Between v0.2.0-beta and v0.3 (PR #1, commit `75307fd`), the
`opencode-moa/agents/propuesta-mimo.md` frontmatter was changed from
`model: opencode-go/mimo-v2.5-pro` to `model: opencode-go/minimax-m3`.
The new `propuesta-minimax.md` agent was created for the user's plan
model `minimax-coding-plan/MiniMax-M3`, but `propuesta-mimo.md` was
incorrectly re-bound to the OpenCode-hosted MiniMax (the model the
user explicitly excluded from proposers with "nunca se va a ejecutar
MiniMax de OpenCode").

Symptoms observed on 2026-07-12:
- 42 requests to `opencode-go/minimax-m3` ($0.10 spent) by orphan
  subagent processes spawned during iter-1
- 11 legitimate iter-2 propuesta subprocesses were killed when we
  terminated all `opencode run` processes to stop the orphan
- See `opencode-moa/AGENTS.md` §2 for full post-mortem

**Fix:** restored `propuesta-mimo.md` to `model: opencode-go/mimo-v2.5-pro`
(matches the v0.2.0-beta mapping documented in bitácora §2).

**Documented OpenCode upstream bug** [#35073](https://github.com/anomalyco/opencode/issues/35073)
("subagent permission asks hang indefinitely") in `docs/installation.md`
with two workarounds: (a) user-level `bash: allow` config; (b) bypass
step 2/3 by invoking step 5 directly via build agent. Affects all
users running the full orchestrator pipeline in headless mode until
PR #35823 is released. Caused the 2026-07-12 iter-1 to block at step 2
(validador) and forced steps 3/4/6/7 to be filled in synthetically.

### Changed (validated by 2026-07-12 v0.3 rerun — PR #4)

**Default `modelos_a_competir` reduced from 11 to 8** based on
cost/ROI analysis of the v0.2.0-beta iter-1+2 data plus the 2026-07-12
v0.3 rerun telemetry. Dropped:

- `opencode-go/qwen3.7-max` — worst $/req ($0.056), mid-tier output
- `opencode-go/deepseek-v4-pro` — regressed 24→24 in iter-2
- `opencode-go/qwen3.6-plus` — regressed 27→27 in iter-2
- `opencode-go/mimo-v2.5-pro` — persistent low performer

The 8-model default roster and per-model rationale is documented in
`opencode-moa/AGENTS.md` §1.

**`modelo_objetivo` default changed** from `opencode-go/minimax-m3`
to `minimax-coding-plan/MiniMax-M3` (the user's plan model). Matches
the v0.2.0-bitácora §1 baseline (`"modelo_objetivo":
"minimax-coding-plan/MiniMax-M3"`). The orchestrator itself now runs
on the user's plan model instead of the OpenCode-hosted MiniMax.

### Added (validated by 2026-07-12 v0.3 rerun — PR #4)

- `opencode-moa/AGENTS.md` — operations & post-mortems file documenting
  the model roster, the `propuesta-mimo.md` binding conflict, the
  OpenCode permission workaround, and orphan-process handling.
- `docs/research/experiments/2026-07-12-rust-gui-app-v3.md` — bitácora
  of the v0.3 rerun (sintesis_central validation, §6.2 partial
  validation, §6.3 cross-pollination extension, 8-model cost table).
- `docs/papers/DRAFT-multi-model-orchestration.md` — §5.4 NEW,
  §6.2 expanded to 4 subsections (original hypothesis + empirical
  evidence + refined proposition + iter-2 feedback-aware evidence),
  §6.3 expanded with iter-1 convergence data, §7 future work
  updated, §8 conclusion extended.

### Fixed (validated by 2026-07-12 v0.3 rerun)

- Documented OpenCode upstream bug
  [#35073](https://github.com/anomalyco/opencode/issues/35073)
  ("subagent permission asks hang indefinitely") in
  `docs/installation.md` with two workarounds: (a) user-level
  `bash: allow` config; (b) bypass step 2/3 by invoking step 5 directly
  via build agent. Affects all users running the full orchestrator
  pipeline in headless mode until PR #35823 is released.
- This bug caused the 2026-07-12 iter-1 to block at step 2 (validador)
  and forced steps 3/4/6/7 to be filled in synthetically. Recovery via
  direct invocation of step 5 (build agent + `--model minimax-coding-plan/MiniMax-M3`)
  produced `05-propuesta-integrada.md` successfully.

### Fixed (validated by smoke test on 2026-07-11)

This block collects the make-it-installable fixes that came out of the
first end-to-end smoke test on 2026-07-11 (commit `26a4dfa`,
cherry-picked onto `feat/iter-design-refinements`).

- Removed the broken `:thinking` model-variant suffix from every
  `opencode-go/minimax-m3:thinking` and `opencode-go/minimax-m3-thinking`
  reference (9 places: `orquestador.json` ×2, `orquestador.md`,
  `evaluador.md`, `sintetizador.md`, `validador.md`,
  `propuesta-mimo.md`, `commands/orquestar.md`,
  `commands/orquestar-iterate.md`). The suffix does not exist in any
  provider's model list; thinking control belongs to the OpenCode
  `--variant` flag or the model's own `thinking` parameter, not the
  model name.
- Clarified the `todowrite` invocation in `orquestador.md` step 0 —
  the previous markdown told the orchestrator to call `todowrite` with
  a bare array of strings, which the tool rejects. Replaced with the
  proper `{content, status, priority}` schema.
- Documented the `id_corto` derivation rule in `orquestador.md` step 0
  so the orchestrator no longer has to infer it on each invocation.

### Added (validated by smoke test on 2026-07-11)

Same provenance as the `### Fixed` block above — these additions also
landed on 2026-07-11 and are part of the cherry-pick from `26a4dfa`.

- New agent `propuesta-deepseek.md` (DeepSeek V4 Pro via `opencode-go`).
- New agent `propuesta-minimax.md` (MiniMax-M3 via the MiniMax Token
  Plan / `minimax-coding-plan` provider).
- `examples/opencode.jsonc.test-template` — ready-to-copy project-level
  permission overrides for non-interactive headless smoke tests.
- New troubleshooting entries in `docs/installation.md`: external-directory
  hangs in headless mode, and the `opencode run --command` `UnknownError`
  workaround.

### Changed (v0.3 — iteration refinements based on 2026-07-11 experiment)

The v0.3 refactor is grounded in `docs/research/experiments/2026-07-11-rust-gui-app.md`.
Tested with 12 models on a Rust GUI design task; documented in
`docs/papers/DRAFT-multi-model-orchestration.md`. The eight new
orchestrator fields below are all opt-in with defaults that preserve
v0.2.0-beta behaviour for users who don't set them — the bundle is
backward-compatible.

#### Added (v0.3 fields — separate from above)

- **`step_5_modo`** — `orquestador.json` now accepts `"sintesis_central" | "self_improve" | "skip"`. Default is `"sintesis_central"`: one integrator (the synthesizer) produces a single integrated proposal `out/{id}/iter-N/05-propuesta-integrada.md` instead of 12 self-improvements. This drops `step_5` cost by ~12× with statistically equivalent quality (validation pending; see `docs/papers/DRAFT-multi-model-orchestration.md` §6.2).
- **`sintesis_final`** — opt-in flag (default `false`). When `true`, after the final iteration's step 9, the synthesizer produces `out/{id}/10-sintesis-cross-iter.md` with convergence, best-of-each-iter, recommended adoption, and convergence trajectory sections.
- **`sintesis_final_modelo`** — string, default = `modelo_objetivo`. The model used by the integrator (step 5 default, step 10 when triggered).
- **`multi_eval` + `multi_eval_modelos`** — opt-in flag (default `false`). When `true`, step 3 and step 7 fan out to multiple evaluators and the orchestrator averages the scores into a single ranking. Useful for variable-evaluation-quality domains (medications, legal).
- **`max_wall_clock_minutes`** — opt-in cost cap (default `0` = unlimited). When `> 0`, the orchestrator writes a partial `09-sumario.md` with a "STOPPED" note when the time budget is reached. Default unlimited: setting this without quota data is speculation.
- **`filter_low_performers`** — opt-in config object: `{ "descalificar_debajo_de": 30, "aplicar_en": "iter_>=2", "keep_minimo": 3 }`. From iter-2 onwards, models with iter-N-1 total score below threshold are dropped from `modelos_a_competir`. Preserves minimum cohort diversity.
- **`if_mejoras_tecnicamente_similares_a_otras`** — opt-in creativity boost (default `false`). When detected that the top-5 iter-1 proposals share > 80% of stack and architecture, the next step-1 prompts append a "seek a non-conventional angle" clause.
- **`track_contributors`** (planned) — iteration-level attribution of which model contributed which design idea (timeline: v0.3.x).
- **Documentation in this repository:**
  - `docs/research/experiments/README.md` — index for the experiment log.
  - `docs/research/experiments/2026-07-11-rust-gui-app.md` — full bitácora of the first multi-model run (cost table, cross-pollination, ROI ranking, limitations, next experiments).
  - `docs/papers/DRAFT-multi-model-orchestration.md` — first paper draft.
  - `docs/papers/BIBLIOGRAPHY.md` — references.

#### Changed

- **`validacion_empirica` default → `true`** (was implicitly false in v0.2.0-beta by the test setup). Empirical testing is encouraged and the validador gets more useful work. The step-1 subagent constraint in `orquestador.md` was relaxed: bounded `cargo build` is now allowed (under 5 minutes, <200 deps); only `cargo tauri build` and GUI-interaction tools remain disallowed.
- **Step 1 prompt template (in `orquestador.md`)** — added `=== FEEDBACK-AWARE ITERATION ===` block so iter-N subagents read iter-N-1's `03-evaluacion` + `04-clasificacion` + `05-integrada` (when applicable) BEFORE writing the new proposal. This is what drove the +7 to +14 lift from iter-1 to iter-2 in the 2026-07-11 experiment.
- **`orquestador.md` step 0** — added explicit listing of all 16 v1.1 fields with their defaults, including the eight new ones. Added `filter_low_performers.aplicar_en` enforcement (drops models on iter-N with score < threshold). Added `max_wall_clock_minutes` enforcement (writes partial sumario and stops).
- **`sintetizador.md`** — extended with three new modes beyond classification and final selection:
  - **integrated synthesis** (step 5, `sintesis_central` mode) — produces `05-propuesta-integrada.md` with convergence-detection, source attribution, and "Why this beats the field" sections.
  - **cross-iteration synthesis** (step 10, optional) — produces `10-sintesis-cross-iter.md` summarising all iterations.
  - **final selection** updated to handle the integrated candidate alongside the 12 originals.
- **`orquestador.json` defaults updated** to the 16-field schema with `step_5_modo` default = `"sintesis_central"`, `validacion_empirica` default = `true`, and example values for the new knobs.
- **Bundle install** — no changes to `install.sh`; new fields are merged via the natural merge-overlap with user-level config.

#### Removed

- **The 12-self-improvement default behavior is preserved as `step_5_modo = "self_improve"`** (renamed from v0.2.0-beta's implicit "always"). It is no longer the default; users who want it set it explicitly. To remove the v0.2.0-beta behaviour without preserving access, drop this branch and remove the related code in step 1 — but `self_improve` is kept as opt-in for transparency.

#### Notes

- The first attempt at v0.3 (a partial run on 2026-07-11 with this version) was cut by the user's 5-hour `opencode-go` quota at iter-2 step 5. The bitácora in `docs/research/experiments/2026-07-11-rust-gui-app.md` documents both the v0.2.0-beta run (legacy `self_improve` mode) and notes how v0.3 would have behaved had quota allowed.
- The v0.3 changes were validated by cherry-picking the v0.2.0-beta shippable-install fix (`26a4dfa`) onto `feat/iter-design-refinements`, producing a single coherent commit history that backs the next release.

## [0.2.0-beta] - 2026-07-10

### Added

- **User-level + project-level configuration merge** — install once in `~/.config/opencode/`, override per-project
- **Per-section viability validation** — validator reports viability per section, not just global; evaluator adjusts AP proportionally
- **Opt-in disqualification** — `descalificar_fallida` defaults to `false`; proposals with low viability stay in ranking as ⚠️ warnings (with AP reduced)
- **4-layer smoke test control** — runtime argument > project JSON > user JSON > default fallback
- **`smoke_test: "auto"` heuristic** — orchestrator decides based on prompt length and complexity
- **35 repo name proposals** — finalized as `opencode-moa`
- **23-section design proposal** at `docs/proposals/001-orquestador-nativo-opencode.md`
- **Iterations analysis** at `docs/research/iterations-analysis.md` — empirical evidence from 5 real-world multi-model projects
- **Cleaner step numbering** — 0-9 (no decimals), with explicit step 0 = initialization
- **Bundle subfolder** — `opencode-moa/` directory inside repo contains only files to copy; avoids copying README/LICENSE/.github

### Changed

- All file headers and content in **English** (research-grade, GitHub-ready)
- `orquestador.json` schema extended with new fields (versioned as v1.0)
- `validacion_empirica` defaults to `true` (was implicit before)
- Documentation restructured: docs/proposals/, docs/research/, docs/installation.md

## [0.1.0-alpha] - 2026-07-10

### Added

- Initial design proposal `001-orquestador-nativo-opencode.md` (17 sections)
- Concept of orchestrator as primary agent + 4 specialized subagents + 3 propuesta variants
- `orquestador.json` schema v0.1 with 8 fields
- Steps 3, 3.5, 4, 5, 6, 6.5, 7, 8 (decimal numbering from bash-based predecessor)
- Decision matrix: multi-model for proposals, single-model for evaluador/validador/sintetizador

---

## Pre-history: Bash-based predecessors

These are NOT part of `opencode-moa` itself, but inform its design.

### 2026-05 to 2026-07: 002/001-007 series

A series of 7 proposals (`001-glm-5.1.md` through `007-glm-5.1.md`) for a bash-based multi-model orchestrator. The series grew to 2058 lines of bash plus 12 helper scripts. After 6 months of iteration, it became clear that the bash approach had fundamental limitations:

- Concurrency management was fragile
- Permission whitelisting for the validator was verbose (100+ glob rules)
- Configuration via bash variables was hard to validate
- Resumability required complex state files

These limitations motivated the v0.1.0-alpha native-agent design.

## How to read this changelog

- **Added** = new feature.
- **Changed** = behaviour change of existing feature (note backwards-compat implications).
- **Deprecated** = feature that will be removed in a future release.
- **Removed** = feature removed in this release.
- **Fixed** = bug fix.
- **Security** = vulnerability fix (this project has had none).

See `opencode-moa/ROADMAP.md` for planned v0.3.x and v0.4 features.
