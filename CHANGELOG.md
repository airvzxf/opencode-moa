# Changelog

All notable changes to `opencode-moa` are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned for v0.3.0

- Multi-eval opt-in: support `evaluador-{model}.md` variants for users who want multi-model evaluation
- `idioma_output` config to allow Spanish output messages
- Auto-detection of `propuesta-{model}.md` files based on `modelos_a_competir`
- Git integration: optional auto-commit of `out/` after each iteration
- Cost estimation per iteration (track token usage)

## [0.2.0-beta] - 2026-07-10

### Added

- **User-level + project-level configuration merge** — install once in `~/.config/opencode/`, override per-project
- **Per-section viability validation** — validator reports viability per section, not just global; evaluator adjusts AP proportionally
- **Opt-in disqualification** — `descalificar_fallida` defaults to `false`; proposals with low viability stay in ranking as ⚠️ warnings
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
- Adding new models required bash code changes

The lessons learned from this series directly inform `opencode-moa`'s design:
- Use OpenCode's native primitives instead of bash
- Prefer declarative markdown configuration over imperative scripts
- Leverage OpenCode's permission system instead of custom whitelists
- Keep the validator's permissions minimal (only what's needed for bash validation)

### Real-world iteration projects (2025-08 to 2026-06)

Five real multi-model orchestration projects were completed using the bash-based predecessor. Their data informs the design:

| Project | Domain | Models used | Iterations |
|---|---|---|---|
| cardiorrenal | medical supplements | 9 | 4 |
| eval-7-ia-001 | self-evaluation | 6 | 2 |
| oc-rust-02 | Rust on OpenCode | 8 | 1 |
| oc-software-development-agents/001 | orchestrator design | 2 | 4 |
| oc-software-development-agents/002 | orchestrator design | 3 | 7 |

Full analysis in [`docs/research/iterations-analysis.md`](docs/research/iterations-analysis.md).

---

## Versioning policy

- **Major version** (X.0.0): breaking changes to the agent interfaces, command syntax, or orquestador.json schema
- **Minor version** (0.X.0): new features, new agents, new fields in orquestador.json (backward compatible)
- **Patch version** (0.0.X): bug fixes, documentation improvements, no interface changes

The `version` field in `orquestador.json` tracks the schema version, not the software version. Schema changes follow their own versioning: v1.0, v1.1, v2.0, etc.

---

## How to update

When a new version is released:

```bash
cd /path/to/opencode-moa
git pull
# Re-copy the bundle (overwrites existing files in ~/.config/opencode/)
cp opencode-moa/agents/*.md ~/.config/opencode/agents/
cp opencode-moa/commands/*.md ~/.config/opencode/commands/
cp opencode-moa/orquestador.json ~/.config/opencode/
```

Existing project-level overrides are preserved (project JSON files are not touched by this update).