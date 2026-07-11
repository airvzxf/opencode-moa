# opencode-moa (installable bundle)

This folder contains ONLY the files you need to install in your OpenCode configuration. Everything else in this repository (documentation, proposals, examples) stays in the repo for reference.

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
ls ~/.config/opencode/agents/
# Should show: orquestador.md, propuesta-glm.md, propuesta-kimi.md,
#              propuesta-mimo.md, evaluador.md, sintetizador.md, validador.md

ls ~/.config/opencode/commands/
# Should show: orquestar.md, orquestar-iterate.md

cat ~/.config/opencode/orquestador.json
# Should show the JSON config
```

### Linux / macOS (remote VPS via SSH)

```bash
# From your local machine:
ssh user@vps "mkdir -p ~/.config/opencode/agents ~/.config/opencode/commands"
scp opencode-moa/agents/*.md user@vps:~/.config/opencode/agents/
scp opencode-moa/commands/*.md user@vps:~/.config/opencode/commands/
scp opencode-moa/orquestador.json user@vps:~/.config/opencode/

# Verify on the VPS:
ssh user@vps "ls ~/.config/opencode/agents/ && ls ~/.config/opencode/commands/"
```

### Windows (PowerShell)

```powershell
Copy-Item opencode-moa\agents\*.md $env:USERPROFILE\.config\opencode\agents\
Copy-Item opencode-moa\commands\*.md $env:USERPROFILE\.config\opencode\commands\
Copy-Item opencode-moa\orquestador.json $env:USERPROFILE\.config\opencode\
```

## What this installs

| File | Type | Purpose |
|---|---|---|
| `agents/orquestador.md` | primary agent | Coordinates all 10 steps + iterate mode |
| `agents/propuesta-glm.md` | subagent | Generates proposals using GLM-5.1 |
| `agents/propuesta-kimi.md` | subagent | Generates proposals using Kimi K2.6 |
| `agents/propuesta-mimo.md` | subagent | Generates proposals using MiniMax-M3-thinking |
| `agents/evaluador.md` | subagent | Evaluates all proposals (single-model) |
| `agents/sintetizador.md` | subagent | Classifies and selects winners (single-model) |
| `agents/validador.md` | subagent | Empirical validation with bash + webfetch |
| `commands/orquestar.md` | custom command | `/orquestar <prompt> <id>` |
| `commands/orquestar-iterate.md` | custom command | `/orquestar-iterate <prompt> <id>` |
| `orquestador.json` | config | List of competing models + iterate settings |

## Project-level overrides (optional)

For per-project overrides, copy `orquestador.json` into the project root:

```bash
cd /path/to/your/project
cp /path/to/opencode-moa/orquestador.json ./
# Edit the file to override specific fields
```

Project-level overrides take precedence over user-level (see [docs/installation.md](../docs/installation.md) for details).

## Adding more competing models

To add a fourth model to the competition (e.g. `opencode-go/opus-5`):

1. Create a new file `agents/propuesta-opus.md` with the same content as `propuesta-glm.md` but with `model: opencode-go/opus-5` in the frontmatter.
2. Add `"opencode-go/opus-5"` to the `modelos_a_competir` array in `orquestador.json`.

The orchestrator will validate that the corresponding `propuesta-{id}.md` exists for each model.

## After installation

Try the smoke test:

```
/orquestar --smoke-test=true "test" smoke
```

Or with an actual prompt:

```
/orquestar "List the 7 colors of the rainbow in order" colors
```

See [../docs/proposals/001-orquestador-nativo-opencode.md](../docs/proposals/001-orquestador-nativo-opencode.md) for the complete design document.