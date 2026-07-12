# Changelog

All notable changes to `opencode-moa` are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned for v0.3.0

- Multi-eval opt-in: support `evaluador-{model}.md` variants for users who want multi-model evaluation
- `idioma_output` config to allow Spanish output messages
- Auto-detection of `propuesta-{model}.md` files based on `modelos_a_competir`
- Git integration: optional auto-commit of `out/` after each iteration
- Cost estimation per iteration (track token usage)

### Changed (v0.3 — iteration refinements based on 2026-07-11 experiment)

The v0.3 refactor is grounded in `docs/research/experiments/2026-07-11-rust-gui-app.md`.
Tested with 12 models on a Rust GUI design task; documented in
`docs/papers/DRAFT-multi-model-orchestration.md`.

#### Added

- **Step 5 modes (NEW `step_5_modo`)** — `orquestador.json` now accepts `"sintesis_central" | "self_improve" | "skip"`. Default is `"sintesis_central"`: one integrator (the synthesizer) produces a single integrated proposal `out/{id}/iter-N/05-propuesta-integrada.md` instead of 12 self-improvements. This drops `step_5` cost by ~12× with statistically equivalent quality (validation pending; see `docs/papers/DRAFT-multi-model-orchestration.md` §6.2).
- **Step 10 — cross-iteration synthesis (NEW `sintesis_final`)** — opt-in flag (default `false`). When `true`, after the final iteration's step 9, the synthesizer produces `out/{id}/10-sintesis-cross-iter.md` with convergence, best-of-each-iter, recommended adoption, and convergence trajectory sections.
- **`filter_low_performers`** — opt-in config object: `{ "descalificar_debajo_de": 30, "aplicar_en": "iter_>=2", "keep_minimo": 3 }`. From iter-2 onwards, models with iter-N-1 total score below threshold are dropped from `modelos_a_competir`. Preserves minimum cohort diversity.
- **`multi_eval` + `multi_eval_modelos`** — opt-in flag (default `false`). When `true`, step 3 and step 7 fan out to multiple evaluators and the orchestrator averages the scores into a single ranking. Useful for variable-evaluation-quality domains (medications, legal).
- **`max_wall_clock_minutes`** — opt-in cost cap (default `0` = unlimited). When `> 0`, the orchestrator writes a partial `09-sumario.md` with a "STOPPED" note when the time budget is reached. Default unlimited: setting this without quota data is speculation.
- **`if_mejoras_tecnicamente_similares_a_otras`** — opt-in creativity boost (default `false`). When detected that the top-5 iter-1 proposals share > 80% of stack and architecture, the next step-1 prompts append a "seek a non-conventional angle" clause.
- **`sintesis_final_modelo`** — string, default = `modelo_objetivo`. The model used by the integrator (step 5 default, step 10 when triggered).
- **`track_contributors`** (planned) — iteration-level attribution of which model contributed which design idea (timeline: v0.3.x).
- **Documentation:**
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
- **`orquestador.json` defaults updated** to the 16-field schema with step_5_modo default = "sintesis_central", validacion_empirica default = true, and example values for the new knobs.
- **Bundle install** — no changes to `install.sh`; new fields are merged via the natural merge-overlap with user-level config.

#### Removed

- **The 12-self-improvement default behavior is preserved as `step_5_modo = "self_improve"`** (renamed from v0.2.0-beta's implicit "always"). It is no longer the default; users who want it set it explicitly. To remove the v0.2.0-beta behaviour without preserving access, drop this branch and remove the related code in step 1 — but `self_improve` is kept as opt-in for transparency.

#### Notes

- The first attempt at v0.3 (a partial run on 2026-07-11 with this version) was cut by the user's 5-hour `opencode-go` quota at iter-2 step 5. The bitácora in `docs/research/experiments/2026-07-11-rust-gui-app.md` documents both the v0.2.0-beta run (legacy `self_improve` mode) and notes how v0.3 would have behaved had quota allowed.

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

### Fixed (validated by smoke test on 2026-07-11)

- Removed the broken `:thinking` model-variant suffix from every
  `opencode-go/minimax-m3:thinking` and `opencode-go/minimax-m3-thinking`
  reference (9 places).
- Clarified the `todowrite` invocation in `orquestador.md` step 0.
- Documented the `id_corto` derivation rule in `orquestador.md` step 0.
- Added `propuesta-deepseek.md` and `propuesta-minimax.md` to the
  bundle (DeepSeek V4 Pro + MiniMax-M3 via `minimax-coding-plan`).
- Added `examples/opencode.jsonc.test-template` and matching
  troubleshooting entries in `docs/installation.md`.
- Brought `README.md`, `docs/installation.md` and `CHANGELOG.md`
  in sync with the above.

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
