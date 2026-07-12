# Installation Guide

This guide covers installation of `opencode-moa` on local machines, remote servers (VPS), and Docker containers.

## Prerequisites

- **OpenCode CLI** installed and configured (`opencode --version` should print v1.0.0+)
- **At least 3 AI model providers** configured in OpenCode (defaults: `opencode-go/glm-5.1`, `opencode-go/kimi-k2.6`, `opencode-go/minimax-m3`)
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
/orquestar --smoke-test=true "test" smoke
```

If everything works, you'll see ~12 files generated in `out/smoke/iter-1/`.

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

For example, change `"smoke_test": false` to `"smoke_test": "auto"` for this project only.

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
/orquestar --smoke-test=true "test from vps" smoke-vps
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

### Enabling smoke test by default

If you want every `/orquestar` to first run a smoke test:

```json
{
  "smoke_test": true
}
```

Or use the `"auto"` mode for heuristic-based detection.

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

Your `out/{id}/` directories (containing past iterations) are NOT removed by uninstallation. Delete them manually if desired:

```bash
rm -rf out/
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
  "/orquestar --smoke-test=true test smoke"
```

---

## Next steps

- Read the [complete design proposal](../proposals/001-orquestador-nativo-opencode.md)
- Try the [smoke test example](../../examples/smoke-test-colores.md)
- Review the [iterations analysis](../research/iterations-analysis.md)
- Check the [changelog](../../CHANGELOG.md) and [roadmap](../../ROADMAP.md)