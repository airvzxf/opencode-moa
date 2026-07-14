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
