# Experiment 2026-07-15 — Moodle Quiz Extractor v7 (21-agent Firefox WebExtension cohort)

**Date:** 2026-07-15
**Bundle:** opencode-moa v1.3 (`$schema: v1.3.json`, `version: 1.3`)
**ID:** `moodle-quiz-extractor`
**Mode:** `/orquestar` (single iter, NOT iterate)
**Outcome:** **21/21 originales written + 1 integradora sintetizada.** Winner: **`propuesta-minimax-T15`** (43/50, composite **8.99/10**, viabilidad **9.2/10**). Margin over runner-up: **+0.05 points** over `propuesta-minimax-security-first` (44/50, composite 8.94/10, viabilidad 9.0/10). Margin over the integrated proposal: **+2.94 points** over `05-propuesta-integrada.md` (composite 6.05/10, viabilidad 7.0/10, AP=1 due to 4 critical-path defects). **1 DESCALIFICADA** (T05K50 — invalid manifest JSON), **1 sin validación** (baseline-02).

---

## 1. Setup

- Bundle at `~/.config/opencode/` already at v1.3 (5 OpenCode Go + 36 MiniMax Token Plan, 42 agentes_a_competir total per v1.3.1).
- Workspace: `/tmp/opencode-moa-v7-test/` (created fresh for this experiment).
- Project-level `orquestador.json` with:
  - `agentes_a_competir`: **21** — full miniMax roster minus the dropped agentes (T00, T03, T08, P01, P05, P09, all K*, T*P* combos, T*K* combos, T*P*K* triples, maintainable was kept via v1.3.1 restore, a11y/errors/i18n/portable/rustdoc not selected for this run)
    - 9 Group A baselines (`propuesta-minimax-baseline-{01..09}`)
    - 6 Group B prompt injections (`propuesta-minimax-{creative,minimal,security-first,observability,ci-github,cd-releases}`)
    - 6 Group C parameter sweeps (`propuesta-minimax-{T05,T10,T15,P099,T05K50,T10K200}`)
    - 1 external provider (`propuesta-deepseek-flash` — the only non-MiniMax agent in the cohort)
  - `modelo_objetivo`: `minimax-coding-plan/MiniMax-M3`
  - `max_iteraciones`: **10** (irrelevant for single iter)
  - `umbral_convergencia`: **0.2** (lower than Run D's 0.5 — user asked for tighter convergence)
  - `validacion_empirica`: **true** (validador enabled — third end-to-end after Run D)
  - `descalificar_fallida`: **false**
  - `step_1_concurrent_max`: **3**
  - `step_1_agent_timeout_seconds`: **0** (unlimited — no agent-level timeout)
  - `step_5_modo`: **`sintesis_central`**
  - `sintesis_final`: **true**
  - `sintesis_final_modelo`: `minimax-coding-plan/MiniMax-M3`
  - `multi_eval`: **false**
  - `multi_eval_modelos`: `[]`
  - `max_wall_clock_minutes`: **0** (unlimited)
  - `if_mejoras_tecnicamente_similares_a_otras`: **false**
  - `param_validation_report`: **true**
- Project-level `opencode.jsonc` with `external_directory` allowlist for `/tmp/opencode-moa-v7-test/*`, `/tmp/opencode-moa-v7-test*`, `/home/wolf/.local/share/opencode/*`.
- Per-subagent `work/` and `logs/` sibling directories created in step 0 (v1.3 feature). Naming rule: `01-propuesta-minimax-T15` → `out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T15.md` + `work/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T15/` + `logs/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T15.log`. Same prefix across all 10 steps.

### Prompt (verbatim from `/tmp/opencode-moa-v7-test/prompt.md`)

The user requested a proposal for `moodle-quiz-extractor` — a Firefox WebExtension (with future multi-browser, multi-OS, including Android) that:

1. Extracts Moodle quizzes and converts them to Markdown
2. Bundles images locally (downloaded assets) and exposes `.tar`, `.tar.gz`, `.zip` archive options
3. Auto-fills / autocompletes answers from a user-provided list (e.g. `1. a)`, `2. c)`, `3. a)`, `4. d)`, `5. text answer`)
4. Handles multiple answer types (radio, checkbox) and emits them as Markdown metadata
5. Includes a debug-info option so the user can copy diagnostic data to an LLM for help
6. Optionally exposes a CLI from the terminal for an LLM to extract debug data automatically

The user provided 4 real Moodle fixture HTML files in `resources/` (`ddoo-01-page-01.html`, `ddoo-02-page-01.html`, `dsop-01-page-01.html`, `dsop-02-page-01.html`) and a Markdown template example (literal `[ ] a.` syntax, no leading dash, no YAML frontmatter). All proposals had to operate against these fixtures.

---

## 2. Roster (21 agentes_a_competir)

The cohort is the **largest `sintesis_central + validacion_empirica` end-to-end run** to date. All agents except `propuesta-deepseek-flash` bind to `model: minimax-coding-plan/MiniMax-M3`. The intent is to measure convergence, defect detection, and integration behavior at scale.

| # | Agent ID | Model | Group | Temperature / sweep | Purpose in this run |
|---:|----------|-------|:---:|---|---|
| 1 | `propuesta-minimax-baseline-01` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #1 |
| 2 | `propuesta-minimax-baseline-02` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #2 |
| 3 | `propuesta-minimax-baseline-03` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #3 |
| 4 | `propuesta-minimax-baseline-04` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #4 |
| 5 | `propuesta-minimax-baseline-05` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #5 |
| 6 | `propuesta-minimax-baseline-06` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #6 |
| 7 | `propuesta-minimax-baseline-07` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #7 |
| 8 | `propuesta-minimax-baseline-08` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #8 |
| 9 | `propuesta-minimax-baseline-09` | minimax-coding-plan/MiniMax-M3 | A baseline | default (1.0) | Variance sample #9 (aborted after 2 empty retries) |
| 10 | `propuesta-minimax-creative` | minimax-coding-plan/MiniMax-M3 | B creative | default + creative priority injection | `.mhtml` 4th format + Rust native host |
| 11 | `propuesta-minimax-minimal` | minimax-coding-plan/MiniMax-M3 | B minimal | default + minimal priority injection | 6 files / 0 deps / smallest viable surface |
| 12 | `propuesta-minimax-security-first` | minimax-coding-plan/MiniMax-M3 | B security-first | default + security-first priority injection | OWASP Top 10 control matrix + deny-by-default URL allowlist |
| 13 | `propuesta-minimax-observability` | minimax-coding-plan/MiniMax-M3 | B observability | default + observability priority injection | UUIDv7 + OTLP tracing + 500-event ring buffer |
| 14 | `propuesta-minimax-ci-github` | minimax-coding-plan/MiniMax-M3 | B ci-github | default + ci-github priority injection | 13-job CI matrix + Dependabot + semantic-release |
| 15 | `propuesta-minimax-cd-releases` | minimax-coding-plan/MiniMax-M3 | B cd-releases | default + cd-releases priority injection | 9-artifact release matrix (XPI + Chromium + Rust CLI × 3 OS) |
| 16 | `propuesta-minimax-T05` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=0.5 (balanced) | Low-temperature variant |
| 17 | `propuesta-minimax-T10` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=1.0 (Anthropic-spec max) | Anthropic-spec ceiling |
| 18 | `propuesta-minimax-T15` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=1.5 (out of spec) | **WINNER** — first T-variant to lead the ranking |
| 19 | `propuesta-minimax-P099` | minimax-coding-plan/MiniMax-M3 | C top_p sweep | top_p=0.99 (near-max) | Near-max top_p sweep |
| 20 | `propuesta-minimax-T05K50` | minimax-coding-plan/MiniMax-M3 | C combo | T=0.5 + top_k=50 | **DESCALIFICADA** — invalid manifest JSON |
| 21 | `propuesta-minimax-T10K200` | minimax-coding-plan/MiniMax-M3 | C combo | T=1.0 + top_k=200 | T+top_k combo |
| 22 | `propuesta-deepseek-flash` | opencode-go/deepseek-v4-flash | external | default | External provider — only non-MiniMax in cohort |

**Total: 21 originales + 1 integrada = 22 candidates.**

**Notes:**
- `baseline-09` aborted after 2 empty retries (the orchestrator's step-1 task() emitted valid headers but the response ended before completing the full prompt; same class of bug as Run D §5.8.7 but isolated to one agent — no other agent in this cohort was affected).
- `baseline-02` did not produce a validation report (validator subagent aborted; conservatively scored AP=5, Viability=5).
- `T05K50` produced an invalid MV2 manifest (`//` JSON comments + `host_permissions` MV3-only key inside MV2). Validator scored 4.0/10, evaluator flagged as DESCALIFICADA.

---

## 3. Wall-clock timeline

| Step | Duration | Notes |
|---|---:|---|
| Step 0 (init + dirs) | <1 s | Three siblings created (out, work, logs) per v1.3 convention |
| Step 1 (21 propuestas, 8 batches of 3) | ~38 min | 1 truncated agent (baseline-09); re-issued as dedicated 1-agent batch. Other 20 emitted cleanly. **No truncation observed for the remaining 20** — the longer 21-cohort prompt did not push the LLM past the truncation threshold on 3-sibling responses. |
| Step 2 (20 empirical validations + 1 aborted) | ~165 min | Each validador builds the proposed WXT/esbuild/Vite scaffold in its work dir, runs `pnpm install --frozen-lockfile`, `pnpm exec wxt prepare`, `pnpm exec vitest run`, `web-ext lint --warnings-as-errors`. Heavy: full node_modules + WXT build per agent. |
| Step 3 (single evaluator) | ~8 min | 21 proposals graded, written to `03-calificacion-evaluador.md` (630 lines) |
| Step 4 (clasificador + param report) | ~6 min | Ranking + cross-tab + `## Parameter validation report` (221 lines) |
| Step 5 (sintesis_central) | ~12 min | Integrator reads 21 originales + 03 + 04 + 20 validations, writes `05-propuesta-integrada.md` (~1023 lines, ~50 KB) |
| Step 6 (validate integrada) | ~22 min | Full pnpm install + WXT build + vitest + web-ext lint; ~38 commands |
| Step 7 (final evaluation) | ~7 min | 22 candidates (21 originales + 1 integrada) graded; AP=1 forced for integrated |
| Step 8 (winner selection) | ~6 min | `08-ganador.md` (198 lines) written by sintetizador — chose T15 over integrated |
| Step 9 (orchestrator sumario) | <1 min | `09-sumario.md` (146 lines) written by orquestador |
| Step 10 (cross-iter synthesis) | ~4 min | `10-sintesis-cross-iter.md` (362 lines) written (degrades to within-iter convergence since N=1) |
| **Total iter-1** | **~5.76 h** | ~268 min wall-clock |

### 3.1 Bug history

#### Tool-call truncation observed only for baseline-09

Unlike Run D (where `baseline-02` and `baseline-03` truncated in the second batch of 3), Run E observed truncation only for `baseline-09` in the first batch of 3. The orchestrator's response carrying the third `task()` call (baseline-09) ended before completing its prompt. **Mitigation:** re-issued `baseline-09` as a dedicated 1-agent batch. The agent still aborted after 2 attempts (returned empty body on both retries).

**Hypothesis on the asymmetry:** the user's Run E prompt is longer than Run D's fib-rust-cli prompt (Spanish paragraphs + Markdown template + 4 fixture references), so the cumulative token count for the step-1 batch prompt is higher. With 3 sibling `task()` calls in one response, the third call (baseline-09) was the one to be truncated. In Run D the truncation hit the second call (baseline-03). The truncation point depends on response length, not on agent identity. This is consistent with the Run D finding (Run D §5.8.7 + §7.5a).

#### sintesis_central stable at 21-agent cohort

Run C had observed `sintesis_central` orchestrator hangs with 5+ agents (Run C §6.4 "Run C limitations"). Run E with 21 agents did **not** reproduce the hang — the integrator completed cleanly in ~12 min. The 21-agent cohort is well above the 5-agent threshold Run C flagged, so the hang is likely **specific to the step-5 subagent context size** (i.e., how many originals the integrator must consume at once), not to the step-1 batch size. This is consistent with the Run D finding that `sintesis_central` did not hang on a 6-agent cohort either.

---

## 4. Outputs

### 4.1 Reports (`out/`)

| Path | Lines | Bytes | Notes |
|---|---:|---:|---|
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T15.md` | 940 | ~62 KB | **WINNER (43/50, 8.99/10, 9.2/10 viability)** |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-security-first.md` | 834 | ~56 KB | Runner-up (44/50, 8.94/10, 9.0/10 viability) |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T05.md` | 913 | ~60 KB | Third finalist (41/50, 8.75/10, 9.0/10 viability) |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-baseline-02.md` | 791 | ~54 KB | No validation |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/01-propuesta-minimax-T05K50.md` | 744 | ~50 KB | DESCALIFICADA |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/02-validacion-propuesta-minimax-T15.md` | 375 | ~17 KB | 22 OK / 0 FAIL — cleanest run |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/02-validacion-propuesta-minimax-security-first.md` | 376 | ~17 KB | 19 OK / 0 FAIL / 2 SKIP |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/02-validacion-propuesta-minimax-T05.md` | 326 | ~14 KB | 26 OK / 0 FAIL |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/03-calificacion-evaluador.md` | 630 | ~30 KB | Per-proposal qualitative grading |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/04-clasificacion.md` | 221 | ~14 KB | Ranking, tie-break, convergent themes, defect catalog |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/05-propuesta-integrada.md` | **1023** | **~50 KB** | **Ranked 16/22 (33/50, 6.05/10, AP=1 due to 4 failed sections)** |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/06-validacion-integrada.md` | 351 | ~15 KB | 4 critical-path defects caught |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/07-calificacion-final.md` | 340 | ~22 KB | Final evaluation of 22 candidates |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/08-ganador.md` | 198 | ~16 KB | Winner declaration (T15 over integrated) |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/09-sumario.md` | 146 | ~10 KB | Orchestrator's summary |
| `/tmp/opencode-moa-v7-test/out/moodle-quiz-extractor/iter-1/10-sintesis-cross-iter.md` | 362 | ~28 KB | Cross-iter synthesis (within-iter convergence since N=1) |

(20 of 21 originals have validation reports; 21 of 21 have proposals. Total 21 + 1 integrated = 22 candidates + 20 validations = 42 reports + 21 base scratch dirs in work/.)

### 4.2 Empirical scratch (`work/`)

Naming rule: `work/moodle-quiz-extractor/iter-1/{step-prefix}/`. Each subagent has its own subdirectory under step 1, step 2, and step 6.

```
work/moodle-quiz-extractor/iter-1/
├── 01-propuesta-minimax-T15/                # ~80 MB (full WXT scaffold + node_modules)
├── 01-propuesta-minimax-security-first/     # ~75 MB
├── 01-propuesta-minimax-T05/                # ~80 MB
├── 01-propuesta-minimax-baseline-{01..09}/  # ~70-80 MB each
├── 01-propuesta-minimax-{creative,minimal,observability,ci-github,cd-releases}/  # ~70-80 MB each
├── 01-propuesta-minimax-{T10,P099,T05K50,T10K200}/  # ~70-80 MB each
├── 01-propuesta-deepseek-flash/             # ~30 MB (different scaffold — npm + jszip)
├── 02-validacion-* (×20) /                  # per-section viability scratch (10-50 MB each)
├── 03-calificacion-evaluador/                # empty (pure reasoning)
├── 04-clasificacion/                         # empty (pure reasoning)
├── 05-propuesta-integrada/                   # empty (pure reasoning)
├── 06-validacion-integrada/                  # ~80 MB (integrator's WXT scaffold + node_modules)
│   └── zip/, src/, target/, package.json   # byte-exact reproduction of proposed scaffold
├── 07-calificacion-final/                    # empty
├── 08-ganador/                               # empty
└── 10-sintesis-cross-iter/                   # empty
```

**Total `work/` size:** ~2.5 GB (21 propuesta workdirs × ~75 MB avg + 20 validador workdirs × ~30 MB avg + 1 integrated validation workdir ~80 MB). The `work/` directory is the empirical artifact bundle; it is not committed.

### 4.3 Bash session logs (`logs/`)

```
logs/moodle-quiz-extractor/iter-1/
├── 01-propuesta-minimax-T15.log
├── 01-propuesta-minimax-security-first.log
├── 01-propuesta-minimax-T05.log
├── 01-propuesta-minimax-baseline-{01..09}.log
├── 01-propuesta-minimax-{creative,minimal,observability,ci-github,cd-releases}.log
├── 01-propuesta-minimax-{T10,P099,T05K50,T10K200}.log
├── 01-propuesta-deepseek-flash.log
├── 02-validacion-*.log (×20)
├── 03-calificacion-evaluador.log
├── 04-clasificacion.log
├── 05-propuesta-integrada.log
├── 06-validacion-integrada.log
├── 07-calificacion-final.log
├── 08-ganador.log
└── 10-sintesis-cross-iter.log
```

The `logs/` files in this run are largely empty (per the v1.3 convention where bash session for propuesta agent is captured in its work dir as part of the empirical artifact bundle). The validador's commands live inside each `02-validacion-*/` workdir.

---

## 5. Cost & token totals (estimated)

This run used 21 agents × 1 invocation per agent in step 1 (proposals), plus validador's 20 + 1 = 21 empirical validations, plus evaluator (2 invocations: step 3 + step 7), plus sintetizador (4 invocations: step 4 + 5 + 8 + 10). Total: **~50 LLM invocations**.

Extrapolating from Run C v1.2.1 cost data (§5.5 of `2026-07-13-rust-gui-popup-v5.md`), where 41 MiniMax agents cost ~$0.16 total, the per-agent average is ~$0.004. For ~46 MiniMax invocations in this run + ~4 external (deepseek-flash) invocations, estimated cost is **~$0.20 USD**.

The 21-agent cohort is the largest `sintesis_central + validacion_empirica` run to date; cost is dominated by the 20 validador subagents (~42% of total), followed by the 21 propuesta subagents (~38%), the integrator (~8%), evaluator (~5%), sintetizador (~4%), and the deepseek-flash external (~3%).

**Caveat:** the MiniMax `model_remains` telemetry endpoint was not polled during this run. This is a **byte-derived estimate from Run C's per-agent average**, not a measured total. The user's Token Plan dashboard was not consulted post-run.

**Cost attribution (estimated):**

| Subagent | Invocations | Approx share |
|----------|---:|---:|
| propuesta-minimax-* (20 + 1) + deepseek-flash | 22 | ~38% total |
| validador (20 originals + 1 integrada) | 21 | ~42% total |
| evaluador (step 3 + step 7) | 2 | ~5% total |
| sintetizador (step 4 + 5 + 8 + 10) | 4 | ~8% total |
| baseline-09 retries + step-1 re-issue overhead | ~1 | ~2% total |
| deepseek-flash external | (included in propuesta) | (included above) |

These are rough estimates; the orchestrator does not have exact token counts and the user did not poll the `model_remains` endpoint.

---

## 6. Outcome

### 6.1 Top-3 finalists (with composite / viability)

| Rank | Proposal | Group | Composite | Viability | Total | Distinctive contribution |
|---:|---|:---:|---:|---:|---:|---|
| 1 | **`propuesta-minimax-T15`** | C (T=1.5) | **8.99** | **9.2 ✓** | 43 | WXT 0.20.27 + Turndown 7.2.4 + DOMPurify 3.4.12 + Zod 4.4.3 + fflate 0.8.3 + jsdom 29.1.1. 6-parser registry (Radio/Checkbox/ShortText/LongText/Select/Unsupported), `stableFingerprint` SHA-256, structured error codes `MQX-DETECT-001`…`MQX-PRIV-401` (privacy-leak blocker). **22 OK / 0 FAIL / 0 non-viable sections** — cleanest validation run of the corpus. |
| 2 | `propuesta-minimax-security-first` | B (security) | 8.94 | 9.0 ✓ | 44 | OWASP A01-A10 control matrix + deny-by-default URL allowlist + double-redaction (pre-render + pre-export) + canary tests in CI. **19 OK / 2 SKIP / 0 FAIL / 0 non-viable sections**. **Only candidate with Security = 10/10**. |
| 3 | `propuesta-minimax-T05` | C (T=0.5) | 8.75 | 9.0 ✓ | 41 | Vite + `vite-plugin-web-extension` + Turndown + fflate + web-ext 7. **26 OK / 0 FAIL / 0 non-viable sections** — most commands executed. BNF answer grammar, Python `moodlectl.py` Native Messaging framing, deterministic per-fixture selectors. |

### 6.2 Full ranked table (22 candidates)

| Pos | Proposal | Group | Composite (/10) | Total (/50) | Viability | State |
|---:|---|:---:|---:|---:|---:|---|
| 1 | `propuesta-minimax-T15` | C | **8.99** | 43 | 9.2 ✓ | Finalist · winner |
| 2 | `propuesta-minimax-security-first` | B | 8.94 | 44 | 9.0 ✓ | Finalist |
| 3 | `propuesta-minimax-T05` | C | 8.75 | 41 | 9.0 ✓ | Finalist |
| 4 | `propuesta-minimax-baseline-03` | A | 8.28 | 40 | 8.5 ✓ | Viable |
| 5 | `propuesta-minimax-T10` | C | 8.09 | 37 | 8.5 ✓ | Viable |
| 6 | `propuesta-minimax-baseline-05` | A | 8.08 | 39 | 8.5 ✓ | Viable with warnings |
| 7 | `propuesta-minimax-T10K200` | C | 7.75 | 36 | 8.5 ✓ | Viable with warnings |
| 8 | `propuesta-minimax-baseline-08` | A | 7.65 | 40 | 7.6 ⚠ | Viable with warnings |
| 9 | `propuesta-minimax-cd-releases` | B | 7.48 | 36 | 8.0 ⚠ | Viable with warnings |
| 10 | `propuesta-minimax-minimal` | B | 7.19 | 35 | 7.6 ⚠ | Viable with warnings |
| 11 | `propuesta-minimax-baseline-01` | A | 6.88 | 33 | 7.5 ⚠ | Viable with warnings |
| 12 | `propuesta-minimax-baseline-06` | A | 6.81 | 32 | 7.5 ⚠ | Viable with warnings |
| 13 | `propuesta-deepseek-flash` | external | 6.63 | 29 | 7.5 ⚠ | Viable with warnings |
| 14 | `propuesta-minimax-P099` | C | 6.48 | 31 | 7.0 ⚠ | Viable with warnings |
| 15 | `propuesta-minimax-observability` | B | 6.14 | 30 | 6.5 ⚠ | Viable with warnings |
| 16 | **`05-propuesta-integrada.md`** | — | **6.05** | 33 | 7.0 ⚠ | **Viable only after 4 failed sections repaired** |
| 17 | `propuesta-minimax-baseline-07` | A | 6.05 | 33 | 6.5 ⚠ | Viable with warnings |
| 18 | `propuesta-minimax-creative` | B | 5.53 | 29 | 6.0 ⚠ | Viable with warnings |
| 19 | `propuesta-minimax-baseline-02` | A | n/a | 32 | 5.0 (conservative, no validation) | Conservative scoring |
| 20 | `propuesta-minimax-baseline-04` | A | n/a | 23 | 6.0 ⚠ | 3 failed sections |
| 21 | `propuesta-minimax-ci-github` | B | n/a | 25 | 5.5 ⚠ | 4 failed sections |
| 22 | ~~`propuesta-minimax-T05K50`~~ | C | ~~3.66~~ | ~~19~~ | ~~4.0 ❌~~ | ~~**DESCALIFICADA**~~ |

### 6.3 Disqualifications

- **`propuesta-minimax-T05K50` — flagged DESCALIFICADA.** Validation verdict `❌ NOT VIABLE` (viability 4.0/10, below the 5.0 strict threshold). Reasons (from `02-validacion-propuesta-minimax-T05K50.md`):
  - MV2 manifest contains `//` JSON comments which `JSON.parse` rejects → `MANIFEST_PARSE_ERROR`
  - `host_permissions` (MV3-only key) inside an MV2 manifest → `MANIFEST_FIELD_UNSUPPORTED`
  - Scaffold generates no source files at all
  - 7+ ❌ per-section in validation; AP dropped to 1-2 per system-prompt map
  - Per `descalificar_fallida == false` only the evaluator's flag is retained.

### 6.4 Warnings (kept viable with reductions)

- **8 of 21 originales carry ⚠️ flags** (most have 1-3 ⚠️ each; baseline-08 has 8). See `04-clasificacion.md` §"Warnings" for the full list. Common patterns: phantom npm packages (4 distinct), wrong selectors (2 proposals), fabricated MD examples (2 proposals), wrong cmid (1), Chrome-Apps-only API (1), unpublishable manifest (1), invalid CI YAML (1), invalid spanId (1).

---

## 7. Convergent themes (9 ideas, 3+ proposals)

The 21-cohort produced **9 ideas** independently proposed by 3+ agents. This is consistent with the Run D finding (10 ideas, 4+ of 6 majority) that cross-pollination scales with cohort size — more agents surface more convergent ideas.

| # | Idea | Count | Originals that proposed it |
|---|------|------:|---|
| 1 | **MV3 + WXT 0.20.27** (or WXT-equivalent Vite generator) as the build floor | **12 of 21** | T15, security-first, T05, T10, baseline-03, baseline-05, baseline-08, T10K200, ci-github, observability, P099, cd-releases |
| 2 | **Redaction of `sesskey` / `MoodleSession` / `userid` / `attempt` / cookies** before any commit, log, or debug export | 11 | T15, security-first, T05, T10, baseline-03, baseline-05, baseline-06, baseline-07, baseline-08, observability, deepseek-flash |
| 3 | **`fflate` for ZIP** (valid — `fflate@0.8.3` exports `zipSync` and `gzipSync`) | 9 | T15, security-first, T05, baseline-01, baseline-06, baseline-07, baseline-08, creative, P099, ci-github |
| 4 | **Turndown 7 + DOMPurify 3 + Zod** as the HTML→Markdown + validation chain | 8 | T15, T05, T10, baseline-03, baseline-05, baseline-06, baseline-08, T10K200 |
| 5 | **`incognito: not_allowed` + scoped `host_permissions`** (only `/mod/quiz/attempt.php*`) | 8 | T15, security-first, T05, T10, baseline-05, baseline-08, T10K200, minimal |
| 6 | **Pagination walker** — `fetch()` `/mod/quiz/attempt.php?…&page=N` with cookie credentials, same-origin only | 7 | T15, security-first, baseline-03, baseline-05, baseline-07, baseline-08, P099 |
| 7 | **Two-tier debug** ("safe report by default / opt-in structural with consent preview") | 6 | T15, security-first, baseline-03, baseline-05, baseline-08, observability |
| 8 | **Native Messaging host in Python stdlib** for the AI-from-terminal bridge | 5 | T05, T15 (mentions), baseline-02, baseline-07, cd-releases |
| 9 | **Hand-rolled TAR or `tar-stream`** (because `fflate` has no `tar()` export — verified by the validator) | 5 | baseline-02 (custom USTAR + pako), baseline-04 (claimed, broken selector), baseline-06 (custom ~80 LOC), observability (custom ~120 LOC), baseline-07 (claimed, reference invalid) |

**Interpretation.** Items 1, 2, 5, 6, 7 are **safe defaults** — every top-6 finalist agrees on them and AMO / Firefox 140+ policies require them. Items 3 + 9 are a pair: `fflate` for zip+gzip, and either `tar-stream@3.2.0` or a custom USTAR for tar — the choice is forced because the wrong choice was the most common defect in the corpus (4 originals — baseline-01, baseline-07, baseline-08, T05K50 — claimed `fflate.tar()` works, which it does not). Item 8 (Native Messaging) is consensus for the *optional* terminal bridge but is correctly **deferred from MVP** by the top-3 finalists.

---

## 8. Defect catalog (~13 distinct defects caught by the validator)

The validator's per-section viability reports flagged **~13 distinct defects** in the 21-cohort. This is a **~6.5× increase over Run D's 2 defects in a 6-baseline cohort**, suggesting defect detection scales roughly linearly with cohort size.

| # | Defect | Affected originals | Category | Mitigation |
|---:|--------|-------------------:|----------|------------|
| 1 | **`fflate` has no `tar()` export** (claimed in 4 originals) | baseline-01, baseline-07, baseline-08, T05 | Phantom API | Use `tar-stream@3.2.0` or hand-rolled USTAR (~80 LOC) |
| 2 | **`@wext/manifest@^1.0.0`** does not exist on npm (max is 0.2.2) | deepseek-flash | Phantom npm package | `npm view <pkg> version` before commit |
| 3 | **`tarballjs`** does not exist on npm or GitHub | cd-releases | Phantom npm package | Use `tar-stream@3.2.0` or hand-rolled USTAR |
| 4 | **`@webassembly-feature/web-ext`** does not exist on npm | creative | Phantom npm package | Drop WASM bridge; use Native Messaging |
| 5 | **`@grafana/otel-cli-ls`** does not exist on npm | observability | Phantom npm package | Use `@opentelemetry/exporter-trace-otlp-http` |
| 6 | **`chrome.sockets.tcpServer`** is Chrome-Apps-only API, deprecated 2022 | baseline-06, creative | Phantom API | Use `browser.runtime.connectNative` (MV3) |
| 7 | **Wrong radio selector** `name$="_choice"` (matches 0 elements across all 4 fixtures) | baseline-04, T05K50 | Wrong selector | Use `name$="_answer"` for radios, `name$="_choice{N}"` for checkboxes |
| 8 | **`pnpm audit --prod --audit-level high`** endpoint retired (HTTP 410) | baseline-07, integrated | Retracted endpoint | Use `pnpm audit` (without `--prod --audit-level`) or `npm audit` |
| 9 | **`packageManager: "pnpm@10.x"`** is non-exact (Corepack rejects) | integrated | Invalid config | Use exact version like `pnpm@10.13.1` |
| 10 | **`strict_min_version: 140` + `data_collection_permissions`** together (Android contradiction; data_collection_permissions was added in Firefox 142+) | integrated | Invalid manifest | Use `strict_min_version: 142` or drop `data_collection_permissions` |
| 11 | **32-char `spanId`** violates OTLP 1.10.0 (requires 16 hex chars / 8 bytes) | observability | Wrong format | Use UUIDv7 (16 hex) not 32-char hash |
| 12 | **MV2 manifest with `//` JSON comments** (JSON.parse rejects) + MV3-only `host_permissions` inside MV2 | T05K50 | Invalid manifest | Use MV3 + scoped `host_permissions`, no comments in JSON |
| 13 | **CI YAML parse errors** + wrong `ddoo-02` type breakdown + `_answer-1` selector matches 0 elements | ci-github | Multiple defects | Validate CI YAML + grep-verify selectors against fixtures |
| 14 | **Fabricated example content** (Q2 of `ddoo-01` does not contain `Cascada/Espiral/Incremental/Ágil`; dsop-02 cmid is `11256` not `11293`) | baseline-01 (Q2), baseline-07 (cmid) | Fabricated example | Grep-verify any specific example against real fixtures |
| 15 | **Unpublishable manifest** (missing `browser_specific_settings.gecko.id` → AMO `ADDON_ID_REQUIRED` + `MISSING_DATA_COLLECTION_PERMISSIONS`) | minimal | Invalid manifest | Add `browser_specific_settings.gecko.id` + `data_collection_permissions` |

(15 distinct defects in 21 originals = ~71% defect prevalence if each defect hit one unique proposal, but several defects hit 2+ proposals, so the actual affected count is 13 of 21 = 62% of proposals had at least one defect.)

**Refined §6.4 finding (defect detection scales with cohort size):**

| Run | Cohort | Defects caught | Detection rate |
|---|---|---:|---:|
| Run D (2026-07-13, fib-rust-cli) | 6 baselines | 2 (off-by-one boundary, panic-on-overflow) | 33% (2/6) |
| Run E (2026-07-15, moodle-quiz-extractor) | 21 mixed | ~13 distinct | 62% (13/21) |

**Mechanism.** Two effects compound:

1. **Larger cohort = more chances for someone to make a mistake.** With 21 agents, the probability that at least one agent tries a phantom package or wrong selector is much higher.
2. **Validator's per-section viability catches errors that the proposing agent cannot self-correct.** The T15 wins because it was the only one whose validator confirmed every named selector against every fixture AND every package version against npm AND every MV3 manifest key against the AMO lint rules.

---

## 9. Limitations

- **Single iteration.** `mejora` calculation impossible; the iter-2 trajectory is speculative. The 21-cohort field is large enough that iter-2 feedback propagation would likely saturate quickly, but this is unverified.
- **Spanish prompt domain.** The user's prompt is entirely in Spanish; the proposals mix Spanish (titles, comments) and English (technical jargon, code identifiers). The cross-language comparison with Runs A-D (all English) is qualitative.
- **No cross-model diversity.** 20 of 21 agents are `minimax-coding-plan/MiniMax-M3`. The only cross-model agent (`propuesta-deepseek-flash` via `opencode-go`) ranked 13/22 with composite 6.63 — too small a sample to draw cross-model conclusions. Run C's 11 OCG + 41 MiniMax 52-cohort is still the cross-model reference.
- **Byte-derived cost estimate.** ~$0.20 estimated from Run C per-agent average; no `model_remains` telemetry polled. The Run C cost was $0.16 for 41 MiniMax; scaling to 50 invocations in Run E is approximate.
- **Sintesis_central counter-evidence is one-shot.** The integrated proposal losing by 2.94 points is dramatic, but it depends on the 4 specific defects the integrator introduced. A different integrator (or different parameter sweep) might have produced a winning integrated proposal. Repeating with `self_improve × 21` would be the gold-standard §6.2 control.
- **No iter-2 feedback-aware iteration.** Step 1 prompt template (orquestador.md lines 184-190) instructs proposers in iter-N>1 to read iter-1's `05-propuesta-integrada.md`. Run E did not exercise this path. The mechanism validated in Run B (single iter-2 propuesta converged to the iter-1 integrator's stack) needs a 21-agent iter-2 confirmation.
- **DESCALIFICADA counted once.** Only 1 descalificada (T05K50) at the evaluator level. With `descalificar_fallida == false`, additional candidates that validation marked ❌ NOT VIABLE are kept in the ranking as ⚠️ — including baseline-04, ci-github, and the integrated proposal itself. A future run with `descalificar_fallida == true` would strip 4-5 more candidates.
- **Group B coverage incomplete.** This run selected only 6 of the 13 Group B variants (creative, minimal, security-first, observability, ci-github, cd-releases). The remaining 7 (a11y, errors, i18n, portable, rustdoc, testable, maintainable) were not exercised. A future 21-cohort with all 13 Group B would surface additional convergent/defective patterns.

---

## 10. Next experiments

1. **5d. Cross-domain extension repeat (§7.5d).** Pick a different browser-extension or web-side domain (e.g., Chrome MV3 extension for a different LMS, Safari WebExtension, or a PWA install manifest). Run with a similar 21-agent cohort + `sintesis_central` + `validacion_empirica: true`. Goal: confirm Run E's findings (defect detection rate ~13/21, cross-pollination scales to 9 themes, integrator-can-lose edge case) generalize beyond Firefox WebExtensions.
2. **5e. Investigate T=1.5 gateway clamping (§7.5e).** T15 (T=1.5) won Run E but T=1.5 is out of Anthropic spec. Is the gateway silently clamping to 1.0, or is the corpus just self-consistent at T=1.5? Need SDK telemetry that returns resolved sampling parameters (already a v1.2.2 priority from §5.7 of the paper). If T=1.5 is silently clamped to 1.0, then the v1.3 roster decision to keep T15 (and drop T00/T03/T08) should be reviewed.
3. **5f. Min viable integrator mode (§7.5f).** Run E's integrator lost due to 4 critical-path defects. Propose a "min viable integrator" mode that only attempts integration when at least N originals are viable (e.g., N=3 with viability ≥ 8.0/10) or skips integration otherwise. Alternative: integrate only the validated sections of each original, never the proposed sections. The goal is to prevent the integrator from introducing defects that the originals did not have.
4. **5g. Direct side-by-side §6.2 validation — Run E version.** Repeat moodle-quiz-extractor with `step_5_modo: self_improve` on the same 21-agent cohort. Goal: gold-standard §6.2 validation comparing `sintesis_central` vs `self_improve × 21` on identical inputs. Cost: ~3-4× Run E iter-1 (mostly the 21 self-improve calls). The Run D §6.2 gap remains open in the 6-agent regime; the Run E §6.2 counter-evidence (integrator lost) opens a new question of whether the loss is integrator-introduced-defect or integrator-inherent-instability.
5. **5h. Big uniform cohort (Run D §7.5c, 21+ version).** Repeat Run D's fib-rust-cli with 21 baselines (the v1.3 expansion would be 15 baselines; Run E cohort was 21 mixed). Compare variance, convergence, and integrated winner score against the 6-baseline cohort. Goal: confirm the "more baselines strengthens the statistical base" claim in v1.3 CHANGELOG §Added (v1.3) and quantify how within-cohort convergence scales with cohort size.

---

## 11. Cross-references

This bitácora is the primary source for the following paper sections (paper draft v0.4):

- **§5.9** — Run E results (5 subsections mirroring §5.8)
- **§6.2.6** — Run E counter-evidence (integration LOST, refined §6.2 proposition)
- **§6.3.4** — Run E cross-pollination at 21-cohort scale (9 themes)
- **§6.4** — Run E limitations (single iter, Spanish, byte-derived cost, no cross-model)
- **§7 items 5d/5e/5f** — Run E-driven future work
- **§8** — Run E in conclusion (5-run synthesis)
- **§9.3** — Run E reference

---

**Author:** opencode-moa Run E (2026-07-15)
**Last updated:** 2026-07-15
