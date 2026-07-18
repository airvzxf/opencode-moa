# Installation Guide

This guide covers installation of `opencode-moa` on local machines, remote servers (VPS), and Docker containers.

## Prerequisites

- **OpenCode CLI** installed and configured (`opencode --version` should print v1.0.0+)
- **At least 2 AI model providers** configured in OpenCode:
  - `minimax-coding-plan` (the user's MiniMax Token Plan — used by ALL
    v0.3 agents: proposers, meta-agents, and the orchestrator itself)
  - `opencode-go` (used by the 7 opencode-go models in the default
    roster: glm-5.1, glm-5.2, kimi-k2.6, kimi-k2.7-code, deepseek-v4-flash,
    mimo-v2.5, qwen3.7-plus)
- A POSIX-compliant shell (bash, zsh, fish) for the install commands

## Installation methods

Choose the method that matches your use case:

| Method | Best for | Difficulty |
|---|---|---|
| A. User-level install (recommended) | Personal use across all projects | Easy |
| B. Project-level install | Single-project, isolated config | Easy |
| C. VPS / remote install | Headless server, OpenCode web | Medium |
| D. Docker install | Reproducible environments, CI/CD | Medium |

---

## Method A: User-level install (recommended)

This is the standard installation. The `opencode-moa` files go in your user-level OpenCode config directory and are available in every project.

### Step 1: Clone the repo

```bash
git clone https://github.com/YOUR-USERNAME/opencode-moa.git
cd opencode-moa
```

### Step 2: Run the install script

The repo includes a `install.sh` script (in the repo root, NOT in the `opencode-moa/` subfolder — see [`../README.md`](../README.md) for why):

```bash
./install.sh
```

This copies:
- `opencode-moa/agents/*.md` → `~/.config/opencode/agents/`
- `opencode-moa/commands/*.md` → `~/.config/opencode/commands/`
- `opencode-moa/orquestador.json` → `~/.config/opencode/`

### Step 3: Verify

```bash
# Confirm files are in place
ls ~/.config/opencode/agents/
# Should show 9 files: orquestador.md,
#                      propuesta-glm.md, propuesta-kimi.md, propuesta-mimo.md,
#                      propuesta-deepseek.md, propuesta-minimax.md,
#                      evaluador.md, sintetizador.md, validador.md

ls ~/.config/opencode/commands/
# Should show 2 files: orquestar.md, orquestar-iterate.md

cat ~/.config/opencode/orquestador.json
# Should show the JSON config
```

### Step 4: Smoke test from OpenCode

Open OpenCode in any project:

```bash
cd /tmp  # any project
opencode
```

In the OpenCode TUI:

```
/orquestar "Design a simple CLI tool that prints 'hello'" hello-cli
```

If everything works, you'll see ~12 files generated in `out/hello-cli/`.

---

## Method B: Project-level install

For project-specific configurations (e.g., a research project that needs different models), install directly in the project's `.opencode/` directory.

### Step 1: Copy to project

```bash
cd /path/to/your/project
mkdir -p .opencode/agents .opencode/commands

cp /path/to/opencode-moa/opencode-moa/agents/*.md .opencode/agents/
cp /path/to/opencode-moa/opencode-moa/commands/*.md .opencode/commands/
cp /path/to/opencode-moa/opencode-moa/orquestador.json ./
```

### Step 2: Edit project-level config

```bash
# Override specific fields in ./orquestador.json
nano orquestador.json
```

For example, change `agentes_a_competir` to a smaller subset, or flip `validacion_empirica` to `true`, for this project only.

### Step 3: Run from project

```
/orquestar "Design something specific to this project" my-id
```

Project-level overrides take precedence over user-level.

---

## Method C: VPS / remote install (SSH)

For installing on a remote server (e.g., Hetzner VPS running OpenCode web).

### Step 1: Connect via SSH

```bash
ssh user@your-vps-ip
```

### Step 2: Install OpenCode if not already

```bash
# On the VPS
curl -fsSL https://opencode.ai/install | bash
```

### Step 3: Clone and install

```bash
# On the VPS
git clone https://github.com/YOUR-USERNAME/opencode-moa.git
cd opencode-moa
./install.sh
```

### Step 4: Configure models

The OpenCode web UI should already be running (default port 4096). Open `https://your-vps-domain/` and configure your AI providers via `/connect`.

### Step 5: Test from OpenCode web

Open the OpenCode web UI in your browser and run:

```
/orquestar "Design a small REST endpoint" hello-vps
```

### Updating later

```bash
# On the VPS
cd ~/opencode-moa
git pull
./install.sh
```

The install script overwrites user-level files with the new versions. Project-level overrides are NOT touched.

---

## Method D: Docker install

For reproducible environments, e.g., CI/CD pipelines or shared development servers.

### Dockerfile

```dockerfile
FROM opencode/opencode:latest

# Install opencode-moa
RUN git clone https://github.com/YOUR-USERNAME/opencode-moa.git /tmp/opencode-moa \
    && cd /tmp/opencode-moa \
    && mkdir -p /root/.config/opencode/agents /root/.config/opencode/commands \
    && cp opencode-moa/agents/*.md /root/.config/opencode/agents/ \
    && cp opencode-moa/commands/*.md /root/.config/opencode/commands/ \
    && cp opencode-moa/orquestador.json /root/.config/opencode/ \
    && rm -rf /tmp/opencode-moa

# Optional: copy your project-level config
# COPY orquestador.json /workspace/.opencode/orquestador.json

WORKDIR /workspace
CMD ["opencode"]
```

### Build and run

```bash
docker build -t my-opencode-moa .
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.config/opencode:/root/.config/opencode \
  my-opencode-moa
```

---

## Customizing after install

### Changing the list of competing models

Edit `~/.config/opencode/orquestador.json`:

```json
{
  "modelos_a_competir": [
    "opencode-go/glm-5.1",
    "opencode-go/claude-sonnet-4",
    "opencode-go/gpt-4"
  ]
}
```

For each new model, create a corresponding agent file:

```bash
# For claude-sonnet-4
cp ~/.config/opencode/agents/propuesta-glm.md \
   ~/.config/opencode/agents/propuesta-claude.md

# Edit the new file and change the model: field
sed -i 's|model: opencode-go/glm-5.1|model: opencode-go/claude-sonnet-4|' \
    ~/.config/opencode/agents/propuesta-claude.md
```

(Repeat for each new model.)

### Changing the evaluator / validator / synthesizer model

Edit `~/.config/opencode/orquestador.json`:

```json
{
  "modelo_objetivo": "opencode-go/claude-opus-4"
}
```

This changes the model used by `evaluador`, `sintetizador`, `validador`, and `orquestador`. Make sure your provider supports this model.

### Disabling empirical validation

If you don't want the validator to execute bash commands:

```json
{
  "validacion_empirica": false
}
```

Steps 2 and 6 will be skipped.

### Enabling strict disqualification

If you want proposals marked ❌ NO VIABLE to be removed from the ranking:

```json
{
  "descalificar_fallida": true
}
```

(Defaults to `false` to keep proposals with viable sections in the ranking.)

---

## Updating

To update to the latest version of `opencode-moa`:

```bash
cd /path/to/opencode-moa
git pull
./install.sh
```

The install script is idempotent — it overwrites existing files without prompts.

To pin to a specific version:

```bash
cd /path/to/opencode-moa
git fetch --tags
git checkout v0.2.0
./install.sh
```

---

## Uninstalling

To remove `opencode-moa`:

```bash
# Remove the agents
rm ~/.config/opencode/agents/orquestador.md
rm ~/.config/opencode/agents/propuesta-glm.md
rm ~/.config/opencode/agents/propuesta-kimi.md
rm ~/.config/opencode/agents/propuesta-mimo.md
rm ~/.config/opencode/agents/propuesta-deepseek.md
rm ~/.config/opencode/agents/propuesta-minimax.md
rm ~/.config/opencode/agents/evaluador.md
rm ~/.config/opencode/agents/sintetizador.md
rm ~/.config/opencode/agents/validador.md

# Remove the commands
rm ~/.config/opencode/commands/orquestar.md
rm ~/.config/opencode/commands/orquestar-iterate.md

# Remove the config (only if no other project depends on it)
rm ~/.config/opencode/orquestador.json

# Remove project-level files (if any)
rm /path/to/project/orquestador.json
rm -rf /path/to/project/.opencode/agents/{orquestador,propuesta-*,evaluador,sintetizador,validador}.md
rm -rf /path/to/project/.opencode/commands/{orquestar,orquestar-iterate}.md
```

Your `{id}/` directories (containing past runs, with the v1.6 layout
`{id}/{subagent}/{proposal,work,log}/`) are NOT removed by
uninstallation. Delete them manually if desired:

```bash
rm -rf {id}/
```

---

## Troubleshooting

### "Agent file not found: propuesta-opus.md"

You added a model to `modelos_a_competir` without creating the corresponding agent file. Either:
- Create the agent file: `cp propuesta-glm.md propuesta-opus.md` and change its `model:` field.
- Remove the model from `modelos_a_competir`.

### "Permission denied" when running validator commands

The validator has restricted bash permissions (see [`../proposals/001-orquestador-nativo-opencode.md`](../proposals/001-orquestador-nativo-opencode.md#125-permisos-bash-del-validador)). If a needed command isn't in the whitelist, edit `~/.config/opencode/agents/validador.md` and add the glob pattern to the `permission.bash` section.

### "Configuration not loading"

Verify the JSON is valid:

```bash
python3 -m json.tool < ~/.config/opencode/orquestador.json
```

If it prints the formatted JSON, it's valid. If it errors, fix the syntax.

### "Commands not appearing in /command list"

Restart OpenCode. Custom commands are loaded at startup.

```bash
# Exit OpenCode and start again
opencode
```

### Smoke test or `/orquestar` hangs at step 3 (evaluator blocked on permission)

In headless mode (`opencode run …`) the orchestrator and its subagents
occasionally read files outside the project directory (this is triggered
when OpenCode's permission resolver normalizes a relative path against
a different reference point than your shell's `cwd`). The default
`external_directory: "*"` rule is `ask`, which headless mode cannot
approve without a TTY.

**Fix:** add a project-level `opencode.jsonc` that allowlists the
expected paths. Template:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "*": "allow",
    "external_directory": {
      "/tmp/opencode/<your-test-dir>/*": "allow",
      "/tmp/opencode/*": "allow",
      "/home/wolf/.local/share/opencode/*": "allow"
    }
  }
}
```

A ready-to-copy version lives at
`examples/opencode.jsonc.test-template` (just rename it to
`opencode.jsonc` in your test dir).

> **Production users** should NOT use `"*": "allow"`. Keep permissions
> restrictive (`ask` or `deny` per category) and only allowlist the
> specific paths you actually need.

### `opencode run --command "/orquestar ..."` returns `UnknownError`

Known issue in OpenCode ≤ 1.17.18 when combining `--command` with
`--agent`. Workaround: pass the slash command as a positional message
and select the agent explicitly via `--agent`:

```bash
opencode run \
  --agent orquestador \
  --model minimax-coding-plan/MiniMax-M3 \
  --auto \
  --pure \
  --print-logs \
  --dir /your/test/dir \
  "/orquestar \"Design a REST API for inventory management\" auth-jwt"
```

### Subagent (validador / evaluador) hangs at step 2/3 waiting for permission

**Symptom:** when running the full orchestrator pipeline in headless
mode, step 2 (validador) or step 3 (evaluador) blocks indefinitely on a
`bash: ask` permission prompt. The `--auto` flag does NOT auto-approve
these because the subagent inherits interactive-actor semantics, not the
primary session's `--auto` flag.

**Root cause:** this is [OpenCode upstream issue #35073](https://github.com/anomalyco/opencode/issues/35073)
("fix: subagent permission asks hang indefinitely"). The fix landed in
PR #35823 but may not be in the release you're running (opencode 1.17.18
as of 2026-07-12). Related issues: #13715, #32388, #33028.

**Workaround (until upstream fix is released in your binary):**

1. Set `bash: allow` (and any other permissions you need) at the **user
   level**, not just project level. The project-level config does not
   propagate to subagents reliably; user-level does:

   ```bash
   # Add to ~/.config/opencode/opencode.jsonc
   {
     "permission": {
       "bash": "allow",
       "edit": "allow",
       "write": "allow",
       "read": "allow",
       "webfetch": "allow",
       "task": "allow",
       "todowrite": "allow",
       "external_directory": {
         "/tmp/opencode-moa-v3-test/*": "allow",
         "/tmp/opencode/*": "allow",
         "/home/wolf/.local/share/opencode/*": "allow"
       }
     }
   }
   ```

   **WARNING:** this allows ALL bash in the primary session, including
   destructive commands. Acceptable for a dedicated research/DPS
   machine; not acceptable for a production machine.

2. Alternative: bypass the orchestrator entirely and invoke step 5
   (sintesis_central) directly via the build agent with `--model`
   override and `--auto --pure`. This avoids the validador subagent
   entirely. See `docs/research/experiments/2026-07-12-rust-gui-app-v3.md`
   §10 Appendix for the wrapper script `run-step5.sh`.

**Long-term:** track [PR #35823](https://github.com/anomalyco/opencode/pull/35823)
for the upstream fix. Once merged and released, the user-level config
can be removed and the project-level config becomes sufficient again.

---

## Next steps

- Read the [complete design proposal](../proposals/001-orquestador-nativo-opencode.md)
- Try the [REST API example](../../examples/auth-jwt-rest-api.md)
- Review the [iterations analysis](../research/iterations-analysis.md)
- Check the [changelog](../../CHANGELOG.md) and [roadmap](../../ROADMAP.md)