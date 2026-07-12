# opencode-moa agents — operations & post-mortems

This file documents the operational gotchas of the `opencode-moa` agent
bundle: model-binding conflicts, headless-mode permission workarounds,
and the reasoning behind the default `modelos_a_competir` roster.
Read this **before** running `./install.sh` and **before** invoking
`/orquestar` or `/orquestar-iterate` for the first time.

## 1. The `modelos_a_competir` default roster (v0.3, 2026-07-12)

The default `opencode-moa/orquestador.json` ships with **8 models**:

| # | Model | id_corto (agent file) | Rationale for inclusion |
|---|-------|-----------------------|-------------------------|
| 1 | `minimax-coding-plan/MiniMax-M3` | `propuesta-minimax.md` | User's plan model. High floor. |
| 2 | `opencode-go/glm-5.1` | `propuesta-glm.md` | Top performer in v0.2.0-beta iter-1 (rank 3). High floor. |
| 3 | `opencode-go/glm-5.2` | `propuesta-glm-52.md` | Top performer in v0.2.0-beta iter-1 (rank 2). |
| 4 | `opencode-go/kimi-k2.6` | `propuesta-kimi.md` | Solid GTK4 validation. |
| 5 | `opencode-go/kimi-k2.7-code` | `propuesta-kimi-k27-code.md` | Only FLTK perspective. Slower (timeout-prone on `cargo tauri build`), but unique value. |
| 6 | `opencode-go/deepseek-v4-flash` | `propuesta-deepseek-flash.md` | Best ROI: $0.001/req, consistent top-5. |
| 7 | `opencode-go/mimo-v2.5` | `propuesta-mimo-v25.md` | Cheapest per request ($0.0004) + biggest iter-2 lift (+14 points) in v0.2.0-beta. |
| 8 | `opencode-go/qwen3.7-plus` | `propuesta-qwen37-plus.md` | Only Tauri alternative. Stack diversity. |

**Dropped from v0.3 bundle** (based on v0.2.0-beta iter-1+2 cost/ROI data
and 2026-07-12 rerun telemetry):

| Model | Why dropped |
|-------|-------------|
| `opencode-go/qwen3.7-max` | Worst $/req ($0.056), mid-tier output (38/50), only 18 requests = $1.00 total |
| `opencode-go/deepseek-v4-pro` | Regressed 24→24 in v0.2.0-beta iter-2; rank 11 |
| `opencode-go/qwen3.6-plus` | Regressed 27→27 in v0.2.0-beta iter-2; rank 10 |
| `opencode-go/mimo-v2.5-pro` | Persistent low performer (rank 11/12 in v0.2.0-beta) |

The full cost/ROI analysis is in
`docs/research/experiments/2026-07-12-rust-gui-app-v3.md` §6.

## 2. Model-binding conflict: `propuesta-mimo.md` and the `opencode-go/minimax-m3` model

**This is the bug that bit us on 2026-07-12.** Read carefully before
running any orchestrator invocation.

### What happened

The v0.2.0-beta bundle had `opencode-moa/agents/propuesta-mimo.md`
bound to `opencode-go/mimo-v2.5-pro` (the model that produces proposals
using the MiMo v2.5 Pro LLM via the `opencode-go` provider).

Between v0.2.0-beta and v0.3, someone (PR #1, commit `75307fd`)
**changed the frontmatter** of `propuesta-mimo.md` to:

```yaml
model: opencode-go/minimax-m3
```

This was apparently done to free up the id_corto `mimo` for a new
agent bound to the OpenCode-hosted MiniMax-M3 model. A separate agent
`propuesta-minimax.md` was created for the user's plan model
`minimax-coding-plan/MiniMax-M3`.

The user's directive ("nunca se va a ejecutar MiniMax de OpenCode")
applied to the **proposers** in `modelos_a_competir`, but the
orchestrator's step 1 logic spawns **all** `propuesta-*.md` agents
that match the model IDs in `modelos_a_competir`. Because the id_corto
derivation rule (orquestador.md step 0) maps `mimo-v2.5-pro → mimo`,
the only matching agent was `propuesta-mimo.md`, which had been
re-bound to the forbidden model.

### The consequences

1. The v0.3 orchestrator silently launched `propuesta-mimo.md` as a
   subagent with `model: opencode-go/minimax-m3` — **42 requests on
   this model in the 2026-07-12 run, $0.10 spent**.
2. When I killed the parent orchestrator PID, this subagent became an
   **orphan** and kept running.
3. The orphan continued writing spurious `01-propuesta-mimo.md` files
   with the forbidden model into iter-2's output directory.
4. This orphan then interfered with iter-2 launches, requiring me to
   kill all `opencode run` processes — which also killed 11 legitimate
   iter-2 propuesta subprocesses mid-stream.

### The fix (PR #4, commit in flight)

Restored `opencode-moa/agents/propuesta-mimo.md` to bind to
`opencode-go/mimo-v2.5-pro` (the v0.2.0-beta mapping, which matches
the bitácora §2 model table and what the user actually wants).

```yaml
---
description: Generates or improves technical proposals (MiMo v2.5 Pro variant via opencode-go)
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.7
---
```

**Also fixed in the same PR (defence-in-depth):**

- All 4 meta-agents (`orquestador.md`, `sintetizador.md`, `evaluador.md`,
  `validador.md`) had `model: opencode-go/minimax-m3` in their
  frontmatter. Changed to `model: minimax-coding-plan/MiniMax-M3`. The
  orchestrator's subagents inherit their model from their own
  frontmatter, NOT from `modelo_objetivo` in orquestador.json, so this
  was a separate bug to fix.
- `commands/orquestar.md` and `commands/orquestar-iterate.md` had
  `model: opencode-go/minimax-m3` in their frontmatter. Changed to
  `model: minimax-coding-plan/MiniMax-M3`. The command-level `model:`
  field overrides the agent's own model.
- `orquestador.md` inline JSON example (the "Default configuration"
  section) was updated to use the 8-model roster and
  `modelo_objetivo: minimax-coding-plan/MiniMax-M3` (matches the actual
  `opencode-moa/orquestador.json` default).
- `opencode-moa/orquestador.json` default `modelos_a_competir` reduced
  from 11 to 8 (see §1). `modelo_objetivo` default changed from
  `opencode-go/minimax-m3` to `minimax-coding-plan/MiniMax-M3`.

### How to verify the fix

After `./install.sh` updates your local DPS, run:

```bash
head -7 ~/.config/opencode/agents/propuesta-mimo.md
```

Expected output:
```
---
description: Generates or improves technical proposals (MiMo v2.5 Pro variant via opencode-go)
mode: subagent
model: opencode-go/mimo-v2.5-pro
temperature: 0.7
---
```

If you see `model: opencode-go/minimax-m3` instead, you have an old
local install. Re-run `./install.sh` from the repo root.

### How to grep for future model-binding conflicts

After the PR #4 fix, the v0.3 default bundle has **zero references** to
`opencode-go/minimax-m3` in active code (proposers, meta-agents,
commands, default orquestador.json, default orquestador.md inline
config). The only mentions are in this AGENTS.md as historical context.

To verify on any local DPS:

```bash
grep -rn 'opencode-go/minimax-m3' \
  ~/.config/opencode/agents/ \
  ~/.config/opencode/orquestador.json \
  /path/to/opencode-moa/opencode-moa/ 2>&1
```

Expected output: matches ONLY in AGENTS.md (this file) and historical
`docs/research/experiments/2026-07-12-rust-gui-app-v3.md` (the
post-mortem). If `propuesta-mimo.md` shows up, your install.sh
predates PR #4 — re-run it.

**Defence-in-depth against future regressions:** if a contributor adds
a new agent or model string that references `opencode-go/minimax-m3`,
a CI check should fail. The `scripts/check-no-forbidden-model.sh`
script implements this check. It greps the bundle for the forbidden
model string and fails if found outside the historical-document
whitelist (AGENTS.md, CHANGELOG.md, the two bitácoras, the original
design proposal, the paper draft).

Run it manually:
```bash
./scripts/check-no-forbidden-model.sh
```

Or in CI (the repo currently has no GitHub Actions workflow; when
one is added, this script should be a required check):
```yaml
# .github/workflows/ci.yml (skeleton)
- name: Check no forbidden model
  run: ./scripts/check-no-forbidden-model.sh
```

## 3. Headless-mode permission hangs (OpenCode upstream bug #35073)

When running `opencode run` (or `opencode run --auto --pure ...`), the
subagents spawned by the orquestador (validador in step 2, evaluador
in step 3) **hang indefinitely** on `bash: ask` permissions. The
`--auto` flag does NOT auto-approve these because the subagent
inherits interactive-actor semantics, not the primary session's
`--auto` flag.

**Upstream:** [anomalyco/opencode#35073](https://github.com/anomalyco/opencode/issues/35073)
with fix in PR #35823 (not yet released as of opencode 1.17.18).

### Workaround until the upstream fix is released

Add `bash: allow` (and any other permissions you need) to your
**user-level** `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
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

**WARNING:** this allows ALL bash in your primary session, including
destructive commands. Acceptable for a dedicated research/DPS
machine; not acceptable for production. Remove this once the
upstream fix lands.

### Workaround #2: bypass the orchestrator for step 5

If you only need the sintesis_central output (not the validador or
evaluador), invoke step 5 directly with the build agent:

```bash
setsid opencode run \
  --model minimax-coding-plan/MiniMax-M3 \
  --auto --pure --print-logs --log-level=INFO \
  --title "step 5 — sintesis_central" \
  --dir /tmp/your/test/dir \
  "Read all 12 proposals in /tmp/your/test/dir/out/{id}/iter-1/01-propuesta-*.md and produce /tmp/your/test/dir/out/{id}/iter-1/05-propuesta-integrada.md following the sintesis_central rules in opencode-moa/agents/sintetizador.md" \
  < /dev/null > /tmp/your/test/dir/logs/step5.log 2>&1 &
disown
```

This skips the permission-blocked validador (step 2) entirely.

## 4. Orphan-process handling

If you run the orchestrator in headless mode and the parent process
dies (timeout, `pkill`, segfault), the **child propuesta subagents**
can become orphans and keep running. Symptoms:

- `ps auxf | grep opencode` shows child `opencode run` processes with
  parent PID 1 (init)
- Output files keep being written to the test directory
- The models being invoked might NOT match your expected roster (the
  orphans may have been the orphan from the previous run, with
  different model bindings)

### How to clean up orphans

```bash
# Find all opencode run processes (excluding the user's main TUI)
pgrep -af opencode | grep -v ' 2088 opencode\|grep' | head -10

# Kill them ALL (be careful — this also kills legitimate subprocesses)
pkill -9 -f 'opencode run' 2>&1

# Wait, then verify
sleep 2
pgrep -af 'opencode run' | wc -l  # should be 0
```

The user's main opencode TUI session (typically PID 2088 or similar)
should NOT be killed — only the headless `opencode run` invocations.

## 5. Quota telemetry

The `minimax-coding-plan` provider does NOT return cost/tokens in the
response metadata. To get accurate cost attribution per model:

1. Open the opencode-web UI (`agent.rovisoft.net`) → Settings →
   Usage → filter by date range → copy the per-model table.
2. The format is: `Modelo | Peticiones | Costo (USD) | % | Tokens In |
   Tokens Out | Reasoning`.

The `opencode-go` provider DOES return cost/tokens. If you switch the
`modelo_objetivo` to `opencode-go/...` temporarily, you'll get
per-call cost data in the session telemetry. Useful for ad-hoc
cost-attribution runs.

## 6. How to add a new model to the roster

1. Create `opencode-moa/agents/propuesta-{id_corto}.md` with the
   desired model binding in the frontmatter. Use the existing files
   as templates.
2. Add the model string to `modelos_a_competir` in
   `opencode-moa/orquestador.json`.
3. Run `./install.sh` to deploy the new agent to your local DPS.
4. Verify:
   ```bash
   grep '^model:' ~/.config/opencode/agents/propuesta-{id_corto}.md
   ```
5. Add an entry to the table in §1 of this file (rationale for
   inclusion).

## 7. How to drop a model from the roster

1. Remove the model string from `modelos_a_competir` in
   `opencode-moa/orquestador.json`.
2. Optionally delete the corresponding `propuesta-{id_corto}.md` file
   if you don't want to keep the agent definition for future
   re-inclusion. **Caution:** the bitácora files reference these
   filenames; deleting them would orphan the references.
3. Update the table in §1 of this file (move from "included" to
   "dropped" section with rationale).
4. Update `CHANGELOG.md` with the change.
5. Re-run `./install.sh` (the orquestador.json change propagates).

## 8. Cross-references

- Bitácora 2026-07-11 (v0.2.0-beta baseline): `docs/research/experiments/2026-07-11-rust-gui-app.md`
- Bitácora 2026-07-12 (v0.3 sintesis_central validation): `docs/research/experiments/2026-07-12-rust-gui-app-v3.md`
- Paper draft §6.2 (sintesis_central vs self_improve): `docs/papers/DRAFT-multi-model-orchestration.md`
- OpenCode upstream bug: [anomalyco/opencode#35073](https://github.com/anomalyco/opencode/issues/35073)
- OpenCode fix PR: [anomalyco/opencode#35823](https://github.com/anomalyco/opencode/pull/35823)