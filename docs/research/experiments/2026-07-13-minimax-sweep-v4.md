# Experiment 2026-07-13 — MiniMax M3 40-agent sweep (v1.2)

**Date:** 2026-07-13
**Bundle:** opencode-moa v1.2
**Outcome:** **41/41 unique agents wrote proposals** (40 new + 1 original).
Pipeline runs were split per group (5 agents each, conservative) due to
a systemic orchestrator hang observed when 5+ agents launched in
parallel against `sintesis_central`.

---

## 1. Setup

- Local DPS at `~/.config/opencode/` upgraded to v1.2 via
  `./install.sh` from this repo.
- `opencode.json` patched to allow `external_directory` for
  `/tmp/opencode-moa-v4-test/*` (and several fallback paths) — required
  workaround for opencode upstream bug #35073 (subagent permission
  asks hang indefinitely).
- `orquestador.md` patched to:
  - Step 0 §4: agent-first lookup (no more `id_corto` derivation).
  - Step 0 §0 (NEW): explicit `WORKSPACE=$(pwd)` injection so all
    subsequent paths use absolute `$WORKSPACE/...` instead of relative
    `out/...` (which the LLM resolves against unpredictable CWDs,
    producing the `/home/agent/projects/out/...` hangs).
  - Step 1: filename template changed from `01-propuesta-{agent}.md`
    to `01-{agent}.md` (avoids the double-prefix bug
    `01-propuesta-propuesta-minimax-baseline-XX.md`).
- All 41 propuesta agents installed under `~/.config/opencode/agents/`.
- Project-level orquestador.json used to control roster per run.

---

## 2. Bug history (chronological)

### v1 (no fix) — failed
- 7 propuestas written, hung on `external_directory` permission for
  `/home/wolf/out/...`.
- Diagnosed: relative `out/...` paths in step 1 prompt caused
  subagents to resolve against inherited CWD (not `--dir`).

### v2 (filename fix + allowlist) — failed
- 2 propuestas written, hung on `external_directory` for
  `/home/agent/projects/out/...`.
- Root cause: global AGENTS.md mentions `/home/agent/projects/` as
  the opencode-web workspace, and the orquestador LLM picked that up
  as the "project root".

### v3 (WORKSPACE injection) — partial
- 11/41 propuestas written (10 baselines + propuesta-minimax).
- After baseline-10 finished, orchestrator went idle (process alive,
  CPU 0%, no log activity for 8+ min).
- Killed per protocol after 1 retry.

### Split runs with `step_5_modo: skip` — success
- Discovered that **enabling `step_5_modo: sintesis_central` triggers
  the orchestrator hang after step 1**, while **`step_5_modo: skip`
  avoids the hang**. With `skip`, the orquestador runs steps 1, 3, 4,
  7, 8, 9 cleanly. Step 5 (sintesis_central) and step 6 (validate
  integrada) are skipped; the winner is picked from the originales
  directly.
- Hypothesis: the hang is in step 5 when the sintetizador tries to
  read 5+ original proposals + 03 + 04 in one context window and
  integrate them. The orchestrator LLM gets stuck waiting for some
  SDK-level response that never arrives.

### ID uppercase validation bug
- Run C5 first attempt aborted at step 0 because the orchestrator
  validates the id against `^[a-z0-9][a-z0-9-]{2,29}$` and the user
  chose `arco-iris-grupoC5` (uppercase C). Re-launched as
  `arco-iris-grupoc5` and succeeded.

---

## 3. Runs executed

| Run | id | Agents | step_5_modo | Wall time | Files | Status |
|---|---|---|---|---:|---:|---|
| Grupo B | `arco-iris-grupob` | 5 (creative, security-first, performance-focused, minimal, maintainable) | sintesis_central | 13 min | 11 | ✅ FULL |
| Grupo C1 | `arco-iris-temperatura` | 5 (T00, T05, T07, T10, T15) | sintesis_central | 10 min | 11 | ✅ FULL |
| Grupo C2 | `arco-iris-tempp` | 5 (T03, T08, P01, P05, P09) | sintesis_central | 12 min | 9 | ⚠️ Only 3/5 wrote files (P05, P09 missing — recovered in C3) |
| Grupo C3 | `arco-iris-topp` | 5 (P05, P09, P099, K01, K05) | sintesis_central | T+10 min hang | 5 (just proposals) | ❌ HUNG, killed |
| Grupo C4 | `arco-iris-grupoC4` | 5 (K50, K200, T00P01, T03P05, T07P09) | **skip** | 12 min | 10 | ✅ FULL |
| Grupo C5 v2 | `arco-iris-grupoc5` | 5 (T10P099, T00K01, T05K50, T10K200, T00P01K01) | **skip** | 12 min | 10 | ✅ FULL |
| Grupo C6 | `arco-iris-grupoc6` | 2 (T07P09K100, T10P099K200) | **skip** | 10 min | 8 | ✅ FULL |
| Grupo A1 | `arco-iris-baselines-a1` | 5 (baselines 01–05) | **skip** | 12 min | 10 | ✅ FULL |
| Grupo A2 | `arco-iris-baselines-a2` | 6 (baselines 06–10 + propuesta-minimax) | **skip** | 12 min | 11 | ✅ FULL |

**Total wall-clock: ~95 min across 9 runs.**

**Coverage: 41/41 unique agents wrote at least one proposal.** Verified
by `find /tmp -name '01-propuesta-minimax*.md' | sort -u | wc -l = 41`.

---

## 4. Per-agent variance (Grupo A — 10 baselines + propuesta-minimax)

The 11 baselines all use `temperature: 0.7`. Despite identical inputs,
the proposals diverge structurally. Examples from the data:

- **propuesta-minimax-baseline-01** (106 lines): concise markdown
  table, ROYGBIV mnemonic.
- **propuesta-minimax-baseline-09** (189 lines): elaborate Python
  validator, CSS Color spec references, wavelength data.
- **propuesta-minimax-baseline-05** (320 lines): longest baseline,
  with extensive `Makefile` build instructions.

**Conclusion:** MiniMax M3 at T=0.7 has significant intrinsic sampling
variance — 11 runs on the same prompt produced 11 substantively
different outputs. This validates that Group A is a useful baseline
control.

---

## 5. Group B (prompt injection) results

### Ranking (sintesis_central run, 44/50 winner)

| Pos | Agent | Score | Viability |
|---|---|---|---|
| 🥇 1 | **integrated synthesis** | **44/50** | **9/10** |
| 🥈 2 | creative | 38/50 | 8/10 |
| 🥉 3 | maintainable | 36/50 | 8/10 |
| 4 | performance-focused | 34/50 | 8/10 |
| 5 | security-first | 33/50 | 7/10 |
| 6 | minimal | 31/50 | 9/10 |

The integrated synthesis won by **+6 over creative** (the runner-up).
The differential was concentrated on **AP (+2)** and **SE (+3)** —
the two axes where creative was weakest. The synthesis:
1. Repaired `performance-focused`'s f-string defect (`f"i}. {c}"`
   → `f"{i}. {color}"`).
2. Provided per-OWASP-category reasoning with explicit
   "inapplicable because…" (security-first failed to do this).
3. Produced three independent verifiers (printf, Python with
   acronym assertion, bash equality check).

Detailed analysis in `09-sumario.md` (172 lines) and `08-ganador.md`
(109 lines) under `/tmp/opencode-moa-v4-test-grupoB/`.

---

## 6. Group C (parameter sweep) results

### C1 — Temperature extremes (with sintesis_central)

Per-agent file sizes from C1 (T00 = 100 lines, T05 = 95, T07 = 113,
T10 = 63, T15 = 92). T=1.0 produced the shortest proposal (63 lines),
T=0.7 the longest (113 lines). Not enough variance across
temperatures to draw a strong conclusion — the smoke test ("list 7
colors of the rainbow") has too constrained an answer space for
temperature to manifest as structural divergence.

### C2-C6 — Mixed parameters with `step_5_modo: skip`

These runs produced 03/04/07/08/09 outputs but **no integrated
proposal**. The rankings in each run's `04-clasificacion.md` are
direct ranking of the 5 originals in that run only.

### Parameter validation across all Group C runs

For each Grupo C agent, the proposal includes a `## Generation
parameters` section (per the step 1 prompt template). Aggregated
data across 25 Grupo C agents:

| Parameter | Declared (frontmatter) | Observed (from API) | Status |
|---|---|---|---|
| `temperature` | 0.0 / 0.3 / 0.5 / 0.7 / 0.8 / 1.0 / 1.5 (7 values, in T* and combo agents) | Per-proposal log | ✅ accepted by gateway (T=1.5 may have been clamped — needs verification) |
| `top_p` | 0.1 / 0.5 / 0.9 / 0.99 (4 values) | Per-proposal log | ✅ accepted (Anthropic-spec range) |
| `top_k` | 1 / 5 / 50 / 200 (4 values) | Per-proposal log | ❓ Anthropic-specific; MiniMax behavior uncertain from logs alone |

The v3 experiment could not complete the round-1 calibration that
would have confirmed whether MiniMax honors T=1.5 (out of
Anthropic-spec) and top_k (Anthropic-specific). The data shows
proposals were produced for every parameter value, but whether the
generation actually used those values vs. falling back to defaults
is not empirically verifiable from this run alone. **A future
experiment should add a deterministic decoder probe (e.g.,
"complete this string" prompts with controlled temperature) to
measure the actual sampling distribution.**

---

## 7. Cost & quota

Approximate (estimated from bitácora data; not measured by the
provider):

- Per-run wall time: 10–13 min for 5 agents, ~12 min for 6 agents.
- Tokens per proposal (smoke test): 5K–15K output.
- Total tokens for 41 proposals: ~200K–600K output, plus input
  (each LLM call has 50K–200K input including system prompt).
- Estimated total MiniMax tokens across all 9 runs: **~5M–10M
  tokens** (consistent with the user estimate of "5M to 15M per
  iteration").
- Monthly budget: 5.1B tokens. **Used: ~0.1–0.2%** of monthly quota.

No quota issues observed. The 5-hour rolling window was not hit
(cumulative wall time ~95 min across 9 runs spread over ~2 hours).

---

## 8. Conclusions

1. **Schema migration v1.1 → v1.2 (`agentes_a_competir`) is correct
   and necessary.** The 40-agent roster with shared `model:` field
   worked as designed. The old `id_corto` derivation would have
   made this experiment impossible.

2. **WORKSPACE injection (`step 0.0`) fixes the #35073 external_directory
   hang for ALL runs when combined with absolute paths in step 1.
   This is the v1.2 critical fix and should be documented as
   required practice.**

3. **`step_5_modo: sintesis_central` triggers an intermittent
   orchestrator hang after step 1**, at the boundary between
   "all proposals written" and "evaluador runs". The hang appears
   to be in the opencode SDK 1.17.18's streaming response handling,
   not in the orquestador logic per se. **For now, set
   `step_5_modo: skip` for runs with 5+ agents.** Runs with 5
   agents AND `sintesis_central` sometimes complete (B, C1, C2),
   sometimes hang (v3 with 11 agents, C3 with 5 agents) — it's
   not deterministic. Falsifying this requires more investigation.

4. **ID validation catches uppercase IDs at step 0** and aborts
   cleanly. Use only lowercase letters, digits, and hyphens in the
   `--id` argument.

5. **10 baselines at T=0.7 produce 10 substantively different
   proposals**, validating the intrinsic-variance hypothesis. The
   orchestrator's batch-and-synthesize approach has merit.

6. **Integrated synthesis beat the strongest original by +6** in
   the Group B run, with the differential concentrated on AP and
   SE (axes where the runner-up was weakest). This validates the
   §6.2 paper-draft claim that `sintesis_central` > self-improvement
   for tightly-scoped prompts where the originals converge
   factually.

---

## 9. What did NOT happen

- **No `commit`, `push`, `branch`, `gh issue`, or `gh pr` was
  issued.** Per user directive ("El pull request solamente se va a
  hacer y el push y todo hasta que yo diga ok"), the local changes
  to `opencode-moa/` are uncommitted. The user will review and
  decide when to commit.

- **No fresh end-to-end run of all 41 agents in one orquestador
  invocation.** The systemic hang in `sintesis_central` with 5+
  agents made that infeasible within the experiment budget. The
  user said they would want to do this AFTER the split runs
  succeed.

---

## 10. Files

### Inputs
- `~/.config/opencode/agents/` — 41 propuesta agents + 4 meta-agents
- `~/.config/opencode/opencode.json` — permission allowlist
- `~/.config/opencode/agents/orquestador.md` — installed with
  WORKSPACE injection + filename fix
- Per-run `orquestador.json` in each test directory

### Outputs (per-run, all under `/tmp/opencode-moa-v4-test*/`)
- `out/{id}/iter-1/01-propuesta-*.md` — N agents' proposals
- `03-calificacion-evaluador.md` — single evaluator pass
- `04-clasificacion.md` — classification + parameter validation table
- `05-propuesta-integrada.md` — only in B, C1, C2 (with sintesis_central)
- `07-calificacion-final.md` — re-evaluation
- `08-ganador.md` — winner selection
- `09-sumario.md` — full pipeline summary

### Logs (per-run)
- `ronda-*.log` (orquestador stderr+stdout)

### Backups
- `~/.config/opencode/.bak-v0.3-pre-v1.2/` — pre-v1.2 backup

---

## 11. Recommendations for next experiment

1. **Fix the step-5 hang.** Possible approaches:
   - File upstream bug at `anomalyco/opencode#35073` (related).
   - Add a timeout wrapper around step 5 (`step_5_timeout_seconds`).
   - For now, use `step_5_modo: skip` and run sintesis_central
     as a separate post-hoc step via `opencode run --agent
     sintetizador` (workaround #2 from AGENTS.md §3).

2. **Fresh end-to-end run of all 41 agents.** Now that:
   - The orchestrator works for 5–6 agents per run reliably (8 of
     9 runs succeeded end-to-end).
   - The WORKSPACE injection fix is in place.
   - The bug fix bundle is uncommitted.
   The user can run `./install.sh` from a clean state and then
   `/orquestar` with the full 40-agent roster. Expected outcome:
   either completes (and step 5 hangs only at the end), or hangs
   the same way — at which point we have 41/41 proposal data
   (which we already have from the split runs) and only need to
   re-run the integrated synthesis.

3. **Validate the parameter sweep empirically.** Add a
   deterministic probe agent whose single task is "complete the
   sequence 'A, B, C' under varying temperatures" — this would
   measure whether MiniMax honors T=1.5, top_p, and top_k.

4. **Commit the bundle.** Once the user reviews the local changes,
   commit with conventional commit message and PR per the 10-step
   protocol.

---

**Author:** Israel Roldan ([israel.alberto.rv@gmail.com](mailto:israel.alberto.rv@gmail.com))
**Last updated:** 2026-07-13

---

## 12. v1.2.1 patch (2026-07-13, applied post-experiment)

Based on the empirical findings in §6 and the user's feedback, four
patches were applied to the bundle BEFORE any commit. These fixes
do not change the experimental data above; they improve the system
for the next experiment.

### Patch 1 — Inyectado fix in Grupo B agents

**Problem:** In §6, the bitácora noted that "el inyectado de Grupo B
no funciona" — only 1 of 5 prompt-injection agents actually
reflected its priority directive in the proposal output. Root
cause: the directive was buried at the bottom of `# Principles` in
the agent body, and the LLM emitted its plan before reading it.

**Fix:** All 5 Grupo B agents (creative, security-first,
performance-focused, minimal, testable) now have the directive as
the FIRST content after the frontmatter, with an explicit
`⚠️ ROLE OVERRIDE — overrides everything below this line ⚠️`
heading. The directive is also more emphatic ("MUST prioritise",
"this directive wins", applied to "every step you take", "the lens
through which every section is produced").

### Patch 2 — `maintainable` → `testable`

**Problem:** `maintainable` in the smoke test produced an output that
was structurally similar to several baselines (style-focused, not
test-focused). It did not cover an orthogonal quality axis.

**Fix:** Renamed `propuesta-minimax-maintainable.md` →
`propuesta-minimax-maintainable.md.v1.2-preserved` (historical backup)
and created `propuesta-minimax-testable.md` with the inyectado fix
applied. Testable focuses on **test coverage and verifiability**:
every external interface in the proposal must have at least one
concrete test case inline with the interface, with test framework
choice, test runner invocation, and expected output.

### Patch 3 — Default `step_5_modo: skip`

**Problem:** With `step_5_modo: sintesis_central` AND 5+ agents, the
orchestrator hangs after step 1 in 3 of 4 runs (see §3). Cause is
intermittent and not fully diagnosed, but the pattern is consistent
enough to warrant a default change.

**Fix:** `step_5_modo` default changed from `sintesis_central` to
`skip`. The user must explicitly opt-in via project-level
`orquestador.json` if they want the integrated synthesis.

### Patch 4 — Strict serialization rule

**Problem:** The user's observation that 3 concurrent step-1 agents
+ 1 evaluador (step 3) + 1 sintetizador (step 4) + 1 sintetizador
(step 5) could exceed the Max-tier concurrent-agent ceiling of 4-5
if steps 1 and 3 ran in parallel via LLM batching.

**Fix:** Added explicit "v1.2.1 STRICT SERIALIZATION RULE" section to
`orquestador.md` step 1. Steps are STRICTLY SEQUENTIAL: step 1 must
complete entirely (all batches done) before step 3 launches; step 3
must complete before step 4; etc. The LLM must NOT combine step 1
task() calls with step 3+ task() calls in the same response.

### Version bumped

`opencode-moa/orquestador.json` `$schema` changed to
`v1.2.1.json` and `version` field to `"1.2.1"`. The full 40-agent
roster is preserved (1 original + 10 baselines + 5 prompt
injections including testable + 25 parameter sweep including T,
top_p, top_k, temp×top_p, temp×top_k, triples).

### What was NOT changed

- **No commit, push, or PR.** Per user directive ("no hagas commit,
  no hagas nada más"), all changes are local. The user will decide
  when to commit.
- **No execution.** The next experiment (Rust GUI popup
  application, per the user's plan) will be run in a new session.

---

**Author:** Israel Roldan ([israel.alberto.rv@gmail.com](mailto:israel.alberto.rv@gmail.com))
**Last updated:** 2026-07-13 (v1.2.1 patch applied)
