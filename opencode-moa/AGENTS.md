# opencode-moa agents — operations & post-mortems

This file documents the operational gotchas of the `opencode-moa` agent
bundle: model-binding conflicts, headless-mode permission workarounds,
and the reasoning behind the default `agentes_a_competir` roster.
Read this **before** running `./install.sh` and **before** invoking
`/orquestar` for the first time.

## 1. The `agentes_a_competir` default roster (v1.3, 2026-07-13)

The default `opencode-moa/orquestador.json` ships with **42 agentes_a_competir**
(6 OpenCode Go + 36 MiniMax Token Plan). This was the v1.3 revision
applied after the 2026-07-13 v5 experiment
(`docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`) validated
the cost-and-quality rationale for the trim, then extended with the
restore of `propuesta-minimax-maintainable` (v1.3.1 addendum).

**v1.2 → v1.3 changes (2026-07-13):**

- **OpenCode Go: 11 → 6 agents.** Dropped: `glm-52` (worst ROI, $0.0475/score-pt, fabricated `rustc 1.92` claim), `kimi-k27-code` (FLTK redundant with `glm`), `mimo-v25` (eframe 0.30 redundant), `qwen36-plus` (hallucinated), `qwen37-max` (Tauri no-artifact).
- **MiniMax Token Plan: 41 → 36 agents** (v1.3 initial trim was 35; v1.3.1 addendum restored `maintainable` to 36). Dropped: `performance-focused` Grupo B (low score, no unique contribution); T00/T03/T08 temperature (incompatible toolchain or single-window trap); P01/P05/P09 top_p (Tauri cluster or redundant); all K01/K05/K50/K200 top_k (no unique contribution; clamp-discovery lives in T10K200 combo); 8 redundant combos.
- **v1.3.1 addendum (2026-07-13, same day):** restored `propuesta-minimax-maintainable` from the `.v1.2-preserved` backup as an **active** agent alongside `propuesta-minimax-testable`. The two are orthogonal lenses: `testable` covers test-coverage (every public interface has a test); `maintainable` covers code-readability and team-onboarding (every public function has a docstring with usage example, prefer boring documented libraries, etc.). User reasoning: `testable` was correctly added in v1.2.1 as a NEW agent, but the removal of `maintainable` was an over-correction; both lenses are independently useful and should run side-by-side. The restored `maintainable` has the v1.2.1 `⚠️ ROLE OVERRIDE` directive prepended (same format as the other 4 original Grupo B variants) so the inyectado fix applies consistently.
- **Added 5 baselines** (10 → 15). `propuesta-minimax-baseline-11..15`. Strengthens statistical base for the intrinsic-variance control cohort.
- **Added 8 Grupo B prompt-injection variants** (4 → 12, now 13 with maintainable restore). All use the v1.3 `⚠️ ROLE OVERRIDE` directive prepended at the top of the agent file. New variants: `a11y` (accessibility), `errors` (Result + thiserror), `portable` (cross-platform), `i18n` (internationalization), `rustdoc` (documentation completeness), `observability` (structured tracing + metrics), `ci-github` (GitHub Actions CI), `cd-releases` (GitHub Releases distribution).

### Roster breakdown (v1.3)

**6 OpenCode Go agents** (default roster, included since v1.3):

| # | Agent | Model | Cost | Why kept |
|---|---|---|---:|---|
| 1 | `propuesta-kimi` | `opencode-go/kimi-k2.6` | $0.62 | Highest OCG score (40/50) — top performer |
| 2 | `propuesta-deepseek` | `opencode-go/deepseek-v4-pro` | $0.26 | **Best ROI** in OCG ($0.0068/score-pt) |
| 3 | `propuesta-deepseek-flash` | `opencode-go/deepseek-v4-flash` | $0.04 | Cheap flash variant; eframe coverage |
| 4 | `propuesta-glm` | `opencode-go/glm-5.1` | $0.78 | Only FLTK representative |
| 5 | `propuesta-mimo` | `opencode-go/mimo-v2.5-pro` | $0.36 | Only iced 0.14 verified |
| 6 | `propuesta-qwen37-plus` | `opencode-go/qwen3.7-plus` | $0.08 | Only GTK3 representative + cheapest legitimate |

**36 MiniMax Token Plan agents** (all bind to `model: minimax-coding-plan/MiniMax-M3`):

| Group | # agents | Naming | Rationale |
|---|---:|---|---|
| Original | 1 | `propuesta-minimax` | Pre-v1.2 baseline. Kept as reference for direct comparability with earlier runs. |
| A — Baselines | 15 | `propuesta-minimax-baseline-{01..15}` | 15 clones with identical frontmatter (T=0.7). Measures intrinsic variance of MiniMax M3 sampling. Increased from 10 in v1.3 to strengthen statistical base. |
| B — Prompt injection | 13 | `propuesta-minimax-{creative,security-first,minimal,testable,maintainable,a11y,errors,portable,i18n,rustdoc,observability,ci-github,cd-releases}` | Each adds a priority directive **as the first content** of the system prompt (v1.2.1+v1.3 inyectado fix). The directive overrides all other principles. 8 new variants in v1.3 cover accessibility, error handling, portability, i18n, documentation, observability, CI, CD. `maintainable` was restored in v1.3.1 from the `.v1.2-preserved` backup as a 13th variant (orthogonal to `testable`). |
| C — Temperature sweep | 4 | `propuesta-minimax-T{05,07,10,15}` | T ∈ {0.5, 0.7, 1.0, 1.5}. T=1.5 is out-of-Anthropic-spec — verifies whether MiniMax clamps it. Trimmed from 7 in v1.2.1 to 4 in v1.3 (dropped T00/T03/T08 for compatibility or single-window trap). |
| C — top_p sweep | 1 | `propuesta-minimax-P099` | top_p = 0.99 at T=0.7. Only P099 kept — P01/P05/P09 dropped (Tauri cluster or redundant). |
| C — Combos | 2 | `propuesta-minimax-T{05K50,10K200}` | Mid-range combinations. T10K200 is the only proposal with honest clamp-admission (§5.7 in paper draft). |
| **Total** | **36** | | |

**Grand total: 6 + 36 = 42 agentes_a_competir.**

### Cost estimate (per run, extrapolated from Run C v5)

- OCG (6 of 11 kept): ~$2.10 vs $4.44 full (–$2.34, –53%)
- MiniMax (36 vs 41): ~$0.14 vs $0.16 (–$0.02, –13%)
- **Total:** ~$2.24 vs $4.60 (–$2.36, –51%)
- Cache hit rate: ~91% of input tokens served from cache (the dominant cost-optimization factor)

### Wall-clock estimate (per run, strict serial)

- Step 1: 42 agentes / 1 per response = 42 responses × ~3 min = ~126 min (serialised; well under Max-tier ceiling)
- Steps 3-9: ~30 min (unchanged)
- **Total:** ~156 min (unchanged; batches run faster since no shared-quota contention, but there are 3× more of them). `max_wall_clock_minutes: 0` leaves the run unlimited by default.

### Drop rationale (why these specific agents were removed)

The complete rationale is in `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md` §8 and `docs/papers/DRAFT-multi-model-orchestration.md` §5.5. Summary:

1. **All agents with fabricated verifications removed** (5 in v1.2.1: `glm-52`, `qwen36-plus`, `qwen37-max`, and 4 MiniMax `gtk4 0.11` agentes with `rustc 1.92` hallucinations — only `qwen37-max` was in the bundle; the 4 gtk4 0.11 MiniMax were T-sweep variants now removed). The remaining v1.3 roster has zero fabricators.
2. **All redundant-stack agentes removed.** When 7 proposals all chose Tauri without producing on-disk artifacts (v5 §3.2), or when 5 chose `eframe 0.33` with identical recipes, the duplicates are noise.
3. **All agents with no unique winning contribution removed.** E.g., `mimo-v25` (eframe 0.30) had the same score (34/50) as `mimo` (iced 0.14) but no additional stack coverage.
4. **Top_k sweep removed entirely.** The clamp-discovery insight lives in `T10K200` (combo). The standalone `K*` agents added nothing.

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
   with the forbidden model into a follow-up output directory.
4. This orphan then interfered with subsequent launches, requiring me to
   kill all `opencode run` processes — which also killed 11 legitimate
   propuesta subprocesses mid-stream.

### The fix (PR #4, applied in v1.2.1)

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
- `commands/orquestar.md` had `model: opencode-go/minimax-m3` in its
  frontmatter. Changed to `model: minimax-coding-plan/MiniMax-M3`. The
  command-level `model:` field overrides the agent's own model.
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

After the v1.2.1 fix, the v1.3 default bundle has **zero references** to
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
predates the v1.2.1 fix — re-run it.

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
  "Read all 12 proposals in /tmp/your/test/dir/{id}/*/proposal/01-propuesta-*.md and produce /tmp/your/test/dir/{id}/orquestador/proposal/05-propuesta-integrada.md following the sintesis_central rules in opencode-moa/agents/sintetizador.md" \
  < /dev/null > /tmp/your/test/dir/{id}/orquestador/log/05-propuesta-integrada.log 2>&1 &
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

## 6. How to add a new agent to the roster (v1.2+)

1. Create `opencode-moa/agents/propuesta-{agent}.md` with the desired
   `model:`, `temperature:`, `top_p:`, `top_k:` fields in the
   frontmatter. Use the existing files as templates.
2. Add the agent name (without `.md`) to `agentes_a_competir` in
   `opencode-moa/orquestador.json`.
3. Run `./install.sh` to deploy the new agent to your local DPS.
4. Verify:
   ```bash
   head -10 ~/.config/opencode/agents/propuesta-{agent}.md
   ```
5. Add an entry to the table in §1 of this file (rationale for
   inclusion).

Multiple agents can share the same `model:` field. They are invoked
independently by the Task tool and ranked independently by the
evaluador.

For v1.3 Grupo B variants with priority injection (a11y, errors,
portable, i18n, rustdoc, observability, ci-github, cd-releases), the
template prepends the `⚠️ ROLE OVERRIDE` heading as the very first
content after the frontmatter. Copy that template structure when
adding new variants — the directive must be the FIRST thing the LLM
sees in its system prompt.

## 7. How to drop an agent from the roster

1. Remove the agent name from `agentes_a_competir` in
   `opencode-moa/orquestador.json`.
2. Optionally delete the corresponding `propuesta-{agent}.md` file if
   you don't want to keep the agent definition for future re-inclusion.
   **Caution:** the bitácora files reference these filenames; deleting
   them would orphan the references. Historical backups use
   suffixes like `.v1.2-preserved` or `.v0.3-pre-update.bak`.
3. Update the table in §1 of this file (move from "included" to
   "dropped" section with rationale).
4. Update `CHANGELOG.md` with the change.
5. Re-run `./install.sh` (the orquestador.json change propagates).

## 8. Cross-references

- Bitácora 2026-07-11 (v0.2.0-beta baseline): `docs/research/experiments/2026-07-11-rust-gui-app.md`
- Bitácora 2026-07-12 (v0.3 sintesis_central validation): `docs/research/experiments/2026-07-12-rust-gui-app-v3.md`
- Bitácora 2026-07-13 (v1.2 — 40-agent MiniMax sweep): `docs/research/experiments/2026-07-13-minimax-sweep-v4.md`
- Bitácora 2026-07-13 (v1.2.1 — 52-agent run, gtk4 0.10 winner, $4.60 cost): `docs/research/experiments/2026-07-13-rust-gui-popup-v5.md`
- Paper draft §5.5-§5.7 + §7.9 (Run C, v1.3 revision): `docs/papers/DRAFT-multi-model-orchestration.md`
- OpenCode upstream bug: [anomalyco/opencode#35073](https://github.com/anomalyco/opencode/issues/35073)
- OpenCode fix PR: [anomalyco/opencode#35823](https://github.com/anomalyco/opencode/pull/35823)

## 9. Schema v1.2 — agent-first roster (rationale)

**v1.1 schema (legacy):** `modelos_a_competir` was an array of model
strings (e.g. `"minimax-coding-plan/MiniMax-M3"`). The orchestrator
applied a derivation rule to compute an `id_corto`:

```
"minimax-coding-plan/MiniMax-M3"
  → strip provider prefix: "MiniMax-M3"
  → strip version segment "-M3": "MiniMax"
  → lowercase: "minimax"
  → única propuesta-minimax.md
```

This made the roster **1 model string ↔ 1 agent file**. Adding a
second `propuesta-{variant}.md` agent bound to the same model caused
a **collision**: the derivation still mapped both to `minimax`, and
the orchestrator's "prefer the shortest filename" tiebreaker invoked
only one. Multi-variant experiments of the same model were not
possible.

**v1.2 schema:** `agentes_a_competir` is an array of agent names
(e.g. `"propuesta-minimax-T15"`, `"propuesta-minimax-baseline-01"`).
The orchestrator:

1. For each entry, looks up `~/.config/opencode/agents/{agente}.md`.
2. Reads the `model:` field from the frontmatter.
3. Invokes the subagent with `subagent_type=agente`. The Task tool
   uses the agent's own `model:` field, NOT anything in
   `orquestador.json`.

This decouples agent identity from model identity. Multiple agents
sharing the same `model:` field are valid and run side-by-side.

**Migration path:**

- v1.1 `modelos_a_competir` is REMOVED. Projects using the old field
  will fail to parse and the orchestrator will ABORT with explicit
  instructions.
- v1.0 `version` field: existing JSONs need to be bumped to `"1.2"`.

**Why now:** the 2026-07-13 experiment (40 MiniMax M3 variants) was
the motivating use case. Without v1.2, only one of the 40 variants
would have been invoked. With v1.2, all 40 run independently and
the user can compare their outputs on identical prompts.

## 10. v1.2 — concurrency cap and parameter validation

### Concurrency cap (REMOVED in v1.5)

**Historical context only.** The v1.2-v1.4 `step_1_concurrent_max`
parameter controlled the batch size of step 1 (and step 2 / step 6)
proposal fan-outs. The MiniMax Token Plan Max tier supports 4-5
concurrent agents sustained, so bursting more risked hitting the
5-hour rolling quota or getting throttled by the gateway. The
parameter's default was 1 (strict serial) since v1.4.

In v1.5 the parameter was **removed entirely** from
`orquestador.json` and the orquestador prompt. Strict serialization is
now structurally enforced by the orchestrator prompt itself — there is
no batching loop, no `chunk()` call, no `BATCH_SIZE` variable. Each
propuesta (and each validador in steps 2 and 6) gets its own
orchestrator response containing exactly one `task()` call. Peak
concurrent MiniMax agents in step 1 is permanently 1 (+ 1 evaluador at
step 3 transition = 2, well within the Max-tier ceiling of 4-5). Step
1 wall time is unchanged from the v1.4 default-1 behavior (~126 min for
the 42-agent roster). Existing v1.4 configs that still carry the field
parse silently — the field is ignored.

`step_1_agent_timeout_seconds` (default 0 = unlimited; v1.4 changed
from default 600) bounds each propuesta subagent. If a subagent
exceeds the timeout, it is ABORTED and the run continues with whatever
proposals did complete.

### v1.2.1 STRICT SERIALIZATION RULE (structural since v1.5)

After running the v1.2 experiment, the user pointed out that if
`step_5_modo: sintesis_central` runs concurrently with step 1's last
batch (via LLM batching across steps), peak concurrent MiniMax agents
could exceed the Max-tier ceiling. The fix:

- Steps are **STRICTLY SEQUENTIAL relative to other numbered steps**.
  Since v1.5 this is structurally enforced — there are no longer any
  "sibling agents inside one step 1 batch" because step 1 emits exactly
  one `task()` call per orchestrator response. Step 1 must complete
  entirely (all responses done, all files written or timed out) before
  step 3 launches. Step 3 must complete before step 4. Etc.
- **DO NOT combine step 1 task() calls with step 3+ task() calls
  in the same response.** If the LLM is tempted, split into two
  responses: response 1 = the step 1 task() call; response 2
  (after response 1 returns) = step 3+ task() call.
- `step_5_modo: sintesis_central` default was changed to `skip`
  (see v1.2.1 §1 patch notes) because the integrated synthesis call
  was the most likely trigger of the post-step-1 hang.
  **Reverted in v1.4 (2026-07-18):** the hang was later attributed to
  cross-step LLM batching rather than to the integrator itself, and the
  corpus of end-to-end runs since (Run D fib-rust-cli, Run E
  moodle-quiz-extractor, Run F voxora-kernels) shows `sintesis_central`
  wins on quality in some cohorts and loses in others. Net effect is
  positive — the integrator consolidates the field — so the default is
  flipped back to `sintesis_central`. With strict serialization now
  structurally permanent in v1.5, the cross-step batching that
  triggered the v1.2.1 hang cannot recur.

### Parameter validation report (`param_validation_report`)

For agents whose name matches `propuesta-minimax-T*`, `propuesta-minimax-P*`,
`propuesta-minimax-K*`, or any combination thereof, the step 1 prompt
template instructs the agent to append a `## Generation parameters`
section to its output proposal, reporting:

- Declared values (from the agent's frontmatter)
- Observed values (from the opencode SDK's response metadata, if
  exposed)
- Status (✅ accepted / ⚠️ overridden / ❌ rejected)

The sintetizador (step 4) is then asked to aggregate this into a
table in `04-clasificacion.md` (section `## Parameter validation
report`).

**Validation strategy:**

1. **Per-proposal report** — the agent itself logs declared vs
   observed parameters in its output.
2. **Baseline-cohort cross-check** — `propuesta-minimax-baseline-{01..15}`
   share identical declared parameters (T=0.7). Their outputs should
   cluster tightly on identical prompts, while `propuesta-minimax-T15`
   (extreme temperature) diverges from the cluster. If baselines
   diverge as much as T15, MiniMax is ignoring the parameter.
3. **Sintetizador table** — `04-clasificacion.md` aggregates the
   per-proposal reports and ranks proposals by their parameter
   profile.

### Known parameter limitations (per Anthropic spec)

- `temperature` range: 0.0 to 1.0 per Anthropic; `T15` (1.5) is
  out-of-spec. MiniMax behavior on out-of-spec values is unknown —
  the experiment will reveal whether MiniMax clamps, errors, or
  accepts.
- `top_p` range: 0.0 to 1.0; valid for all our values.
- `top_k` range: positive integer; Anthropic-specific. MiniMax
  behavior unknown.

## 11. v1.3 Grupo B variants — priority-injection pattern

The v1.3 roster adds 8 new Grupo B variants that follow the
**priority-injection pattern** documented in v1.2.1:

- The agent's system prompt has a `⚠️ ROLE OVERRIDE` heading as the
  **very first content after the frontmatter**.
- The directive is emphatic and explicit: "MUST prioritise", "this
  directive wins", applied to "every step you take", "the lens
  through which every section is produced".
- Each variant targets a specific quality axis:

| Variant | Quality axis | Concrete requirement (from override) |
|---|---|---|
| `creative` | Creativity | Explore unconventional architectures; reject the obvious choice if boring; risk unusual dependencies; reward novelty over safety |
| `security-first` | Security | STRIDE threat model in §2; OWASP Top 10 applicability in §6; `deny.toml` policy; security-first decision rationale per choice |
| `minimal` | Simplicity | Single direct dependency where possible; stdlib-first; reject over-engineering; minimum viable solution |
| `testable` | Test coverage | Every external interface has a concrete test inline; test framework choice stated; runner invocation documented; expected output asserted |
| `maintainable` | Code readability | Docstrings on every public fn with usage examples; boring documented libraries preferred; explicit-over-clever; English identifiers; design rationale inline |
| `a11y` | Accessibility | AT-SPI/UI Automation/NSAccessibility contracts; WCAG 2.2 AA; keyboard-only navigation; screen-reader verification commands |
| `errors` | Error handling | `Result<T,E>` + `thiserror`; `#![deny(clippy::unwrap_used, clippy::expect_used)]`; error-path unit tests; `# Errors` rustdoc on every public fn |
| `portable` | Cross-platform portability | `cargo check --target` matrix on Linux + macOS + Windows; `#[cfg(target_os)]` discipline; CI matrix; pure-Rust deps preferred |
| `i18n` | Internationalization | Fluent/gettext catalogs; ICU4X formatters; RTL locale support; no hardcoded user-visible strings |
| `rustdoc` | Documentation completeness | `#![deny(missing_docs)]`; `# Examples` doctest on every public fn; `cargo test --doc`; `cargo doc --no-deps` |
| `observability` | Structured tracing + metrics | `tracing` not `println!`; JSON logs in production; `metrics` + Prometheus exporter; span hierarchy with trace_id |
| `ci-github` | GitHub Actions CI | stable+MSRV+nightly × Linux+macOS+Windows matrix; `cargo deny`, `cargo audit`, `cargo llvm-cov`; dependabot.yml; branch protection |
| `cd-releases` | GitHub Releases distribution | `cargo-dist`; AppImage/.deb/.rpm/.dmg/.msi; cosign signing; SBOM; `release-plz` semver |

Together with the 4 existing Grupo B (creative, security-first,
minimal, testable) and the v1.3.1-restored `maintainable`, the v1.3
Grupo B roster covers **13 orthogonal quality axes**. The evaluator
(step 3) scores each proposal against all 5 base axes (TQ, CO, AP, SE,
IN); the Grupo B variants are expected to score highest on the axis
they target, providing within-cohort signal on which quality dimension
matters most for a given prompt.

## 12. Per-subagent work directory convention

### Why this exists

Before v1.3.x, propuesta and validador subagents did their
empirical work (cargo scaffolds, downloaded dependencies, compiled
binaries) wherever they imagined. In the v5 experiment
(`docs/research/experiments/2026-07-13-rust-gui-popup-v5.md` §9) the
artifacts ended up scattered across the workspace:

- `/tmp/opencode-moa-v5-test/rust-gui-popup/` — winner's 53 MB binary
- `/tmp/opencode-moa-v5-test/iced-test/` — mimo's iced verification
- `/tmp/opencode-moa-v5-test/gtk4-overlay-test/` — gtk4-layer-shell verification

Cleaning up a run meant `find /tmp -name 'opencode-moa-*' -prune`.
The convention below fixes this.

### Per-subagent directory tree (v1.6)

Each run creates **one root directory per id**, `$WORKSPACE/{id}/`,
with one folder per subagent. Every subagent folder has the same
triplet:

```
$WORKSPACE/{id}/{subagent}/
├── proposal/   ← final reports (.md)
├── work/       ← empirical scratch space
└── log/        ← bash session log(s)
```

There are two kinds of subagent folders:

1. **`orquestador/`** — owns ALL meta-step outputs (03–10) and the
   shared `validador` / `sintetizador` scratch. Step-prefix names
   (e.g. `02-validacion-{agente}/`, `05-propuesta-integrada/`) live
   directly under `orquestador/work/` and `orquestador/log/`.
2. **{agente}/`** (literal name without `.md`, one per
   `agentes_a_competir` entry) — owns the propuesta's own outputs
   (01, 02 if validation enabled, 05 if `self_improve`, 06 if
   `self_improve` + validation).

### Naming rule

The proposal/work/log names use the same step-prefix as in v1.5.
The mapping is:

| Step | Output `.md` | Owner folder | Work dir | Log file |
|---|---|---|---|---|
| 1 | `01-propuesta-{agente}.md` | `{id}/{agente}/proposal/` | `{id}/{agente}/work/01-{agente}/` | `{id}/{agente}/log/01-{agente}.log` |
| 2 | `02-validacion-{agente}.md` | `{id}/{agente}/proposal/` | `{id}/orquestador/work/02-validacion-{agente}/` | `{id}/orquestador/log/02-validacion-{agente}.log` |
| 3 | `03-calificacion-evaluador.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/03-calificacion-evaluador/` | `{id}/orquestador/log/03-calificacion-evaluador.log` |
| 4 | `04-clasificacion.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/04-clasificacion/` | `{id}/orquestador/log/04-clasificacion.log` |
| 5 (`sintesis_central`) | `05-propuesta-integrada.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/05-propuesta-integrada/` | `{id}/orquestador/log/05-propuesta-integrada.log` |
| 5 (`self_improve`) | `05-mejorada-{agente}.md` | `{id}/{agente}/proposal/` | `{id}/{agente}/work/05-mejorada-{agente}/` | `{id}/{agente}/log/05-mejorada-{agente}.log` |
| 6 (`sintesis_central`) | `06-validacion-integrada.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/06-validacion-integrada/` | `{id}/orquestador/log/06-validacion-integrada.log` |
| 6 (`self_improve`) | `06-validacion-{agente}.md` | `{id}/{agente}/proposal/` | `{id}/orquestador/work/06-validacion-{agente}/` | `{id}/orquestador/log/06-validacion-{agente}.log` |
| 7 | `07-calificacion-final.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/07-calificacion-final/` | `{id}/orquestador/log/07-calificacion-final.log` |
| 8 | `08-ganador.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/08-ganador/` | `{id}/orquestador/log/08-ganador.log` |
| 9 | `09-sumario.md` | `{id}/orquestador/proposal/` | (none — orchestrator writes directly) | (none) |
| 10 (`sintesis_final`) | `10-sintesis-cross-iter.md` | `{id}/orquestador/proposal/` | `{id}/orquestador/work/10-sintesis-cross-iter/` | `{id}/orquestador/log/10-sintesis-cross-iter.log` |

### Worked example

For the v6 prompt with `id = fib-rust-cli`, the v1.6 layout would be:

```
fib-rust-cli/
├── orquestador/
│   ├── work/
│   │   ├── 02-validacion-propuesta-minimax-baseline-01/   ← validador's step-2 scratch
│   │   ├── 02-validacion-propuesta-minimax-baseline-02/
│   │   ├── 02-validacion-propuesta-minimax-baseline-03/
│   │   ├── 02-validacion-propuesta-minimax-baseline-04/
│   │   ├── 02-validacion-propuesta-minimax-baseline-05/
│   │   ├── 02-validacion-propuesta-minimax-baseline-06/
│   │   ├── 05-propuesta-integrada/                        ← sintetizador's step-5 scratch
│   │   ├── 06-validacion-integrada/                       ← validador's step-6 scratch
│   │   └── 03-04-07-08-10/                                ← usually empty
│   ├── log/
│   │   ├── 02-validacion-*.log
│   │   ├── 05-propuesta-integrada.log
│   │   ├── 06-validacion-integrada.log
│   │   └── 03-04-07-08-10.log                              ← usually empty
│   └── proposal/
│       ├── 03-calificacion-evaluador.md
│       ├── 04-clasificacion.md
│       ├── 05-propuesta-integrada.md                       (sintesis_central)
│       ├── 06-validacion-integrada.md
│       ├── 07-calificacion-final.md
│       ├── 08-ganador.md
│       ├── 09-sumario.md
│       └── 10-sintesis-cross-iter.md                       (sintesis_final)
├── propuesta-minimax-baseline-01/
│   ├── work/01-propuesta-minimax-baseline-01/
│   ├── log/01-propuesta-minimax-baseline-01.log
│   └── proposal/
│       ├── 01-propuesta-minimax-baseline-01.md
│       └── 02-validacion-propuesta-minimax-baseline-01.md
├── propuesta-minimax-baseline-02/
│   └── ...
└── ... (one folder per agent in agentes_a_competir)
```

### How it's wired

1. `orquestador.md` step 0 creates the entire `$WORKSPACE/{id}/`
   tree with `mkdir -p` (or `rm -rf`s it under `--force`).
2. Each `task()` call in steps 1, 2, 5, and 6 includes a
   `=== WORK DIRECTORY ===` block with the absolute path so the
   subagent knows where to write.
3. Steps 3, 4, 7, 8, 9, 10 are pure reasoning — their work dirs
   are created but typically stay empty. We still create them so
   the pattern is uniform and future agents have a guaranteed
   scratch location.
4. Every agent's system prompt has a "## Work directory" section
   near the top (after the ROLE OVERRIDE in Grupo B variants)
   documenting the convention.

### How to add a new step or new subagent

1. Pick the step number and decide whether it can do empirical
   work. If yes, add a row to the table above.
2. Update `orquestador.md` step 0 to create the new work dir and
   log file (if the new step follows the pattern).
3. Update the corresponding `task()` prompt template to include
   the `=== WORK DIRECTORY ===` block with the new paths.
4. Add a "## Work directory" section to the new agent's system
   prompt.

### Why one folder per subagent (instead of three siblings like v1.5)?

Three reasons:

1. **Per-subagent isolation**: each subagent has its own folder
   so two concurrent `propuesta-X` and `propuesta-Y` builds cannot
   collide (they did in v5 — see the 4 gtk4 0.10 agents). With
   v1.6 the isolation is even cleaner: `{id}/{agente}/work/` is
   bounded to that single agent, and the shared `validador`
   scratch is contained in `orquestador/work/` instead of being
   split across many step-prefix subdirs under `work/{id}/`.
2. **Easy cleanup**: `rm -rf {id}/` cleans the entire run in one
   shot, no `find /tmp -name 'opencode-moa-*'` hunting. Single
   `--force` flag does it; no need to `rm -rf` three sibling
   directories.
3. **Run-level scoping**: subsequent runs' work never bleeds into
   the current run. The historical evidence in
   `{id}/{agente}/work/01-{agente}/` stays attached to that run
   even after the next one starts. Cleanup is now trivial because
   the entire `{id}/` namespace is owned by one run.

### Why does the validador live under `orquestador/`?

The validador is a single subagent invoked N times (once per
propuesta in step 2, once per candidate in step 6). It has no
identity of its own as a "candidate owner" — it merely validates
other agents' work. Putting its scratch under `orquestador/`
reflects this: the orquestador owns the validation phase. The
validador's **output .md**, however, lands in the **candidate's**
`proposal/` folder (so each agent's folder is self-contained: the
agent owns both its proposal and its validation report).

### Disk budget

Currently no size cap. The v5 gtk4 winner was 53 MB, mimo's iced
scaffold was ~80 MB with `target/`. A degenerate loop (cargo build
in a hot feedback loop) could fill the disk — tracked as a
follow-up in `ROADMAP.md` §"v1.3.x additions shipped". v1.6 does
NOT change the per-run disk footprint materially; it only
rearranges where things live.

### Backward compatibility

The v1.6 layout applies to runs started after the change. Existing
runs in `out/`, `work/`, `logs/` (the v1.5 layout) are untouched;
the historical bitácoras
(`docs/research/experiments/2026-07-13-*.md` and later) still
reference the old `/tmp/opencode-moa-v*-test/{project}/` paths as
historical evidence of the pre-v1.6 behavior. There is no
auto-migration script; users who want to inspect a v1.5 run keep
the old tree as-is.

---

*Last updated:* 2026-07-18 (v1.6 — directory layout restructured: `out/{id}/`, `work/{id}/`, `logs/{id}/` collapsed into `{id}/{subagent}/{proposal,work,log}/`. No semantic changes; same step numbers and naming rules. The orquestador owns the meta-step outputs (03-10) and the shared validador/sintetizador scratch; each `{agente}/` folder is self-contained.).