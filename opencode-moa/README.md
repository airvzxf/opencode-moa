# opencode-moa (installable bundle)

This folder contains ONLY the files you need to install in your OpenCode configuration. Everything else in this repository (documentation, proposals, examples) stays in the repo for reference.

**Current bundle: v1.6 (2026-07-18) — 42 agents (6 OpenCode Go + 36 MiniMax Token Plan), 4 meta-agents + 2 commands. Breaking: directory layout restructured (`out/{id}/`, `work/{id}/`, `logs/{id}/` collapsed into `{id}/{subagent}/{proposal,work,log}/`). Inherits from v1.5: `step_1_concurrent_max` removed (steps 1/2/6 strictly serial).**

## What to copy

You need to copy these three things into your OpenCode config directory:

```
~/.config/opencode/
├── agents/             ← copy all *.md from this folder's agents/
├── commands/           ← copy all *.md from this folder's commands/
└── orquestador.json    ← copy from this folder's root
```

## Installation commands

### Linux / macOS (local)

```bash
# From the repo root:
cp opencode-moa/agents/*.md ~/.config/opencode/agents/
cp opencode-moa/commands/*.md ~/.config/opencode/commands/
cp opencode-moa/orquestador.json ~/.config/opencode/

# Verify:
ls ~/.config/opencode/agents/ | wc -l
# Should show: 46 files (42 proposal agents + 4 meta-agents)

ls ~/.config/opencode/commands/
# Should show: orquestar.md

cat ~/.config/opencode/orquestador.json | jq '.agentes_a_competir | length'
# Should show: 42 entries (the v1.3/v1.4 default roster — unchanged in v1.4)
```

### Linux / macOS (remote VPS via SSH)

```bash
# From your local machine:
ssh user@vps "mkdir -p ~/.config/opencode/agents ~/.config/opencode/commands"
scp opencode-moa/agents/*.md user@vps:~/.config/opencode/agents/
scp opencode-moa/commands/*.md user@vps:~/.config/opencode/commands/
scp opencode-moa/orquestador.json user@vps:~/.config/opencode/

# Verify on the VPS:
ssh user@vps "ls ~/.config/opencode/agents/ | wc -l && ls ~/.config/opencode/commands/"
```

### Windows (PowerShell)

```powershell
Copy-Item opencode-moa\agents\*.md $env:USERPROFILE\.config\opencode\agents\
Copy-Item opencode-moa\commands\*.md $env:USERPROFILE\.config\opencode\commands\
Copy-Item opencode-moa\orquestador.json $env:USERPROFILE\.config\opencode\
```

## What this installs (v1.3)

| File / group | Count | Purpose |
|---|---:|---|
| `agents/orquestador.md` | 1 | Primary agent. Coordinates 10 steps. |
| `agents/evaluador.md` | 1 | Subagent. Evaluates all proposals (single-model, temp 0.0). |
| `agents/sintetizador.md` | 1 | Subagent. Classifies + integrates + selects winners. |
| `agents/validador.md` | 1 | Subagent. Empirical validation, configurable via `validacion_empirica`. |
| `agents/propuesta-minimax.md` | 1 | Original MiniMax baseline agent. |
| `agents/propuesta-minimax-baseline-{01..15}.md` | 15 | Grupo A — baseline clones for intrinsic-variance measurement. |
| `agents/propuesta-minimax-{creative,...,cd-releases}.md` | 13 | Grupo B — priority-injection variants. |
| `agents/propuesta-minimax-T{05,07,10,15}.md` | 4 | Grupo C — temperature sweep. |
| `agents/propuesta-minimax-P099.md` | 1 | Grupo C — top_p sweep. |
| `agents/propuesta-minimax-T{05K50,10K200}.md` | 2 | Grupo C — temperature/top_k combinations. |
| `agents/propuesta-{kimi,deepseek,deepseek-flash,glm,mimo,qwen37-plus}.md` | 6 | OpenCode Go agents included in the v1.3 default roster. |
| `commands/orquestar.md` | 1 | Custom command: `/orquestar <prompt> <id>`. |
| `orquestador.json` | 1 | Config with `agentes_a_competir` (42 entries by default). |

## Project-level overrides (optional)

For per-project overrides, copy `orquestador.json` into the project root:

```bash
cd /path/to/your/project
cp /path/to/opencode-moa/orquestador.json ./
# Edit the file to override specific fields
```

Project-level overrides take precedence over user-level (see [docs/installation.md](../docs/installation.md) for details).

**Tip:** for the 2026-07-13 MiniMax sweep experiment, override at project
level to keep `agentes_a_competir` to a small subset (e.g. only 5 agents)
for cheaper runs. The default 42-agent roster is intended for research
runs and takes substantially longer than a small project-level override.

## Adding more agents (v1.3)

To add another agent (for example, a new variant):

1. Create `agents/propuesta-{name}.md` with the desired
   `model:`, `temperature:`, `top_p:`, `top_k:` fields in the
   frontmatter.
2. Add `"propuesta-{name}"` (without `.md`) to the `agentes_a_competir`
   array in `orquestador.json`.

Multiple agents can share the same `model:` field — they invoke
independently and rank independently.

## Mixing MiniMax + OpenCode Go

The v1.3 default roster already combines **36 MiniMax Token Plan agents
and 6 OpenCode Go agents**. Project-level overrides may select any subset
or add custom agents; multiple agents may share the same `model:` field.

The default roster is configured in `opencode-moa/orquestador.json`. Keep
that file and the agent table in `opencode-moa/AGENTS.md` synchronized when
changing the default roster.

## After installation

The full 42-agent roster is intended for research runs and can take
substantially longer than a small project-level override. Output
includes a `## Parameter validation report` section in
`04-clasificacion.md` showing which parameter-sweep agents produced
distinct outputs.

Or with a single-agent roster (faster, ~3 min):

```
cp opencode-moa/orquestador.json /tmp/my-project/
# Edit to set agentes_a_competir to just one agent
/orquestar "test" smoke
```

See [../docs/proposals/001-orquestador-nativo-opencode.md](../docs/proposals/001-orquestador-nativo-opencode.md) for the complete design document.