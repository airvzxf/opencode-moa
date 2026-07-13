# Changelog

All notable changes to `opencode-moa` are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
