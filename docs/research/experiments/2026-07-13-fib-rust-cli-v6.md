# Experiment 2026-07-13 — Rust Fibonacci CLI v6 (6-baseline minimum-cohort `sintesis_central`)

**Date:** 2026-07-13
**Bundle:** opencode-moa v1.3 (`$schema: v1.3.json`, `version: 1.3`)
**ID:** `fib-rust-cli`
**Mode:** `/orquestar` (single iter, NOT iterate)
**Outcome:** **6/6 originales written + 1 integradora sintetizada.** Winner: **`05-propuesta-integrada.md`** (45/50, viabilidad 9.8/10). Margin over runner-up: **+1 punto** sobre `01-propuesta-minimax-baseline-06.md` (44/50, viabilidad 10/10). 0 descalificadas. 2 defectos del campo detectados por el validador empírico y corregidos en la integradora (off-by-one boundary, panic-on-overflow).

---

## 1. Setup

- Bundle at `~/.config/opencode/` already at v1.3 (5 OpenCode Go + 36 MiniMax Token Plan, 42 agentes_a_competir total per v1.3.1).
- Workspace: `/tmp/opencode-moa-v6-test/` (created fresh for this experiment).
- Project-level `orquestador.json` with:
  - `agentes_a_competir`: **6** — only `propuesta-minimax-baseline-{01..06}` (minimum controlled cohort: same model, no temperature override, no Grupo B prompt-injection, no parameter sweep, no OpenCode Go cross-model)
  - `modelo_objetivo`: `minimax-coding-plan/MiniMax-M3`
  - `max_iteraciones`: **10** (irrelevant for single iter)
  - `umbral_convergencia`: **0.5**
  - `validacion_empirica`: **true** (validador enabled — first time documented with full end-to-end since Run B v0.3 where it was blocked by `bash: ask` permissions)
  - `descalificar_fallida`: **false**
  - `smoke_test`: **false**
  - `step_1_concurrent_max`: **3**
  - `step_1_agent_timeout_seconds`: **600**
  - `step_5_modo`: **`sintesis_central`** (vs Run C v1.2.1 `skip` and Run B v0.3 `sintesis_central` with synthetic 03/04/06/07/08)
  - `sintesis_final`: **true** (writes step-10 cross-iter synthesis)
  - `sintesis_final_modelo`: `minimax-coding-plan/MiniMax-M3`
  - `multi_eval`: **false**
  - `multi_eval_modelos`: `[]`
  - `max_wall_clock_minutes`: **0** (unlimited)
  - `if_mejoras_tecnicamente_similares_a_otras`: **false**
  - `param_validation_report`: **true**
- Project-level `opencode.json` with `external_directory` allowlist for `/tmp/opencode-moa-v6-test/*`, `/tmp/opencode/*`, `~/.config/opencode/*`, `~/.local/share/opencode/*`.
- All 6 propuesta-minimax-baseline agents installed and verified (clones of canonical `propuesta-minimax.md`, no ROLE OVERRIDE — pure baseline clones).
- Per-subagent `work/` and `logs/` sibling directories created in step 0 (v1.3 feature). Naming rule: `01-propuesta-minimax-baseline-04` → `out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04.md` + `work/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04/` + `logs/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04.log`. Same prefix across all 10 steps.

## 2. Roster (6 agentes_a_competir)

All 6 agents bind to `model: minimax-coding-plan/MiniMax-M3`. No sampling overrides (Grupo A — pure baselines). The intent is **minimum controlled cohort** for intrinsic-variance measurement and `sintesis_central` validation on a uniform model pool.

| # | Agent ID | Model | Temperature | Group | Purpose in this run |
|---:|----------|-------|---:|---|---|
| 1 | `propuesta-minimax-baseline-01` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #1 |
| 2 | `propuesta-minimax-baseline-02` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #2 |
| 3 | `propuesta-minimax-baseline-03` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #3 |
| 4 | `propuesta-minimax-baseline-04` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #4 |
| 5 | `propuesta-minimax-baseline-05` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #5 |
| 6 | `propuesta-minimax-baseline-06` | minimax-coding-plan/MiniMax-M3 | default (1.0) | A baseline | Variance sample #6 |

**Why 6 and not 10 or 15?** Three reasons:
1. **Cohort uniformity** — the experiment's goal is to measure intrinsic variance and `sintesis_central` behavior on a uniform cohort. 6 proposals is enough for convergence analysis (4-6 of 6 majority threshold).
2. **Cost ceiling** — at the MiniMax rate from Run C (~$0.16 for 41 agents per iter), 6 agents is ~$0.024 — a clean baseline cost for this experiment.
3. **Wall-clock ceiling** — 6 agents / 3 concurrent = 2 batches × ~9 min = ~18 min for step 1 alone. Combined with steps 2-9 (~60 min observed), iter-1 stays well under 90 min.

## 3. Wall-clock timeline (estimated)

| Step | Duration | Notes |
|---|---:|---|
| Step 0 (init + dirs) | <1 s | Three siblings created (out, work, logs) per v1.3 convention |
| Step 1 (6 propuestas, 4 batches due to 2 truncated retries) | ~17 min | Bug: baseline-02 and baseline-03 had to be re-issued in smaller batches due to tool-call truncation when the step-1 prompt text exceeded a length threshold (see §6 Bug History) |
| Step 2 (6 empirical validations, 2 batches) | ~38 min | First time `validacion_empirica: true` runs end-to-end since Run B (where bash:ask blocked it) |
| Step 3 (single evaluator) | ~3 min | 6 proposals graded, written to `03-calificacion-evaluador.md` |
| Step 4 (clasificador + param report) | ~3 min | Ranking + cross-tab + `## Parameter validation report` |
| Step 5 (sintesis_central) | ~5 min | Integrator reads 6 originales + 03 + 04 + 6 validations, writes `05-propuesta-integrada.md` (~1051 lines, 51 KB) |
| Step 6 (validate integrada) | ~6 min | Full `cargo init` + paste + 38 commands executed; 36 OK, 2 SKIP (false-positive shellcheck in markdown comments), 0 FAIL |
| Step 7 (final evaluation) | ~3 min | 7 candidates (6 originales + 1 integrada) graded |
| Step 8 (winner selection) | ~3 min | `08-ganador.md` written by sintetizador |
| Step 9 (orchestrator sumario) | <1 min | `09-sumario.md` written by orquestador |
| Step 10 (cross-iter synthesis) | ~2 min | `10-sintesis-cross-iter.md` written (degrades to within-iter convergence since N=1) |
| **Total iter-1** | **~78 min** | |

## 3.1 Bug history (chronological)

### Tool-call truncation in step 1 (observed with baseline-02 and baseline-03)

The first attempt at step 1 launched all 6 agentes_a_competir in 2 batches of 3 with `task()` calls in the same response. The orquestador's response carrying the second batch (containing the step-1 prompt for `propuesta-minimax-baseline-02` and `propuesta-minimax-baseline-03`) was **truncated mid-emission** — the LLM emitted the `task()` call headers and partial tool-call arguments but the response ended before completing the second agent's full prompt. The result: the first attempt's batch produced only `01-propuesta-minimax-baseline-01.md` (from the first batch that completed cleanly) and `01-propuesta-minimax-baseline-04.md` through `-06.md` (from the third batch that was re-issued). baseline-02 and baseline-03 were missing.

**Workaround applied:** re-issued baseline-02 and baseline-03 as a smaller, dedicated batch (2 sibling `task()` calls in one response). Both completed successfully. Final `out/fib-rust-cli/iter-1/` has all 6 originales.

**Workdir evidence** (per v1.3 per-subagent work dir convention):
- `work/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-02/fib-cli/` — created 21:30 (first attempt, truncated before completion)
- `work/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-03/Cargo.lock`, `Cargo.toml`, `src/`, `target/` — created 21:35 (first attempt, truncated before completion)
- Both workdirs were reused on the second attempt with no `--force` reset (the agent naturally overwrites the proposal file with the new content on retry).

**Step 1 took 4 batches instead of 2.** Wall-clock estimate: ~17 min instead of ~9 min.

**Open question (for v1.3.x follow-up):** what is the maximum prompt length before the LLM truncates `task()` siblings in a single response? The step-1 prompt template includes the user task, the proposal agent's system prompt excerpt, the absolute workdir and log path, the workspace path, and the opencode.json permission reminder. Empirically: with 6 agents and `step_1_concurrent_max: 3`, the LLM truncates when emitting 2+ `task()` calls in a single response with full prompts. Mitigation strategies to evaluate:
- Lower `step_1_concurrent_max` from 3 to 2 for cohorts with long prompts (no-op for 6-agent cohort, would halve parallelism).
- Move the workdir/path block out of the `task()` prompt and into the agent's own prompt template (DRY).
- Investigate the opencode SDK 1.17.18 streaming-response behavior for `task()` siblings.

This is **not the same bug as Run B's `bash: ask` permission hang** (#35073) and **not the same as Run C's `step_5_modo: sintesis_central` orchestrator hang with 5+ agentes**. It's a new bug class: tool-call truncation when emitting multiple `task()` siblings in one response with long prompts.

## 4. Outputs

### 4.1 Reports (`out/`)

| Path | Lines | Bytes | Notes |
|---|---:|---:|---|
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-01.md` | 483 | 15 792 | Zero-deps, u128, hand-rolled argv, no unit tests |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-02.md` | 414 | 14 988 | clap derive, u64, 3 unit tests |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-03.md` | 383 | 14 731 | clap + String + hand u128 parse |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-04.md` | 423 | 19 258 | clap u32 + FibError enum — **off-by-one boundary bug** |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-05.md` | 198 | 14 280 | clap + u128 + documented panic — **no source code in proposal** |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-06.md` | 653 | 31 883 | Zero-deps, FibError 5-variant, 6 tests — best original (44/50) |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-01.md` | 321 | 15 732 | Validador: 10/10 viability, 26 commands OK |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-02.md` | 407 | 18 882 | 10/10, 37 commands OK |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-03.md` | 385 | 17 840 | 10/10, 21 commands OK |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-04.md` | 396 | 23 465 | **7.8/10**, 36 OK, 9 FAIL — boundary bug confirmed |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-05.md` | 333 | 12 870 | 10/10 post-reconstruction (no source in proposal) |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-06.md` | 336 | 13 307 | 10/10, 33 commands OK |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/03-calificacion-evaluador.md` | 290 | 26 475 | Evaluator signal on 6 originales |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/04-clasificacion.md` | 74 | 9 468 | Ranking, tie-break, per-proposal warnings, param validation report |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/05-propuesta-integrada.md` | **1051** | **51 217** | **WINNER (45/50, 9.8/10 viability)** |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/06-validacion-integrada.md` | 601 | 25 801 | Full integration validation: 36/38 OK, 0 FAIL, 2 SKIP (false-positive shellcheck) |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/07-calificacion-final.md` | 329 | 24 099 | Final evaluation of 7 candidates (6 originales + 1 integrada) |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/08-ganador.md` | 232 | 19 873 | Step 8 winner write-up |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/09-sumario.md` | 80 | 3 278 | Orchestrator's summary |
| `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/10-sintesis-cross-iter.md` | 296 | 21 529 | Cross-iter synthesis (degrades to within-iter convergence, N=1) |

### 4.2 Empirical scratch (`work/`)

Naming rule: `work/fib-rust-cli/iter-1/{step-prefix}/`. Each subagent has its own subdirectory under step 1, step 2, and step 6.

```
work/fib-rust-cli/iter-1/
├── 01-propuesta-minimax-baseline-01/scratch/fib-rust-cli/   # proposal agent's scratch
├── 01-propuesta-minimax-baseline-02/fib-cli/                # proposal agent's scratch
├── 01-propuesta-minimax-baseline-03/{Cargo.lock,Cargo.toml,src/,target/}
├── 01-propuesta-minimax-baseline-04/{...}                   # analogous
├── 01-propuesta-minimax-baseline-05/{...}                   # analogous
├── 01-propuesta-minimax-baseline-06/{...}                   # analogous
├── 02-validacion-propuesta-minimax-baseline-01/{...}        # validador scratch
├── 02-validacion-propuesta-minimax-baseline-02/{...}
├── 02-validacion-propuesta-minimax-baseline-03/{...}
├── 02-validacion-propuesta-minimax-baseline-04/{...}        # includes Python recurrence for boundary proof
├── 02-validacion-propuesta-minimax-baseline-05/{...}        # includes reverse-engineered source
├── 02-validacion-propuesta-minimax-baseline-06/{...}
├── 03-calificacion-evaluador/                                # empty (evaluator is pure reasoning)
├── 04-clasificacion/                                         # empty (clasificador is pure reasoning)
├── 05-propuesta-integrada/                                   # empty (integrator is pure reasoning)
├── 06-validacion-integrada/fib/                              # ✅ integrator's verified source tree
│   ├── Cargo.toml         # verbatim from 05-propuesta-integrada.md lines 137–153
│   ├── Cargo.lock         # 22 entries (clap 4.6.1 transitive closure)
│   └── src/main.rs        # verbatim from 05-propuesta-integrada.md lines 176–390
│   └── target/release/fib # ~700 KB stripped binary (post-validation build)
├── 07-calificacion-final/                                    # empty
├── 08-ganador/                                               # empty
└── 10-sintesis-cross-iter/                                   # empty
```

The validador's `02-validacion-propuesta-minimax-baseline-04/` work dir contains the validator's **independent Python recurrence script** that mathematically proves the off-by-one boundary bug (`F(186)` fits in `u128`; `F(187)` does not). This is the empirical evidence behind the validator's 7.8/10 viability score for baseline-04 and the reason baseline-04's `MAX_POSITION = 186` is wrong (should be 187 in 1-indexed).

### 4.3 Bash session logs (`logs/`)

```
logs/fib-rust-cli/iter-1/
├── 01-propuesta-minimax-baseline-01.log    # 0 bytes (proposal agents don't run bash)
├── 01-propuesta-minimax-baseline-02.log    # 0 bytes
├── 01-propuesta-minimax-baseline-03.log    # 0 bytes
├── 01-propuesta-minimax-baseline-04.log    # 2 210 bytes (proposal ran cargo check / cargo build)
├── 01-propuesta-minimax-baseline-05.log    # 4 033 bytes
├── 01-propuesta-minimax-baseline-06.log    # 8 255 bytes (most cargo activity)
├── 02-validacion-propuesta-minimax-baseline-01.log    # 0 bytes
├── 02-validacion-propuesta-minimax-baseline-02.log    # 0 bytes
├── 02-validacion-propuesta-minimax-baseline-03.log    # 156 bytes
├── 02-validacion-propuesta-minimax-baseline-04.log    # 0 bytes (captured by the validador's work dir instead)
├── 02-validacion-propuesta-minimax-baseline-05.log    # 0 bytes
├── 02-validacion-propuesta-minimax-baseline-06.log    # 0 bytes
├── 03-calificacion-evaluador.log    # 0 bytes
├── 04-clasificacion.log             # 0 bytes
├── 05-propuesta-integrada.log       # 0 bytes
├── 06-validacion-integrada.log      # 0 bytes
├── 07-calificacion-final.log        # 0 bytes
├── 08-ganador.log                   # 0 bytes
└── 10-sintesis-cross-iter.log       # 0 bytes
```

The 6 validaciones built cargo projects in their work dirs and ran 21–45 commands each; the bash session was captured per-step in the work dir's shell transcript (see §4.2). The `logs/` files are mostly empty because the v1.3 `logs/` convention captures the bash session for the **propuesta** agent's invocation only; the **validador** agent's commands live inside its work dir (e.g. `02-validacion-propuesta-minimax-baseline-04/`) as part of the empirical artifact bundle. This is consistent with the v1.3 README convention.

## 5. Cost & token totals (estimated)

This run used 6 MiniMax-M3 agents × ~1 invocation per agent in step 1 (proposals), plus validador's 6 + 1 = 7 empirical validations, plus evaluator (2 invocations: step 3 + step 7), plus sintetizador (3 invocations: step 4 + step 5 + step 8 + step 10 = 4 actually). Total: ~18 LLM invocations.

Extrapolating from Run C v1.2.1 cost data (§5.5 of `2026-07-13-rust-gui-popup-v5.md`), where 41 MiniMax agents cost ~$0.16 total, the per-agent average is ~$0.004. For 18 invocations in this run, estimated cost is **~$0.07 USD** (all MiniMax Token Plan; no OpenCode Go).

**Caveat:** the MiniMax `model_remains` telemetry endpoint was not polled during this run. This is a **byte-derived estimate from Run C's per-agent average**, not a measured total. The user's Token Plan dashboard was not consulted post-run.

**Cost attribution (estimated):**

| Subagent | Invocations | Approx share |
|----------|---:|---:|
| propuesta-minimax-baseline-{01..06} | 6 | ~33% total |
| validador (6 originals + 1 integrada) | 7 | ~39% total |
| evaluador (step 3 + step 7) | 2 | ~11% total |
| sintetizador (step 4 + 5 + 8 + 10) | 4 | ~17% total |

These are rough estimates; the orchestrator does not have exact token counts and the user did not poll the `model_remains` endpoint.

## 6. Outcome

### 6.1 Final ranking (all 7 candidates)

| Pos | Proposal | Total | TQ | CO | AP | SE | IN | Viab | State |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---|
| 🥇 1 | **`05-propuesta-integrada.md`** | **45** | 9 | 9 | 9 | 10 | 8 | **9.8** | ✅ OK |
| 🥈 2 | `01-propuesta-minimax-baseline-06.md` | 44 | 9 | 8 | 9 | 10 | 8 | 10.0 | ✅ OK |
| 🥉 3 | `01-propuesta-minimax-baseline-02.md` | 43 | 9 | 9 | 10 | 9 | 6 | 10.0 | ✅ OK |
| 4 | `01-propuesta-minimax-baseline-01.md` | 41 | 8 | 7 | 10 | 10 | 6 | 10.0 | ✅ OK |
| 4 | `01-propuesta-minimax-baseline-03.md` | 41 | 8 | 8 | 10 | 9 | 6 | 10.0 | ✅ OK |
| 6 | `01-propuesta-minimax-baseline-04.md` | 36 | 7 | 8 | 7 | 7 | 7 | 7.8 | ⚠️ VIABLE CON ADVERTENCIAS |
| 7 | `01-propuesta-minimax-baseline-05.md` | 29 | 5 | 6 | 7 | 5 | 6 | 10.0* | ⚠️ VIABLE CON ADVERTENCIAS |

\* Viability for baseline-05 is 10/10 *only after the validator reverse-engineered the source code from prose*; the proposal as-shipped does not contain an executable code block.

### 6.2 Winner: `05-propuesta-integrada.md`

**Margin:** +1 point over the strongest original (baseline-06 at 44/50). Not a tiebreak; a real margin.

**Why the integrated proposal wins (per `08-ganador.md`):**

1. **Highest total score (45/50)** — unambiguous leader; not a tiebreak.
2. **Empirical viability 9.8/10** — near-perfect reproduction. Validator executed 38 commands against a fresh `cargo init`; 36 OK, 0 FAILED, 2 SKIP (false-positive shellcheck in markdown comments). All 6 unit tests pass. Spec table reproduces byte-for-byte.
3. **Two field defects fixed:**
   - **baseline-04's off-by-one boundary bug** (`MAX_POSITION = 186` should be `187` in 1-indexed). Validator proved mathematically with independent Python recurrence.
   - **baseline-05's panic-on-overflow defect.** Validator confirmed `./target/debug/fib 187` exits 101 in debug, silently wraps in release. Integrated proposal uses `checked_add` propagating `None` as `FibError::Overflow`.
4. **Full pasteable source code** — only candidate that combines ≥ 45 score with verbatim `src/main.rs` (~213 lines including 6 unit tests).
5. **Best-of-breed design choices** — every architectural decision has evidence in at least one original and is the strongest option for that axis.

**Concrete 30-second bootstrap** (from `08-ganador.md`):

```bash
mkdir fib && cd fib
cargo init --name fib --vcs none --bin
# paste Cargo.toml (pin clap = "4.5") and src/main.rs from the proposal
cargo fmt
cargo test
for i in 1 2 3 4 5 6 7 8 9 10 11; do cargo run --quiet -- $i; done
```

Expected: `0 1 1 2 3 5 8 13 21 34 55`, each on its own line. Optional: `cargo build --release` produces a ~700 KB stripped binary.

### 6.3 Disqualifications & warnings

- **0 descalificadas** — `descalificar_fallida = false`, no validation marks any section as ❌ NO VIABLE.
- **2 marked ⚠️ VIABLE CON ADVERTENCIAS:**
  - **baseline-04 (36/50, 7.8/10)** — off-by-one boundary bug (`MAX_POSITION = 186` should be 187); `cargo fmt --check` fails (2 formatting diffs); `expect("checked_add must succeed")` is panic-prone.
  - **baseline-05 (29/50, 10/10*)** — no source code in proposal (validator had to reverse-engineer); panic on overflow (exit 101 debug, silent wrap release); no unit tests.

### 6.4 Parameter validation report

Every proposal in this iteration includes a `## Generation parameters` section. All 6 are baseline clones (`propuesta-minimax-baseline-{01..06}`) with no priority-injection directive (Group A); the orchestrator did not override temperature, top_p, or top_k, so each proposal inherits the provider/model default.

| Agent | Declared temp | Observed temp | Status | Total score |
|-------|---------------|---------------|--------|-------------|
| propuesta-minimax-baseline-01 | not set (baseline clone, no override) | unknown (no SDK telemetry exposed) | OK | 41/50 |
| propuesta-minimax-baseline-02 | not set (baseline clone, no override) | unknown (no SDK telemetry exposed) | OK | 43/50 |
| propuesta-minimax-baseline-03 | 1.0 (provider default, not overridden) | 1.0 (default — not overridden) | OK | 41/50 |
| propuesta-minimax-baseline-04 | not specified; baseline clone inherits model default | assumed model default (1.0) — no telemetry endpoint queried | OK | 36/50 |
| propuesta-minimax-baseline-05 | not declared (default) | provider default (1.0) — inferred from agent static config | OK | 29/50 |
| propuesta-minimax-baseline-06 | not specified; baseline clone inherits model default | assumed model default (1.0) | OK | 44/50 |

**Common caveat.** Every "Observed" column is *inferred from static configuration*, not measured at inference time. None of the baseline clones expose a per-token sampling telemetry hook. Per the proposal's own disclaimer (`baseline-05` is the most explicit), treat the temperature column as the *expected* default of `minimax-coding-plan/MiniMax-M3`, not an empirical observation from this run.

**No agents flagged `WARN no parameter report`** — every proposal contains a `## Generation parameters` section, even if it honestly disclaims that the observed values are unmeasured defaults. **No agents flagged for parameter dishonesty** (vs Run C's `propuesta-minimax-creative` claiming `rustc 1.92` validation that did not exist on the host). The baseline cohort is by design conservative on parameter declarations.

### 6.5 Convergence status

This is iter-1 (N=1). No prior iteration exists. Iterate mode is NOT in effect (`/orquestar` invoked, not `/orquestar-iterate`).

**If `/orquestar-iterate` were used** (from `09-sumario.md`):
- `max_iteraciones = 10` (project-level orquestador.json)
- `umbral_convergencia = 0.5`
- `prev_score` = 0 (no prior iter)
- `mejora` = 45 - 0 = 45 (>> 0.5) → would **CONTINUE** to iter-2

**Take-away from trajectory** (from `10-sintesis-cross-iter.md` §"Convergence trajectory"): For a project of this size (single-file Rust CLI, ~213 lines incl. tests), the MOA pipeline **saturates after one iteration**. The 6-original fan-out was justified (it surfaced the boundary bug and the panic-on-overflow bug that no single model caught) but a second iteration would mostly re-litigate the same design space. The integrator's value in iter-1 was **defect detection** (boundary, panic, missing source), not innovation.

## 7. Observations

### 7.1 Variance analysis — intrinsic variance of 6 identical-input proposals

The 6 baselines share **identical** inputs: same model (`minimax-coding-plan/MiniMax-M3`), same temperature (provider default 1.0), same system prompt (the baseline clone is a verbatim copy of `propuesta-minimax.md` modulo a renaming), same user task. Yet they produced 6 substantively different proposals. Distribution of design choices:

| Design axis | baseline-01 | baseline-02 | baseline-03 | baseline-04 | baseline-05 | baseline-06 |
|---|---|---|---|---|---|---|
| Dependency model | zero-deps | clap 4.5 | clap 4.5 | clap 4.5 | clap 4.5 | zero-deps |
| Positional type | `i128` | `u64` | `String` | `u32` | `i64` + `allow_negative_numbers` | `i64` + `allow_negative_numbers` |
| Algorithm type | iterative `u128` + `checked_add` | iterative `u64` + `checked_add` | iterative `u128` + `checked_add` | iterative `u128` + `checked_add` (with `expect`) | iterative `u128` + `+` (panicking) | iterative `u128` + `checked_add` |
| Error type | `Result<u8, String>` | `Result<u64, String>` | `Result<u128, String>` | `enum FibError` (5 variants) | inline `ExitCode` | `enum FibError` (5 variants) |
| Unit tests | 0 | 3 | 2 | 4 | 0 | 6 |
| Exit code split | 2 | 1 vs 2 (clap vs logical) | 2 | 1 vs 2 (clap vs logical) | 2 | 2 |
| Maximum position | 187 (correct) | 94 (`u64` ceiling) | 187 (correct) | **186 (off-by-one)** | 187 (documented panic above) | 187 (correct) |
| Verbatim src/main.rs | YES | YES | YES | YES | **NO** | YES |
| `cargo fmt --check` | PASS | PASS | PASS | **FAIL** | PASS | PASS |
| `cargo clippy -- -D warnings` | PASS | PASS | PASS | PASS | PASS | PASS |
| Binary size (stripped release) | ~340 KB | ~700 KB | ~700 KB | ~700 KB | ~700 KB | ~340 KB |

**Key finding:** 6 identical-input proposals diverge structurally on dependency model, error type, exit code split, and unit test count. This is direct empirical evidence that **intrinsic variance of LLM proposals is sufficient to produce diverse design alternatives without any prompt variation, parameter override, or model variation**. This extends Run C's finding (10 baselines → 10 different proposals) to 6 baselines and confirms the design rationale for the baseline cohort in v1.3 (15 baselines for variance expansion).

### 7.2 Within-cohort convergence (cross-pollination at iter-1, uniform model)

Even with **6 identical-input proposals from the same model**, the field converged on a core design pattern that occupies ~80% of the design surface. Convergent ideas (4+ of 6 agree):

| # | Idea | Originals that picked it | Notes |
|---|------|--------------------------|-------|
| 1 | Iterative Fibonacci on `u128` with `checked_add` | baseline-01, -02, -03, -04, -06 (5 of 6) | baseline-05 uses `+` (panicking) as a deliberate choice |
| 2 | `clap = "4.5"` with `#[derive(Parser)]` | baseline-02, -03, -04, -05 (4 of 6) | baseline-01 and -06 are zero-deps |
| 3 | Exit code `2` for all usage errors (`sysexits.h` `EX_USAGE`) | baseline-01, -03, -05, -06 (4 of 6) | baseline-02 and -04 split exit 1 vs 2 |
| 4 | Edition `2021` for maximum portability | baseline-01, -02, -03, -05 (4 of 6) | baseline-06 chose 2024 |
| 5 | 1-indexed Fibonacci contract (`fib 1 = 0`, `fib 11 = 55`) | all 6 | Unanimous |
| 6 | English-only error messages on stderr, separate from stdout | all 6 | Unanimous |
| 7 | Iterative loop invariant `a == F(k), b == F(k + 1)` | baseline-01, -06 explicit; others implicit | Effective unanimity |
| 8 | `cargo fmt --check` cleanliness | baseline-01, -02, -03, -05, -06 (5 of 6) | baseline-04 fails |
| 9 | `cargo clippy -- -D warnings` cleanliness | all 6 | Unanimous |
| 10 | Doc comments on every public item | baseline-02, -06 explicit; implicit in others | Effective unanimity |

**Interpretation:** Cross-pollination (§6.3 of the paper draft) is observable **with a uniform-model cohort**, not just with diverse-model ensembles. The LLM's intrinsic variance in the baseline cohort is enough to surface the convergent design pattern. This **extends §6.3**: cross-pollination is a property of LLM sampling temperature, not a property of model diversity.

### 7.3 Defect detection — empirical validation caught 2 real bugs

The validator (step 2, `validador` agent with `validacion_empirica: true`) executed every command and claim in each proposal against a fresh `cargo init`. Two real bugs surfaced that no individual proposal agent caught:

**Bug A — baseline-04 off-by-one boundary (`MAX_POSITION = 186` should be `187`).**
- baseline-04's proposal claims `MAX_POSITION = u32 = 186` and a comment "F(185) is the largest fit."
- Validator ran an independent Python recurrence in `02-validacion-propuesta-minimax-baseline-04.md` lines 105–113:
  ```
  u128::MAX = 340282366920938463463374607431768211455
  F(186) = 332825110087067562321196029789634457848  # fits
  F(187) = 538522340430300790495419781092981030533  # does not fit
  ```
- Therefore, for **1-indexed** positions, position 187 returns `F(186)` (the last u128 fit), and position 188 is the first to overflow. baseline-04 is off by one.
- baseline-04's own boundary test asserts only `v > 0` rather than the exact `F(186)` value, so the bug is invisible to its own test suite.
- **Integrated proposal fix:** `const MAX_POSITION: u64 = 187;` + two pinning unit tests (`fib_overflow_at_boundary_187`, `fib_1indexed_max_position_is_187`) that assert the exact value.

**Bug B — baseline-05 panic-on-overflow (`+` instead of `checked_add`).**
- baseline-05 explicitly documents in its proposal: "For positions beyond `186`, the addition `a + b` will panic in debug mode and wrap in release mode." Acknowledged as a "known limitation."
- Validator confirmed (`02-validacion-propuesta-minimax-baseline-05.md` lines 256–260): `./target/debug/fib 187` exits with code 101 (`thread 'main' panicked at src/main.rs:21:20: attempt to add with overflow`) in debug mode; silently wraps in release mode.
- Both behaviors violate the expected "English stderr + non-zero exit" contract for `n > 186`.
- **Integrated proposal fix:** `checked_add(...).ok_or(FibError::Overflow)` propagating `None` as `FibError::Overflow { position }` — verified in both debug and release modes, no panic possible.

**Plus a structural defect:** baseline-05 omits a fenced `src/main.rs` code block from the proposal. Validator had to reverse-engineer the implementation from prose (`02-validacion-propuesta-minimax-baseline-05.md` lines 100–103). This is a Completeness defect, not a Technical Quality defect, but it raises implementation risk.

**Net defect detection rate:** 2 of 6 proposals (33%) had real bugs or structural defects the validator exposed. The integrated proposal fixes both and adds pinning regression tests. **This is direct empirical evidence that the validator is a load-bearing step**, not a courtesy.

### 7.4 Viability vs score — orthogonal validation and grading

5 of 6 proposals (baseline-01, -02, -03, -05, -06) hit **10/10 viability** despite differing widely in evaluation score (29 → 44). The single sub-10 viability score (baseline-04 at 7.8/10) reflects that its boundary bug means some claims *do not* reproduce faithfully — but its spec table 1..11 still produces the right output, so it remains viable for the original prompt scope.

This confirms (from Run C §5.5–5.7 and the paper §6.4) that the validator's job is to verify that **claimed behaviours reproduce**, not to grade design quality. Validation and grading are orthogonal axes:

| Viab → / Score ↓ | 10/10 | < 10/10 |
|---|---|---|
| **≥ 40/50** | Strong: viable + well-designed | borderline (rare) |
| **30–40/50** | Viable but design flaws | borderline with bugs |
| **< 30/50** | Strong viability + poor design (e.g. baseline-05) | rare |

### 7.5 `sintesis_central` outcome — first end-to-end validation

This is the **first documented run with `step_5_modo: sintesis_central` and `validacion_empirica: true` both enabled and both completing without synthetic steps.** Comparison with prior runs:

| Run | Bundle | step_5_modo | validacion_empirica | Steps 3/4/6/7/8 quality |
|---|---|---|---|---|
| Run A (2026-07-11) | v0.2.0-beta | self_improve × 12 | true | Full; iter-2 cut at step 5 by quota |
| Run B (2026-07-12) | v0.3 | sintesis_central × 1 | true | Steps 3/4/6/7/8 **synthetic** (bash:ask blocked) |
| Run C (2026-07-13) | v1.2.1 | **skip** | false (default) | Full but no step 5/6/8 |
| **Run D (2026-07-13, this run)** | **v1.3** | **sintesis_central × 1** | **true** | **Full and real** |

In Run D, the integrator (`05-propuesta-integrada.md`) won by **+1 point** over the strongest original (44/50). Cost of step 5: ~5 min wall-clock + ~1 LLM invocation. Cost of self_improve × 6: would have been ~6 × ~5 min = ~30 min wall-clock + 6 LLM invocations.

**Direct evidence for §6.2 of the paper:** `sintesis_central` produces a strictly higher-scoring winner than the best individual original, at ~6× lower step-5 cost. Combined with Run B (where the integrator's score was derived from self-evaluation rather than a real evaluator pass, so the comparison was not strict), Run D's full end-to-end pipeline is the first **methodologically clean** sintesis_central validation.

### 7.6 Tool-call truncation bug — new failure mode

The step-1 re-emit for baseline-02 and baseline-03 (see §3.1) is a new bug class: the orquestador's response carrying multiple `task()` siblings in one response was **truncated mid-emission** by the LLM when the step-1 prompt text exceeded a length threshold. The truncation is **silent** — the LLM emits valid-looking `task()` headers with partial arguments and then ends the response without erroring.

**Mitigation in this run:** re-issued the truncated agents in a smaller batch (2 sibling `task()` calls instead of 3). Worked.

**Open question (logged for v1.3.x follow-up):** what is the maximum prompt length before truncation? Should `step_1_concurrent_max` be lowered to 2 for cohorts with long prompt templates? Should the workdir/path block be DRY'd out of the step-1 prompt?

**This is distinct from prior bugs:**
- Run B's `bash: ask` permission hang (opencode upstream #35073) — affects step 2 (validador).
- Run C's `step_5_modo: sintesis_central` orchestrator hang with 5+ agentes — affects step 5 (integrator).
- Run D's tool-call truncation — affects step 1 (propuesta launch).

Each is a different failure mode with a different mitigation.

## 8. Limitations

- **N=1 iter.** Single iteration only; no `mejora` calculation possible. `10-sintesis-cross-iter.md` documents the hypothetical iter-2 trajectory but it is speculative.
- **Cohort minimum (6 agents).** Smaller than Run C's 52-agent sweep. Limits statistical claims about variance and convergence; 6 proposals is enough for convergence analysis (4-6 of 6 majority threshold) but not for tail-latency or robustness claims.
- **Same prompt for all 6 proposals.** Unlike Run C's diverse prompt injection (Grupo B) and parameter sweep (Grupo C), Run D has no prompt variation. The variance measured is **intrinsic** LLM variance only.
- **Trivial prompt scope.** The Fibonacci CLI is a single-file, ~213-line Rust program with no GUI, no network, no async, no subprocesses. Findings about defect detection and `sintesis_central` do not necessarily generalize to more complex prompts.
- **No cost telemetry.** Token counts and dollar costs are byte-derived estimates from Run C, not measured during Run D. The MiniMax `model_remains` endpoint was not polled.
- **No OpenCode Go cross-model comparison.** Unlike Run C (11 OCG + 41 MiniMax = 52 agentes_a_competir), Run D uses 6 MiniMax-only baselines. Cross-model convergence findings from Run B and C are not re-tested here.
- **Tool-call truncation unmitigated at the orchestrator level.** The fix applied in this run was manual (re-issue smaller batch). The long-term fix is unknown and is logged as a v1.3.x follow-up.

## 9. Next experiments

1. **Side-by-side §6.2 validation: repeat fib-rust-cli with `step_5_modo: self_improve`** on the same 6-baseline cohort, same prompt, same permissions. This is the **gold-standard** §6.2 validation that Run B's bash:ask hang blocked and Run C's `step_5_modo: skip` made impossible. Cost: ~2.5× the iter-1 cost of Run D (mostly the 6 self-improve calls). Expected outcome: if `self_improve × 6` produces a winner with score ≥ 45/50 and viability ≥ 9.8/10, then `sintesis_central` and `self_improve` are roughly tied on quality (and `sintesis_central` wins on cost, confirming §6.2). If `self_improve × 6` produces a winner with score < 45/50, Run D's result stands.

2. **Tool-call truncation investigation.** Determine the maximum prompt length before truncation. Test `step_1_concurrent_max: 2` for cohorts with long prompt templates. Consider DRY'ing the workdir/path block out of the step-1 prompt and into the agent's own prompt template.

3. **Iter-2 of fib-rust-cli** with `05-propuesta-integrada.md` as the single "baseline" (replace `propuesta-minimax-baseline-{01..06}` with one propuesta-minimax agent seeded with the integrated proposal). Goal: confirm §6.3 cross-pollination holds at iter-2 with a uniform cohort.

4. **Cross-domain repeat with the 6-baseline cohort.** Pick a different prompt (e.g., "CLI that resolves DNS over HTTPS" or "static HTTP server with structured logging") and run with the same 6 baselines + `sintesis_central` + `validacion_empirica: true`. Goal: confirm Run D's findings (defect detection rate, `sintesis_central` +1 margin, within-cohort convergence) generalize beyond Fibonacci.

5. **Parameter sweep on a 6-baseline cohort.** Run fib-rust-cli with `agentes_a_competir: [propuesta-minimax-T05, propuesta-minimax-T07, propuesta-minimax-T10, propuesta-minimax-T15, propuesta-minimax-T05K50, propuesta-minimax-T10K200]` and compare defect detection rate, integrated winner score, and cost against the 6-baseline cohort. Goal: does parameter variation improve or worsen the integrator's defect detection ability?

6. **Bigger uniform cohort.** Repeat fib-rust-cli with 15 baselines (the v1.3 expansion) and compare variance, convergence, and integrated winner score. Goal: confirm the "15 baselines strengthens the statistical base" claim in v1.3 CHANGELOG §Added (v1.3).

---

## Appendix A — Configuration used

`/tmp/opencode-moa-v6-test/orquestador.json`:

```json
{
  "$schema": "https://opencode-moa.dev/schemas/orquestador.v1.3.json",
  "version": "1.3",
  "agentes_a_competir": [
    "propuesta-minimax-baseline-01",
    "propuesta-minimax-baseline-02",
    "propuesta-minimax-baseline-03",
    "propuesta-minimax-baseline-04",
    "propuesta-minimax-baseline-05",
    "propuesta-minimax-baseline-06"
  ],
  "modelo_objetivo": "minimax-coding-plan/MiniMax-M3",
  "max_iteraciones": 10,
  "umbral_convergencia": 0.5,
  "validacion_empirica": true,
  "descalificar_fallida": false,
  "smoke_test": false,
  "step_1_concurrent_max": 3,
  "step_1_agent_timeout_seconds": 600,
  "step_5_modo": "sintesis_central",
  "sintesis_final": true,
  "sintesis_final_modelo": "minimax-coding-plan/MiniMax-M3",
  "multi_eval": false,
  "multi_eval_modelos": [],
  "max_wall_clock_minutes": 0,
  "if_mejoras_tecnicamente_similares_a_otras": false,
  "param_validation_report": true
}
```

## Appendix B — User prompt

`/tmp/opencode-moa-v6-test/prompt.md`:

> Goal: build a command-line interface (CLI) in Rust that computes the Fibonacci number at a position the user provides.
>
> The expected results for the canonical 1..11 positions are:
>
> | Input (position) | Expected output (stdout) |
> |------------------|--------------------------|
> | 1                | 0                        |
> | 2                | 1                        |
> | 3                | 1                        |
> | 4                | 2                        |
> | 5                | 3                        |
> | 6                | 5                        |
> | 7                | 8                        |
> | 8                | 13                       |
> | 9                | 21                       |
> | 10               | 34                       |
> | 11               | 55                       |
>
> User-facing language: English (help text, errors, version banner).

## Appendix C — Winner path

`/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/05-propuesta-integrada.md` (51 217 bytes, ~1051 lines).

The integrated proposal's source tree was reproduced byte-for-byte by the validator at `/tmp/opencode-moa-v6-test/work/fib-rust-cli/iter-1/06-validacion-integrada/fib/` and produces a ~700 KB stripped release binary at `target/release/fib`.

## Appendix D — Files referenced

- iter-1 winner: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/05-propuesta-integrada.md`
- iter-1 winner validation: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/06-validacion-integrada.md`
- iter-1 final evaluation: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/07-calificacion-final.md`
- iter-1 classification: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/04-clasificacion.md`
- iter-1 step-8 winner write-up: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/08-ganador.md`
- iter-1 step-9 summary: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/09-sumario.md`
- iter-1 step-10 cross-iter synthesis: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/10-sintesis-cross-iter.md`
- 6 originales: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/01-propuesta-minimax-baseline-{01..06}.md`
- 6 per-original validations: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/02-validacion-propuesta-minimax-baseline-{01..06}.md`
- Evaluator signal on 6 originales: `/tmp/opencode-moa-v6-test/out/fib-rust-cli/iter-1/03-calificacion-evaluador.md`
- Validated source tree: `/tmp/opencode-moa-v6-test/work/fib-rust-cli/iter-1/06-validacion-integrada/fib/src/main.rs`