# opencode-moa (installable bundle)

This folder contains ONLY the files you need to install in your OpenCode configuration. Everything else in this repository (documentation, proposals, examples) stays in the repo for reference.

**Current bundle: v1.2 (2026-07-13) — 40 MiniMax M3 agents + 4 meta-agents + 2 commands.**

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
# Should show: 50 files (40 propuesta-* + 5 meta-agents + 4 legacy propuesta-* + 1 orquestador)
# Wait: 40 propuesta-minimax-* + 1 propuesta-minimax (original) + 8 propuesta-go-* (legacy)
#      + orquestador + evaluador + sintetizador + validador = 54

ls ~/.config/opencode/commands/
# Should show: orquestar.md, orquestar-iterate.md

cat ~/.config/opencode/orquestador.json | jq '.agentes_a_competir | length'
# Should show: 40 (the v1.2 default roster)
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

## What this installs (v1.2)

| File / group | Count | Purpose |
|---|---:|---|
| `agents/orquestador.md` | 1 | Primary agent. Coordinates 10 steps + iterate mode. |
| `agents/evaluador.md` | 1 | Subagent. Evaluates all proposals (single-model, temp 0.0). |
| `agents/sintetizador.md` | 1 | Subagent. Classifies + integrates + selects winners. |
| `agents/validador.md` | 1 | Subagent. Empirical validation (off by default in v1.2). |
| `agents/propuesta-minimax.md` | 1 | Original v1.1 baseline agent (untouched). |
| `agents/propuesta-minimax-baseline-{01..10}.md` | 10 | Grupo A — 10 clones for variance measurement. |
| `agents/propuesta-minimax-{creative,security-first,performance-focused,minimal,maintainable}.md` | 5 | Grupo B — prompt-injection variants. |
| `agents/propuesta-minimax-T*.md` | 7 | Grupo C — temperature sweep (T=0.0 → 1.5). |
| `agents/propuesta-minimax-P*.md` | 4 | Grupo C — top_p sweep (P=0.1 → 0.99). |
| `agents/propuesta-minimax-K*.md` | 4 | Grupo C — top_k sweep (K=1 → 200). |
| `agents/propuesta-minimax-T*P*.md` | 4 | Grupo C — temp×top_p combos. |
| `agents/propuesta-minimax-T*K*.md` | 3 | Grupo C — temp×top_k combos. |
| `agents/propuesta-minimax-T*P*K*.md` | 3 | Grupo C — triple combos (stress test). |
| `agents/propuesta-{glm,glm-52,kimi,kimi-k27-code,deepseek-flash,mimo-v25,qwen37-plus,mimo}.md` | 8 | Legacy OpenCode Go agents (NOT in default roster; opt-in via `agentes_a_competir` override). |
| `commands/orquestar.md` | 1 | Custom command: `/orquestar <prompt> <id>`. |
| `commands/orquestar-iterate.md` | 1 | Custom command: `/orquestar-iterate <prompt> <id>`. |
| `orquestador.json` | 1 | Config with `agentes_a_competir` (40 entries by default). |

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
for fast iteration. The default 40-agent roster takes ~21 min per
step 1.

## Adding more agents (v1.2)

To add a 41st agent (e.g. a new variant):

1. Create `agents/propuesta-{name}.md` with the desired
   `model:`, `temperature:`, `top_p:`, `top_k:` fields in the
   frontmatter.
2. Add `"propuesta-{name}"` (without `.md`) to the `agentes_a_competir`
   array in `orquestador.json`.

Multiple agents can share the same `model:` field — they invoke
independently and rank independently.

## Mixing MiniMax + OpenCode Go

The default 40-agent roster is MiniMax-only. To add OpenCode Go models
(8 agents) on top of the 40 MiniMax, append them to `agentes_a_competir`:

```jsonc
{
  "agentes_a_competir": [
    ...40 MiniMax entries...,
    "propuesta-glm",
    "propuesta-glm-52",
    "propuesta-kimi",
    "propuesta-kimi-k27-code",
    "propuesta-deepseek-flash",
    "propuesta-mimo-v25",
    "propuesta-qwen37-plus",
    "propuesta-mimo"
  ]
}
```

Note: this brings the total to 48 agents. Step 1 spans 16 batches of 3
+ 1 batch of 1 = ~24 min wall time. OpenCode Go models run via the
`opencode-go` provider (separate $12/5h budget from MiniMax Token Plan).

## After installation

Try the smoke test with the full 40-agent roster:

```
/orquestar --smoke-test=true "test" arco-iris-40
```

Expected: ~25 min wall time. Output includes a `## Parameter
validation report` section in `04-clasificacion.md` showing which
parameter-sweep agents produced distinct outputs.

Or with a single-agent smoke test (faster, ~3 min):

```
cp opencode-moa/orquestador.json /tmp/my-project/
# Edit to set agentes_a_competir to just one agent
/orquestar --smoke-test=true "test" smoke
```

See [../docs/proposals/001-orquestador-nativo-opencode.md](../docs/proposals/001-orquestador-nativo-opencode.md) for the complete design document.