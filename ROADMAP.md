# Roadmap

This document outlines the planned evolution of `opencode-moa`. Items are organized by release horizon. Dates are approximate and subject to change based on user feedback.

## Current focus: v1.3 (2026-07-13, in local testing, not yet released)

### What v1.3 changed

Based on the 2026-07-13 v5 experiment
(`docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`), the
default roster was trimmed from 52 to 41 `agentes_a_competir`:

- **OpenCode Go:** 11 → 6 (dropped glm-52, kimi-k27-code, mimo-v25,
  qwen36-plus, qwen37-max — all fabricators or redundant)
- **MiniMax Token Plan:** 41 → 35 (dropped maintainable active file,
  performance-focused, T00/T03/T08, P01/P05/P09, all K*, redundant
  combos)
- **Added:** baselines 11-15 (variance expansion); 8 new Grupo B
  variants — a11y, errors, portable, i18n, rustdoc, observability,
  ci-github, cd-releases

**Measured outcome:** per-iter cost dropped from $4.60 to ~$2.24
(–51%), wall-clock from 200 min to ~156 min (–22%). All
unique-contribution agentes preserved, all fabricated-verification
agentes removed.

### v1.3.x additions shipped

- [x] **Per-subagent work directory convention** (`work/` + `logs/`
  first-class siblings of `out/`, created in step 0). Solves the
  "where do I put my scratch artifacts" problem that scattered
  `/tmp/opencode-moa-v5-test/rust-gui-popup/`, `iced-test/`,
  `gtk4-overlay-test/` etc. across the filesystem in the v5
  experiment. Each subagent now writes cargo scaffolds, downloaded
  deps, compiled binaries, and bash session logs into a deterministic
  location under `work/{id}/iter-{N}/{step-prefix}/` and
  `logs/{id}/iter-{N}/{step-prefix}.log`. Naming rule mirrors the
  output file prefix (e.g. `01-propuesta-minimax-baseline-04` →
  `01-propuesta-minimax-baseline-04/`). See `opencode-moa/AGENTS.md`
  §12 for the full table. `--force` cleans all three siblings for
  the iteration.
- [x] **Run D validated `sintesis_central` + `validacion_empirica: true` end-to-end** on a 6-baseline minimum cohort (fib-rust-cli, 2026-07-13). This is the first run with the full pipeline (steps 1–10) executing without synthetic substitutions. Key empirical confirmations:
  - **§6.2 evidence at last:** integrated proposal 45/50 beats best original 44/50 by +1 point on a uniform-model 6-baseline cohort. First methodologically clean §6.2 evidence.
  - **§6.3 with uniform model:** 6 identical-input proposals converged on 10 ideas (4-6 of 6 majority on each). Cross-pollination is a property of LLM sampling temperature, not a property of model diversity. Refines §6.3.
  - **Defect detection rate: 2 of 6 (33%)** caught real bugs (off-by-one boundary, panic-on-overflow). The validator is a load-bearing step, not a courtesy.
  - **Bitácora:** `docs/research/experiments/2026-07-13-fib-rust-cli-v6.md`. **Paper draft bumped to v0.3** with §5.8 (Run D results), §6.2.5 (cohorte uniforme §6.2 evidence), §6.3.3 (cross-pollination uniform model), §6.4 (Run D limitations), §7 items 5a/5b/5c, §8 conclusion extended, §9 split into §9.1 Run C + §9.2 Run D.

### Planned v1.3.x follow-ups

- [ ] **Wire `step_1_agent_timeout_seconds` to the actual `task()`
  call** — currently documented in `orquestador.md` but not enforced
  at the LLM call level. Hard 8-min cap per propuesta would reduce
  step-1 tail-latency (the slowest agent in each batch dominates).
  User feedback: "no hagas nada" for the rolling-batch optimisation,
  but per-agent timeout is a separate, lower-risk improvement.
- [ ] **SDK instrumentation for resolved sampling parameters** —
  current `## Generation parameters` audit is a self-declaration
  audit (0% of proposals have independently verified
  `temperature_actual`). v1.2.2 priority. See
  `DRAFT-multi-model-orchestration.md` §5.7.
- [ ] **Work dir size budget** — if a propuesta agent's `cargo
  build --release` produces >500 MB inside `work/`, the orchestrator
  should warn (currently no size cap; the v5 gtk4 winner was 53 MB
  which is fine, but a degenerate loop could fill the disk).
- [ ] **NEW: Investigate step-1 tool-call truncation (Run D §5.8.7).**
  When the step-1 prompt text exceeds a length threshold, the
  orquestador's response carrying multiple `task()` siblings in one
  response is truncated mid-emission (Run D observed with baseline-02
  and baseline-03 in the second batch of 3). Open questions: (a)
  what is the maximum prompt length before truncation? (b) Should
  `step_1_concurrent_max` be lowered to 2 for cohorts with long
  prompt templates? (c) Should the workdir/path block be DRY'd out of
  the step-1 prompt and into the agent's own prompt template? (d) Is
  this an opencode SDK 1.17.18 streaming-response bug or an LLM-side
  truncation? See `DRAFT-multi-model-orchestration.md` §7.5a.
- [ ] **NEW: Direct side-by-side §6.2 validation (Run D §7.5).**
  Repeat fib-rust-cli with `step_5_modo: self_improve` on the same
  6-baseline cohort. Goal: gold-standard §6.2 validation comparing
  `sintesis_central` vs `self_improve × 6` on identical inputs. Cost:
  ~2.5× Run D iter-1 (mostly the 6 self-improve calls).
- [ ] **NEW: Cross-domain Run D repeat (Run D §7.5b).** Pick a
  different prompt and run with the same 6-baseline cohort +
  `sintesis_central` + `validacion_empirica: true`. Goal: confirm
  Run D's findings (defect detection rate, +1 sintesis_central
  margin, within-cohort convergence) generalize beyond Fibonacci.

### What v1.3 changed

Based on the 2026-07-13 v5 experiment
(`docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`), the
default roster was trimmed from 52 to 41 `agentes_a_competir`:

- **OpenCode Go:** 11 → 6 (dropped glm-52, kimi-k27-code, mimo-v25,
  qwen36-plus, qwen37-max — all fabricators or redundant)
- **MiniMax Token Plan:** 41 → 35 (dropped maintainable active file,
  performance-focused, T00/T03/T08, P01/P05/P09, all K*, redundant
  combos)
- **Added:** baselines 11-15 (variance expansion); 8 new Grupo B
  variants — a11y, errors, portable, i18n, rustdoc, observability,
  ci-github, cd-releases

**Measured outcome:** per-iter cost dropped from $4.60 to ~$2.24
(–51%), wall-clock from 200 min to ~156 min (–22%). All
unique-contribution agentes preserved, all fabricated-verification
agentes removed.

### Planned v1.3.x follow-ups

- [ ] **Wire `step_1_agent_timeout_seconds` to the actual `task()`
  call** — currently documented in `orquestador.md` but not enforced
  at the LLM call level. Hard 8-min cap per propuesta would reduce
  step-1 tail-latency (the slowest agent in each batch dominates).
  User feedback: "no hagas nada" for the rolling-batch optimisation,
  but per-agent timeout is a separate, lower-risk improvement.
- [ ] **SDK instrumentation for resolved sampling parameters** —
  current `## Generation parameters` audit is a self-declaration
  audit (0% of proposals have independently verified
  `temperature_actual`). v1.2.2 priority. See
  `DRAFT-multi-model-orchestration.md` §5.7.

## v1.2.1 (2026-07-13, applied)

### Goals

- Stabilize the v0.2 beta API
- Gather user feedback from production usage
- Add features that reduce friction in common workflows

### Planned features

- [ ] **Auto-detection of propuesta-{model}.md files** — currently the orchestrator validates that each model in `modelos_a_competir` has a corresponding agent file. This validation is sufficient but could be more forgiving: if a user adds a new model without creating the agent, auto-generate a default agent with the right `model:` field.

- [ ] **Multi-eval opt-in** — currently the `evaluador` is a single agent. Some users (especially for high-stakes decisions) want multi-model evaluation. Plan: allow `evaluador-{model}.md` variants and a `multi_eval: true` flag in `orquestador.json`.

- [ ] **`idioma_output` config** — currently all file headers are in English. Add a config option to output headers in Spanish (or other languages) for users who prefer their native language.

- [ ] **Cost estimation** — OpenCode session logs include token counts. Add a post-iteration cost estimator that summarizes the per-model token usage and approximate cost (requires user-provided pricing data).

- [ ] **Git integration** — optional auto-commit of `out/{id}/iter-{N}/` after each iteration. Users can opt-in by adding `"git_autocommit": true` to `orquestador.json`. Useful for tracking iteration history.

- [ ] **Better error messages** — when a subagent fails, the error message should include enough context to debug (current model, current step, input file paths, etc.). Currently errors are minimal.

### Non-goals for v0.3

- UI / web dashboard for viewing iterations (deferred to v0.4+)
- Multi-machine resume (deferred to v0.5+)
- Model performance benchmarks (separate project)

## Medium term: v0.4-v0.5 (Q4 2026)

### v0.4 — UI and ergonomics

- [ ] **Web dashboard** — a simple HTML viewer for `out/{id}/iter-*/` that shows the flow visually (proposals → validations → evaluations → winner)
- [ ] **Interactive re-run** — pick a step from a previous iteration and re-run only that step with feedback
- [ ] **Diff view** — see what changed between iterations of the same `{id}`

### v0.5 — Distributed execution

- [ ] **Multi-machine resume** — `out/` syncing across machines (via git or cloud storage)
- [ ] **Cloud execution** — run heavy validations on a remote worker (e.g., a powerful VPS) while the orchestrator stays on the local machine
- [ ] **Cached evaluations** — if the same proposal was evaluated before, reuse the score

## Long term: v1.0+ (2027+)

### v1.0 — Production hardening

- [ ] **Sandbox enforcement** — run validators in Docker containers with restricted capabilities (the bash whitelist is good but not airtight)
- [ ] **Audit trail** — every decision by every agent is logged with full context for compliance
- [ ] **Replay mode** — given a previous run's metadata, replay the exact same execution (same model, same inputs, same order) for reproducibility
- [ ] **Plugin system** — let users extend with custom agents (e.g., a `legal-reviewer.md` that checks licensing implications)

### v2.0 — Full MoA implementation

- [ ] **Layered model evaluation** — implement the full Mixture-of-Agents paper: models propose, then models evaluate, then models refine the evaluations, etc. (vs current flat structure)
- [ ] **Cross-model attention** — feed proposals from one model as context for another model in the next layer
- [ ] **Configurable depth** — number of layers (currently fixed at 1)

## Research directions (long-term exploration)

These are ideas worth exploring but not committed:

- **Auto-tuning the convergence threshold** — currently `umbral_convergencia` is static. Could be auto-tuned based on score variance across iterations.
- **Prompt injection detection** — validate that user prompts don't contain malicious instructions targeting the agents.
- **Cross-language prompts** — automatically translate the user prompt to the language each model performs best in, then translate outputs back.
- **Federated evaluation** — distribute evaluation across multiple users to reduce individual bias (privacy-preserving).

## Out of scope (won't do)

- **Replace OpenCode with our own runtime** — `opencode-moa` is built on top of OpenCode and depends on its primitives. We won't fork or replace.
- **Support non-OpenCode orchestrators** — AutoGen, CrewAI, LangGraph are great projects but they have their own designs. `opencode-moa` is intentionally OpenCode-native.
- **Cloud-only hosted version** — this project is local-first. Users run it on their own machines. We won't offer a SaaS version.

## Contributing to the roadmap

Have an idea? Open an issue with the label `roadmap-proposal`. Include:

- The problem you're trying to solve
- Your proposed solution
- Why it fits `opencode-moa`'s design philosophy (native, declarative, zero bash)
- Any prior art or references

Maintainer will review and either accept (and add to roadmap), defer (with rationale), or close (with explanation).

---

Last updated: 2026-07-13 (v1.3 revision)
Maintainer: Israel Roldan [israel.alberto.rv@gmail.com](mailto:israel.alberto.rv@gmail.com)
