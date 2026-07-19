# opencode-moa

> A native OpenCode multi-agent orchestrator for competitive model evaluation and empirical validation — **without a single line of bash**.

[![OpenCode](https://img.shields.io/badge/OpenCode-native-blueviolet)](https://opencode.ai)
[![Mixture-of-Agents](https://img.shields.io/badge/inspired%20by-Mixture%20of%20Agents-orange)](https://arxiv.org/abs/2406.04692)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](#license)
[![Status](https://img.shields.io/badge/status-v1.6-yellow)]()

## What is opencode-moa?

`opencode-moa` is a multi-agent orchestration system built **entirely inside OpenCode** — no external scripts, no bash, no Python, no CLI shellouts. It coordinates multiple AI models in parallel to:

1. **Generate** competing proposals for the same prompt (multi-model)
2. **Validate** them empirically by executing their commands (bash + webfetch)
3. **Evaluate** them with objective criteria
4. **Classify** and rank them
5. **Improve** them using feedback

All coordination is done by an OpenCode primary agent (`orquestador`) that invokes subagents via OpenCode's native `task` tool. Everything is declarative markdown + JSON.

## Why?

The traditional multi-model orchestrators (AutoGen, CrewAI, LangGraph, custom bash scripts) require:

- Maintaining code in a non-declarative language
- Handling process management, retries, and concurrency manually
- External dependencies (Python, bash, npm packages)
- Complex deployment

`opencode-moa` reuses OpenCode's existing primitives — subagents, permissions, session logs, custom commands — to deliver the same functionality with **zero external code**.

## Quick start

### 1. Install (one-time)

From the repo root:

```bash
# Linux / macOS
cp opencode-moa/agents/*.md ~/.config/opencode/agents/
cp opencode-moa/commands/*.md ~/.config/opencode/commands/
cp opencode-moa/orquestador.json ~/.config/opencode/

# Or on a remote VPS via SSH
ssh user@vps "mkdir -p ~/.config/opencode/{agents,commands}"
scp opencode-moa/agents/*.md user@vps:~/.config/opencode/agents/
scp opencode-moa/commands/*.md user@vps:~/.config/opencode/commands/
scp opencode-moa/orquestador.json user@vps:~/.config/opencode/
```

See [`opencode-moa/README.md`](opencode-moa/README.md) for full installation instructions.

### 2. Run

From the OpenCode TUI:

```
/orquestar "Design a REST API for inventory management with JWT auth" auth-jwt
```

### 3. Inspect results

Each run produces **one root directory per id** with one folder per
subagent. Every subagent folder has the same `{proposal,work,log}/`
triplet:

```
auth-jwt/                                ← the run id (matches $ARGUMENTS $2)
├── orquestador/                         ← owns meta-step outputs (03-10)
│   ├── proposal/
│   │   ├── 03-calificacion-evaluador.md
│   │   ├── 04-clasificacion.md
│   │   ├── 05-propuesta-integrada.md
│   │   ├── 06-validacion-integrada.md
│   │   ├── 07-calificacion-final.md
│   │   ├── 08-ganador.md
│   │   ├── 09-sumario.md
│   │   └── 10-sintesis-cross-iter.md
│   ├── work/                            ← shared validador/sintetizador scratch
│   │   ├── 02-validacion-{agente}/
│   │   ├── 05-propuesta-integrada/
│   │   └── 06-validacion-integrada/
│   └── log/
│       ├── 02-validacion-{agente}.log
│       └── 05/06-*.log
└── {agente}/                            ← one folder per agent in agentes_a_competir
    ├── proposal/
    │   ├── 01-propuesta-{agente}.md
    │   └── 02-validacion-{agente}.md    ← only if validacion_empirica
    ├── work/01-{agente}/                ← subagent's empirical scratch
    └── log/01-{agente}.log              ← bash session log
```

The `{agente}/work/` and `{orquestador}/work/` directories are the
subagent's private scratch space — the orchestrator creates them
before invoking each agent and tells the agent to put ALL empirical
work there. No more scattered `/tmp/opencode-moa-{test}/{project}/`
directories. Naming rule: the `work/` subdir uses the same step-prefix
as the output file (without `.md`), so `01-propuesta-glm.md` ↔
`01-propuesta-glm/`. The validador's scratch lives under
`orquestador/` because the validador is a shared subagent owned by
the orquestador (it validates N candidates, not its own).

## Repository structure

```
opencode-moa/
├── README.md                              ← you are here
├── CHANGELOG.md                           ← version history
├── ROADMAP.md                             ← future plans
├── LICENSE                                ← Apache 2.0
├── docs/
│   ├── proposals/
│   │   └── 001-orquestador-nativo-opencode.md   ← complete design document
│   ├── research/
│   │   └── iterations-analysis.md         ← analysis of real-world multi-model iterations
│   └── installation.md                    ← detailed installation guide
├── examples/
│   └── auth-jwt-rest-api.md               ← full example
└── opencode-moa/                          ← INSTALLABLE BUNDLE (copy this to ~/.config/opencode/)
    ├── README.md                          ← installation instructions for this bundle
    ├── agents/
    │   ├── orquestador.md                 ← PRIMARY: coordinates the flow
    │   ├── propuesta-glm.md               ← generates proposals with GLM-5.1
    │   ├── propuesta-kimi.md              ← generates proposals with Kimi K2.6
     │   ├── propuesta-mimo.md              ← generates proposals with MiMo v2.5 Pro via OpenCode Go
    │   ├── propuesta-deepseek.md          ← generates proposals with DeepSeek V4 Pro
    │   ├── propuesta-minimax.md           ← generates proposals with MiniMax-M3 (your token plan)
    │   ├── evaluador.md                   ← evaluates all proposals
    │   ├── sintetizador.md                ← classifies and selects winners
    │   └── validador.md                   ← empirical validation (bash + webfetch)
    ├── commands/
    │   ├── orquestar.md                   ← /orquestar command
    │   └── orquestador.json                   ← configuration (list of models)
```

## Key features

### Multi-model competition (step 1)

The v1.8 bundle ships with a **55-agent default roster**: 6 OpenCode Go agents
and 49 MiniMax Token Plan agents (13 Grupo B prompt-injection variants + 36
Grupo C T-only sweep). The sweep (v1.7 → v1.8) dropped the redundant `top_p`
axis and tightened the temperature range to Anthropic spec (0.0–1.0 inclusive),
adding 12 clones at T=1.0 for intrinsic-variance signal at the high-entropy
edge. A project-level `orquestador.json` may select a smaller cohort or add
custom variants. Proposals are launched in strict serial order — one agent
per orchestrator response — and each selected agent writes its own report.

### Empirical validation (step 2)

A dedicated subagent (`validador`) executes the commands mentioned in each proposal and reports **per-section viability** (not just global). Bash permissions are scoped via OpenCode's permission system to prevent destructive operations.

### Single-model evaluation (step 3, 7)

A single evaluator (`evaluador`, using MiniMax-M3 with temperature 0.0) grades all proposals with objective criteria: Technical Quality, Completeness, Applicability, Security, Innovation. The evaluator adjusts the Applicability score based on the per-section viability report.

### Opt-in disqualification (step 4, 8)

By default, proposals with low viability stay in the ranking as ⚠️ warnings (with AP reduced). Set `descalificar_fallida: true` in `orquestador.json` to enable strict disqualification.

## Design decisions

### Why multi-model only for proposals?

Based on analysis of 5 real-world multi-model iterations (cardiorrenal, oc-rust-02, eval-7-ia-001, oc-software-development-agents/001 and /002):

- **Multi-model generation**: 100% valuable (different approaches enrich the pool)
- **Multi-model evaluation**: valuable in 33% of cases (close ties); redundant in 67% (clear consensus)
- **Multi-model validation**: irrelevant (bash output is binary)
- **Single-model synthesis**: critical (needs consistent criterion)

See [`docs/research/iterations-analysis.md`](docs/research/iterations-analysis.md) for the full analysis with citations.

### Why per-section viability?

Complex proposals have multiple technical sections (installation, API endpoints, code snippets, etc.). A single failure in one section doesn't justify disqualifying the entire proposal. The validator reports viability per section, and the evaluator adjusts scores proportionally.

### Why user-level + project-level config?

OpenCode natively merges configurations from multiple sources. This lets you:

- Install `opencode-moa` once in `~/.config/opencode/` (user-level, available everywhere)
- Override specific fields per-project (e.g., disable validation in production projects)

The merge is automatic and non-conflicting keys are preserved.

## Configuration

The `orquestador.json` file has 12 configurable fields plus `$schema`:

| Field | Type | Default | Description |
|---|---|---|---|
| `version` | string | required | Schema version |
| `agentes_a_competir` | array<string> | required | Agent IDs that generate proposals |
| `modelo_objetivo` | string | required | Target model for meta-agents |
| `validacion_empirica` | boolean | false | Enable validation steps 2 and 6 |
| `descalificar_fallida` | boolean | false | Enable strict disqualification |
| `step_1_agent_timeout_seconds` | integer | 0 | Per-agent timeout; 0 means unlimited |
| `step_5_modo` | string | `sintesis_central` | `sintesis_central`, `self_improve`, or `skip` |
| `multi_eval` | boolean | false | Enable multi-model evaluation |
| `multi_eval_modelos` | array<string> | `[]` | Evaluator models when enabled |
| `max_wall_clock_minutes` | integer | 0 | Global wall-clock cap; 0 means unlimited |
| `param_validation_report` | boolean | true | Aggregate declared sampling parameters |

See [`docs/proposals/001-orquestador-nativo-opencode.md`](docs/proposals/001-orquestador-nativo-opencode.md#7-orquestadorjson--esquema-completo) for the complete schema.

## Documentation

- 📋 [Complete design proposal](docs/proposals/001-orquestador-nativo-opencode.md) — 23 sections covering every detail
- 🔍 [Iterations analysis](docs/research/iterations-analysis.md) — empirical evidence backing the design decisions
- 🧪 [v5 experiment bitácora](docs/research/experiments/2026-07-13-rust-gui-popup-v5.md) — 52-agent iter-1 with measured cost + 53 MB winner binary
- 🧪 [v6 experiment bitácora](docs/research/experiments/2026-07-13-fib-rust-cli-v6.md) — 6-baseline minimum-cohort `sintesis_central` + `validacion_empirica` end-to-end with defect-detection evidence
- 🧪 [v7 experiment bitácora](docs/research/experiments/2026-07-15-moodle-quiz-extractor-v7.md) — 22 configured agents, 21 proposal outputs on Firefox WebExtension domain, T15 winner (first T-variant), first §6.2 counter-evidence
- 🧪 [v8 experiment bitácora](docs/research/experiments/2026-07-16-voxora-kernels-v8.md) — 22-agent configured CUDA-kernel compatibility cohort, source-attributed integration, byte-precise PTX validation
- 📄 [Paper draft (DRAFT v0.5)](docs/papers/DRAFT-multi-model-orchestration.md) — Run A–F synthesis with cost calibration, minimum-cohort evidence, Run E counter-evidence, and Run F CUDA-kernel results
- 📦 [Installation guide](docs/installation.md) — detailed install instructions for local, VPS, Docker, etc.
- 🧪 [Examples](examples/) — full REST API example with orchestrator workflow
- 📝 [Changelog](CHANGELOG.md) — version history, Run E, and Run F experiment records
- 🗺️ [Roadmap](ROADMAP.md) — future plans

## Background

This project is inspired by the paper **"Mixture-of-Agents"** (Together AI, 2024), which showed that layering multiple LLMs produces better responses than any individual model. While `opencode-moa` doesn't implement the full MoA paper (which uses iterative refinement through multiple model layers), it captures the spirit: multiple models contribute to a better final result.

It's also informed by 6+ months of real-world multi-model orchestration experiments documented in the research folder.

## Known limitations

### SDK temperature clamp (discovered 2026-07-18, fixed in v1.8 by design)

The `@ai-sdk/anthropic@3.0.82` SDK bundled in opencode 1.18.3 silently
clamps `temperature > 1.0` to `1.0` in its `getArgs()` method before the
HTTP request. For MiniMax-M3 (where `rejectsSamplingParameters=false`
because it is not a known Claude model), the "reject temperature" path
is skipped but the clamp at `temperature > 1` still executes.

This affects the **v1.7 sweep matrix only**; the v1.8 T-only sweep
avoids the issue entirely by keeping all values inside Anthropic spec:

| v1.8 agent cell | Frontmatter `temperature` | **What MiniMax receives** |
|---|---|---|
| `propuesta-minimax-T00-*` | 0.0 | 0.0 ✓ (deterministic-control) |
| `propuesta-minimax-T02-*` | 0.2 | 0.2 ✓ |
| `propuesta-minimax-T04-*` | 0.4 | 0.4 ✓ |
| `propuesta-minimax-T06-*` | 0.6 | 0.6 ✓ |
| `propuesta-minimax-T08-*` | 0.8 | 0.8 ✓ |
| `propuesta-minimax-T10-*` | 1.0 | 1.0 ✓ |

The v1.7 cells T15/T20 (the "out-of-Anthropic-spec" portion) were
empirically verified to clamp to 1.0 (see `CHANGELOG.md` v1.7.1 and
paper draft §5.11). The T15/T20 wins in v7/v8 bitácoras were sampling
variance at T=1.0, not a real effect of the higher temperature — which
is why v1.8 dropped those cells rather than reproducing them.

**Workaround if you need to test T>1.0 against MiniMax:** call the
endpoint directly with `curl`, `httpx`, `requests`, or any non-Anthropic
HTTP client. The Anthropic-compatible SDKs (`@ai-sdk/anthropic`,
`anthropic` Python SDK) all clamp at their respective versions.

## Contributing

This is currently a single-author project (Israel Roldan, [israel.alberto.rv@gmail.com](mailto:israel.alberto.rv@gmail.com)). Contributions welcome via issues and pull requests.

Areas where help is especially valued:
- Adding more `propuesta-{model}.md` variants for other AI providers
- Testing on additional real-world prompts
- Documentation translations (currently English only)
- Performance benchmarks

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Selected over AGPL v3.0 (the user's default) and MIT because:
- This is a tool/template, not a service — AGPL's network clause adds little value
- 100% markdown + JSON, not traditional source code
- Patent grant is useful when mixing multiple AI providers with different ToS
- Maximum adoption = more contributions and feedback

## Related projects

- [OpenCode](https://opencode.ai) — the AI coding agent this project extends
- [Mixture-of-Agents paper](https://arxiv.org/abs/2406.04692) — inspiration
- Original bash-based predecessor: see `docs/research/` for the history

---

**opencode-moa** — Multi-model orchestration, native OpenCode, zero bash.
