# opencode-moa (installable bundle)

This folder contains ONLY the files you need to install in your OpenCode configuration. Everything else in this repository (documentation, proposals, examples) stays in the repo for reference.

**Current bundle: v1.8 (2026-07-18) — 55 agents (6 OpenCode Go + 13 Grupo B + 36 Grupo C T-only sweep), 4 meta-agents + 2 commands. Breaking: v1.7 T×P matrix (5 T × 3 P × 3 replicas = 45 agents) collapsed to T-only sweep (6 T × variable clones {3,3,6,6,6,12} = 36 agents); top_p dropped (short proposals saturate the nucleus), T range tightened to Anthropic spec (0.0–1.0 inclusive). Inherits v1.6 directory layout (`{id}/{subagent}/{proposal,work,log}/`).**

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
# Should show: 59 files (55 proposal agents + 4 meta-agents)

ls ~/.config/opencode/commands/
# Should show: orquestar.md

cat ~/.config/opencode/orquestador.json | jq '.agentes_a_competir | length'
# Should show: 55 entries (the v1.8 default roster)
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

## What this installs (v1.8)

| File / group | Count | Purpose |
|---|---:|---|
| `agents/orquestador.md` | 1 | Primary agent. Coordinates 10 steps. |
| `agents/evaluador.md` | 1 | Subagent. Evaluates all proposals (single-model, temp 0.0). |
| `agents/sintetizador.md` | 1 | Subagent. Classifies + integrates + selects winners. |
| `agents/validador.md` | 1 | Subagent. Empirical validation, configurable via `validacion_empirica`. |
| `agents/propuesta-minimax-{creative,...,cd-releases}.md` | 13 | Grupo B — priority-injection variants. |
| `agents/propuesta-minimax-T{T}-{01..NN}.md` | 36 | Grupo C — T-only sweep (6 T values × variable clone counts: T00×3, T02×3, T04×6, T06×6, T08×6, T10×12). Replaces the v1.7 T×P matrix (5 T × 3 P × 3 = 45). top_p fixed out of the prompt (short proposals saturate the nucleus). T range tightened to Anthropic spec (0.0–1.0 inclusive). Larger clone cohort at T=1.0 (12) for intrinsic-variance signal at the high-entropy edge. |
| `agents/propuesta-{kimi,deepseek,deepseek-flash,glm,mimo,qwen37-plus}.md` | 6 | OpenCode Go agents included in the v1.3+ default roster. |
| `commands/orquestar.md` | 1 | Custom command: `/orquestar <prompt> <id>`. |
| `orquestador.json` | 1 | Config with `agentes_a_competir` (55 entries by default). |

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
for cheaper runs. The default 55-agent roster is intended for research
runs and takes substantially longer than a small project-level override.

## Adding more agents (v1.8)

To add another agent (for example, a new variant):

1. Create `agents/propuesta-{name}.md` with the desired
   `model:`, `temperature:`, `top_p:`, `top_k:` fields in the
   frontmatter.
2. Add `"propuesta-{name}"` (without `.md`) to the `agentes_a_competir`
   array in `orquestador.json`.

Multiple agents can share the same `model:` field — they invoke
independently and rank independently.

## Mixing MiniMax + OpenCode Go

The v1.8 default roster already combines **49 MiniMax Token Plan agents
(13 Grupo B + 36 Grupo C T-only sweep) and 6 OpenCode Go agents**.
Project-level overrides may select any subset or add custom agents;
multiple agents may share the same `model:` field.

The default roster is configured in `opencode-moa/orquestador.json`. Keep
that file and the agent table in `opencode-moa/AGENTS.md` synchronized when
changing the default roster.

## After installation

The full 55-agent roster is intended for research runs and can take
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