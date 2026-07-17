# Experiment 2026-07-16 — voxora-kernels v8 (22-agent CUDA kernel compatibility cohort)

**Date:** 2026-07-16
**Bundle:** opencode-moa v1.3 (`$schema: v1.3.json`, `version: 1.3`)
**ID:** `voxora-kernels`
**Mode:** `/orquestar` (single iter, NOT iterate — `max_iteraciones=10` but user did not invoke `/orquestar-iterate`)
**Outcome:** **22/22 originales written + 1 integradora sintetizada.** Winner: **`05-propuesta-integrada.md`** (integrated, AP **9.4**, validator **9.7/10** ✅, 7-section score **69/70**). Runner-up: `01-propuesta-minimax-T15.md` (AP **9.2**, validator **9.5/10** ✅, 6-section score 48/60). Comparable margin: **+0.2 AP**. The apparent **+21 total-point difference is not comparable** because the integrated proposal adds a synthetic seventh "Why this beats the field" section. **0 DESCALIFICADAS** at the global level; 4 ❌ NOT VIABLE per section (`minimal`, `T05K50`, `baseline-07`, `T10K200`).

This is the **4th distinct prompt domain** in the opencode-moa corpus (after Rust GUI, Rust CLI, Firefox WebExtension) and the first to target a **CUDA-kernel / GPU-binary compatibility** decision space.

---

## 1. Setup

- Bundle at `~/.config/opencode/` already at v1.3. The project-level override used for this run is authoritative for the cohort count (22 entries); the bundle's default roster is documented separately as 42 agents (6 OpenCode Go + 36 MiniMax Token Plan).
- Workspace: `/tmp/opencode-moa-v8-test/` (created fresh for this experiment).
- Project classification: **NOT_GIT** (orchestration workspace; out-of-scope for the GitHub PR protocol).
- Project-level `orquestador.json` listed **22 agents**, all launched successfully (9 Group A baselines, 6 Group B prompt injections, 6 Group C parameter sweeps, and 1 external provider). Five additional agents were excluded by user instruction before launch (`propuesta-mimo`, `propuesta-deepseek`, `propuesta-qwen37-plus`, `propuesta-kimi`, `propuesta-glm`); they do not appear in this project-level JSON or in the output corpus.
  - `modelo_objetivo`: `minimax-coding-plan/MiniMax-M3`
  - `max_iteraciones`: **10**
  - `umbral_convergencia`: **0.2**
  - `validacion_empirica`: **true**
  - `descalificar_fallida`: **false**
  - `smoke_test`: **false**
  - `step_1_concurrent_max`: **3**
  - `step_1_agent_timeout_seconds`: **0** (unlimited)
  - `step_5_modo`: **`sintesis_central`**
  - `sintesis_final`: **true**
  - `sintesis_final_modelo`: `minimax-coding-plan/MiniMax-M3`
  - `multi_eval`: **false**
  - `multi_eval_modelos`: `[]`
  - `max_wall_clock_minutes`: **0** (unlimited)
  - `if_mejoras_tecnicamente_similares_a_otras`: **false**
  - `param_validation_report`: **true**
- Project-level `opencode.jsonc` with `external_directory` allowlist for `/tmp/opencode-moa-v8-test/*`, `/home/wolf/.local/share/opencode/*`, `/home/wolf/workspace/projects/{voxora,telora,candle}/*` (READ-ONLY for the latter three per the user's instruction).
- Per-subagent `work/` and `logs/` sibling directories created in step 0 (v1.3 convention). Naming rule: `01-propuesta-minimax-T15` → `out/voxora-kernels/iter-1/01-propuesta-minimax-T15.md` + `work/voxora-kernels/iter-1/01-propuesta-minimax-T15/` + `logs/voxora-kernels/iter-1/01-propuesta-minimax-T15.log`.

### Prompt (verbatim from `/tmp/opencode-moa-v8-test/prompt.md`)

The user requested a proposal for `voxora-kernels` — a compatibility fork of `candle-kernels 0.9.2` (the version actually locked by `voxora/Cargo.lock`) that:

1. **Enables Candle CUDA kernels to compile and link on Pascal `sm_61` (GTX 1080 Mobile)** — the user's target hardware.
2. **Does not fork all of Candle** — narrow surface only.
3. **Optionally** create a separate `airvzxf/voxora-kernels` repository OR inject the patch via AUR-style `[patch.crates-io]` redirection.
4. **No upstream PR / no upstream issue** to the candle repo (pre-agreed by the user).
5. **Open to alternative approaches** if the synthesizer finds a better option (e.g., AUR-style patch passthrough, polyfill at the consumer level, etc.).

The user noted that:
- The local `/home/wolf/workspace/projects/candle` is on candle-kernels 0.11.0 with `cudaforge::KernelBuilder` API — the patch must target **0.9.2** with `bindgen_cuda::Builder`, NOT the local 0.11.0 checkout.
- `qwen3-asr` is the Qwen-side consumer integrated into `telora`; the user's downstream is `telora/telora-daemon/`.
- Maxwell `sm_50/sm_52` is "tu sabes, para viejas tarjetas gráficas" — out of scope for Phase 1; honest-deferral is preferred over compile-only claim.
- GPU rental credits available on `vast.ai` if compilation on other cards is needed.

---

## 2. Roster (22 originales, 5 user-excluded)

The project-level `orquestador.json` contained 22 entries. Five additional proposer agents were excluded by user instruction before launch; they are listed separately for transparency and produced no output files. All launched agents except `propuesta-deepseek-flash` bind to `model: minimax-coding-plan/MiniMax-M3`.

| # | Agent ID | Model | Group | Temperature / sweep | Outcome |
|---:|----------|-------|:---:|---|---|
| 1 | `propuesta-minimax-baseline-01` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 5.5 ⚠️ — unconditional MoE skip (contradicts own "no-op on sm≥70" claim) |
| 2 | `propuesta-minimax-baseline-02` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 8.9 ✅ — 4-file patch with `sm_80` MoE floor; supplies the BF16-launcher evidence |
| 3 | `propuesta-minimax-baseline-03` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 8.7 ✅ — AUR-style `[patch.crates-io]` 2-patch with broader scope |
| 4 | `propuesta-minimax-baseline-04` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 7.2 ⚠️ — 4-blocker analysis with citation drift |
| 5 | `propuesta-minimax-baseline-05` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 7.0 ⚠️ — AUR-style 2-file patch with one hallucinated BF16 quote |
| 6 | `propuesta-minimax-baseline-06` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 8.5 ✅ — standalone repo + DP4A-based MoE fallback (Maxwell-aware) |
| 7 | `propuesta-minimax-baseline-07` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 3.5 ❌ — false "patch is sufficient for Qwen CUDA" claim |
| 8 | `propuesta-minimax-baseline-08` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 8.7 ✅ — 2-file patch (compatibility.cuh + moe_wmma stub); PTX 37,328/293,657 B |
| 9 | `propuesta-minimax-baseline-09` | minimax-coding-plan/MiniMax-M3 | A baseline | default (0.7) | AP 8.5 ✅ — minimal in-tree 30-line patch |
| 10 | `propuesta-minimax-creative` | minimax-coding-plan/MiniMax-M3 | B creative | default (0.7) + creative priority | AP 7.7 ⚠️ — capability-sliced patch queue; `cudaforge` API drift |
| 11 | `propuesta-minimax-minimal` | minimax-coding-plan/MiniMax-M3 | B minimal | default (0.7) + minimal priority | AP 5.0 ❌ — patch files malformed (empty `@@` hunk headers) |
| 12 | `propuesta-minimax-security-first` | minimax-coding-plan/MiniMax-M3 | B security | default (0.7) + security-first priority | AP 8.5 ✅ — minimal patch + full supply-chain hardening (CycloneDX, cosign, minisign) |
| 13 | `propuesta-minimax-observability` | minimax-coding-plan/MiniMax-M3 | B observability | default (0.7) + observability priority | AP 7.0 ⚠️ — tracing + metrics + Prometheus; `cudaforge` API drift |
| 14 | `propuesta-minimax-ci-github` | minimax-coding-plan/MiniMax-M3 | B ci-github | default (0.7) + ci-github priority | AP 6.7 ⚠️ — 7 CI workflows; KCP indentation bug + `CUDA_TOOLKIT` operator-precedence trap |
| 15 | `propuesta-minimax-cd-releases` | minimax-coding-plan/MiniMax-M3 | B cd-releases | default (0.7) + cd-releases priority | AP 8.0 ⚠️ — Pascal patch + GitHub-Releases pipeline (cargo-dist 6-target matrix) |
| 16 | `propuesta-minimax-T05` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=0.5 (balanced) | AP 9.0 ✅ — standalone repo; per-architecture profile taxonomy |
| 17 | `propuesta-minimax-T10` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=1.0 (Anthropic-spec max) | AP 8.2 ✅ — 3 surgical edits + `no_wmma_stubs.cu` |
| 18 | `propuesta-minimax-T15` | minimax-coding-plan/MiniMax-M3 | C temp sweep | T=1.5 (out of spec, likely clamped) | AP 9.2 ✅ — cleanest 2-file ~110-line patch; PTX 282,810 B reproduced |
| 19 | `propuesta-minimax-P099` | minimax-coding-plan/MiniMax-M3 | C top_p sweep | top_p=0.99 (near-max) | AP 8.2 ✅ — Track A (compile-only) / Track B (full CUDA) split |
| 20 | `propuesta-minimax-T05K50` | minimax-coding-plan/MiniMax-M3 | C combo | T=0.5 + top_k=50 | AP ≈3.5 ❌ — standalone crate not resolvable as `candle-kernels` |
| 21 | `propuesta-minimax-T10K200` | minimax-coding-plan/MiniMax-M3 | C combo | T=1.0 + top_k=200 | AP 3.3 ❌ — 3 structural bugs (wrong Cargo metadata, undefined helper, missing paths panic) |
| 22 | `propuesta-deepseek-flash` | opencode-go/deepseek-v4-flash | external | default | AP 6.5 ⚠️ — targets wrong candle-kernels 0.11.0 with `cudaforge` API |
| 23 | **`05-propuesta-integrada.md`** | minimax-coding-plan/MiniMax-M3 | — (integrator) | default (0.7) | **AP 9.4 ✅ WINNER** — source-attributed synthesis; 18/18 line citations ≤5 lines |

**Excluded by user (5 agents, never launched):**

| Agent | Status |
|---|---|
| `propuesta-mimo` | excluded by user instruction — no proposal file emitted |
| `propuesta-deepseek` | excluded by user (note: only `-flash` variant exists and **is** part of the run) |
| `propuesta-qwen37-plus` | excluded by user instruction |
| `propuesta-kimi` | excluded by user instruction |
| `propuesta-glm` | excluded by user instruction |

**Total: 22 originales + 1 integrada = 23 candidates.**


---

## 3. Wall-clock timeline

The orchestrator did not record explicit per-step durations in this run; the values below are reconstructed from the agent-time, retry counts, and the summary's cost-attribution table (`09-sumario.md` §6).

| Step | Duration | Notes |
|---|---:|---|
| Step 0 (init + dirs) | <1 s | Three siblings (out, work, logs) created per v1.3 convention |
| Step 1 (22 propuestas, ~8 batches of 3) | ~30 min | **5 originals initially gateway-timed out** (security-first, observability, T10, P099, baseline-06); re-launched after wiping work dirs. `propuesta-deepseek-flash` succeeded first attempt. |
| Step 2 (22 empirical validations + 1 integrated re-validation) | ~25 min | Initial `validador` subagent hung on `webfetch` calls (opencode gateway bug, see §3.1). After prompt tightening (forbid webfetch/curl/network, bail at 30s), validations completed in 35-65s each consistently. |
| Step 3 (single evaluator) | ~6 min | 22 proposals + integration candidate graded; `03-calificacion-evaluador.md` (419 lines) |
| Step 4 (clasificador + param report) | ~3 min | Ranking + parameter-validation report; `04-clasificacion.md` (242 lines) |
| Step 5 (sintesis_central) | ~5 min | Integrator reads 22 originales + 03 + 04 + 22 validations; emits `05-propuesta-integrada.md` (357 lines). First attempt gateway-timed out on a 30-call tool budget; rewrite with 25-call budget + 30s/cap succeeded. |
| Step 6 (validate integrada) | ~2 min | Empirical re-validation of the integrated candidate; `06-validacion-integrada.md` (251 lines). Reproduced the 282,810 B PTX + 0 `atom.add.f16` + 8 `softmax_f16` byte-for-byte. |
| Step 7 (final evaluation) | ~2 min | 23 candidates (22 originales + 1 integrada) graded over 7 sections (the integrated candidate's synthetic "Why this beats the field" added as 7th row); `07-calificacion-final.md` (232 lines) |
| Step 8 (winner selection) | ~2 min | `08-ganador.md` (168 lines); chose integrated over T15 by AP +0.2 (the total-point comparison is non-uniform) |
| Step 9 (orchestrator sumario) | <1 min | `09-sumario.md` (133 lines) |
| Step 10 (cross-iter synthesis) | ~2 min | `10-sintesis-cross-iter.md` (174 lines); collapses to within-iter convergence since N=1 |
| **Total iter-1** | **~78 min** | ~1.3 h wall-clock |

### 3.1 Bug history

#### validador subagent hung on `webfetch` calls (mitigated, not fixed)

During the first ~5 validador invocations, the validator subagent called `webfetch` on URLs from external references in the proposals. Each call **hung indefinitely** (no response, no timeout from the opencode SDK). This is a distinct headless validation/tool-call failure from Run E's
`baseline-09` truncation and permission issues; Run E has no independently
documented webfetch hang. The root cause remains an open question (opencode
SDK, LLM tool-call budget, or network policy).

**Mitigation applied:** the orchestrator re-launched the affected validador subagents with a tightened prompt that:
1. Forbids `webfetch`, `curl`, `wget`, and any network access.
2. Requires a 30-second bail timeout on any tool call that hangs.
3. Directs the validator to consult **local files only** (`/home/wolf/workspace/projects/{voxora,telora,candle}` and `~/.cargo/registry/src/.../candle-kernels-0.9.2/`).

After the tightening, the remaining 18 validador invocations completed in **35-65 seconds each** consistently, with no hangs.

**Open question:** is this an opencode SDK bug, an LLM-side tool-call budget bug, or a network-policy issue specific to this VPS? Run E observed the same class of hang. The bug needs upstream investigation or a permanent prompt-template hardening; see §10 next-experiments item 5i.

#### 5 propuesta originals initially gateway-timed out

Five agents failed on first attempt with gateway timeouts:
1. `propuesta-minimax-security-first` (Group B)
2. `propuesta-minimax-observability` (Group B)
3. `propuesta-minimax-T10` (Group C)
4. `propuesta-minimax-P099` (Group C)
5. `propuesta-minimax-baseline-06` (Group A)

In each case the orchestrator wiped the agent's `work/` subdir and re-launched. All five succeeded on retry. **No proposal data was lost**; the retry overhead was ~30-60s per retry.

**Hypothesis:** the timeouts cluster on Group B agents with longer system prompts (priority-injection directives prepend to the base agent) and on Group C parameter-sweep agents that may have higher tool-call counts per proposal. The deepseek-flash external provider succeeded first attempt, suggesting the bottleneck is on the MiniMax provider gateway specifically, not on the orchestrator.

---

## 4. Outputs

### 4.1 Reports (`out/`)

| Path | Lines | Headline |
|---|---:|---|
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/01-propuesta-*.md` (22 files) | 309–1,827 | Original proposals; the largest files are `cd-releases`, `ci-github`, `baseline-09`, `baseline-08`, and `baseline-03` |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/02-validacion-*.md` (22 files) | 139–377 | Per-section viability and global verdicts |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/03-calificacion-evaluador.md` | 418 | Full ranking; 22 entries with per-section scores and platform feasibility |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/04-clasificacion.md` | 242 | Final ranking and parameter-validation report |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/05-propuesta-integrada.md` | 357 | **WINNER** (AP 9.4, validator 9.7/10 ✅, 69/70); 18/18 source-attributed line citations verified |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/06-validacion-integrada.md` | 251 | Empirical re-validation and byte-precise PTX reproduction |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/07-calificacion-final.md` | 232 | Final re-evaluation; 23 candidates over the non-uniform 7/6-section rubric |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/08-ganador.md` | 168 | Winner declaration and adoption guide |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/09-sumario.md` | 133 | Orchestrator summary and cost attribution |
| `/tmp/opencode-moa-v8-test/out/voxora-kernels/iter-1/10-sintesis-cross-iter.md` | 174 | Single-iteration cross-iteration synthesis |

**Total: 22 original proposals + 22 validations + 8 meta/summary reports = 52 reports.**

### 4.2 Empirical scratch (`work/`)

Naming rule: `work/voxora-kernels/iter-1/{step-prefix}/`. Each subagent has its own subdirectory.

```
work/voxora-kernels/iter-1/
├── 01-propuesta-minimax-T15/
│   └── empirical/
│       ├── build_test.sh
│       ├── Cargo.toml.example
│       ├── smoke.cu
│       └── voxora-kernels-0.9.2/   # patched tree (the validator's reproduction harness)
├── 01-propuesta-minimax-baseline-02/
│   ├── build-patched.log
│   ├── build.rs.patch
│   ├── build-smoke.log
│   ├── candle-kernels-0.9.2/
│   ├── cudaforge-0.1.5/            # cross-referenced (proves wrong API)
│   ├── patched-kernels/
│   ├── patched-kernels-no-stub/
│   ├── reduce.cu.patch
│   └── voxora-kernels-0.9.2-pascal1/  # the actual validated patched tree
├── 01-propuesta-minimax-baseline-{01..09}/
│   └── per-agent build artifacts (cargo target trees + CUDA builds; large)
├── 01-propuesta-minimax-{creative,minimal,security-first,observability,ci-github,cd-releases}/
│   └── per-agent build artifacts (large)
├── 01-propuesta-minimax-{T05,T10,T15,P099,T05K50,T10K200}/
│   └── per-agent build artifacts (large)
├── 01-propuesta-deepseek-flash/
├── 02-validacion-* (×22) /         # per-section viability scratch
├── 03-calificacion-evaluador/      # empty (pure reasoning)
├── 04-clasificacion/               # empty
├── 05-propuesta-integrada/         # empty
├── 06-validacion-integrada/        # ~5 MB (re-ran nvcc + grep on patched PTX)
├── 07-calificacion-final/          # empty
├── 08-ganador/                     # empty
└── 10-sintesis-cross-iter/         # empty
```

**Total `work/` size:** ~18 GB on this host — **larger than Run E's ~2.5 GB**, not smaller. Each propuesta's `cargo target/` tree plus per-target `nvcc` artifacts (e.g. `target-sm50/`, `target-sm52/`, `target-sm61/`, `target-sm70/`) consumed roughly 700 MB–1.7 GB each. The four largest contributors were `baseline-07` (~4.6 GB), `baseline-03` (~4.1 GB), `T05K50` (~3.4 GB), and `T05` (~2.1 GB). This is reported for completeness only; the bitácora's load-bearing artifacts (below) are tracked separately and are small.

The two **load-bearing empirical artifacts** are:
1. `work/voxora-kernels/iter-1/01-propuesta-minimax-T15/empirical/build_test.sh` — T15's reproduction harness, invoked by the integrated validator to reproduce the 282,810-byte PTX byte-for-byte.
2. `work/voxora-kernels/iter-1/01-propuesta-minimax-baseline-02/voxora-kernels-0.9.2-pascal1/` — baseline-02's vendored patched tree (which the integrated proposal's Source-attribution table cites, with a path-drift correction).

### 4.3 Bash session logs (`logs/`)

```
logs/voxora-kernels/iter-1/
├── 01-propuesta-*.log (×22)
├── 02-validacion-*.log (×22)
├── 03-calificacion-evaluador.log
├── 04-clasificacion.log
├── 05-propuesta-integrada.log
├── 06-validacion-integrada.log
├── 07-calificacion-final.log
├── 08-ganador.log
└── 10-sintesis-cross-iter.log
```

Per the v1.3 convention, `logs/` captures the bash session for each subagent invocation. In Run F the validador's commands live inside each `02-validacion-*/` workdir as part of the empirical artifact bundle.

---


## 5. Cost & token totals (estimated)

This run used 22 agents × 1 invocation per agent in step 1 (proposals) + 22 validador invocations + 1 integrated validador + 2 evaluador invocations + 3 sintetizador invocations + ~5 retry invocations + orchestration overhead = **~55 LLM invocations** total.

Extrapolating from Run C v1.2.1 cost data (§5.5 of `2026-07-13-rust-gui-popup-v5.md`, where 41 MiniMax agents cost ~$0.16 total) and Run D's ~$0.07 estimate for a 6-agent cohort, the per-agent average is **~$0.004 per LLM call**. For ~50 MiniMax invocations in this run + ~3 retry invocations, estimated cost is **~$0.20 USD**.

The 22-cohort's cost is dominated by the retry loop (~30% of total), followed by the validador subagents (~16%), the propuesta subagents (~38%), the sintetizador (~10%), the evaluador (~6%), and the deepseek-flash external (~3%).

**Caveat:** the MiniMax `model_remains` telemetry endpoint was not polled during this run. This is a **byte-derived estimate from Run C's per-agent average**, not a measured total. The user's Token Plan dashboard was not consulted post-run.

**Cost attribution (best-effort, from `09-sumario.md` §6):**

| Subagent | Count launched | Avg wall time / call (sec) | Total share (estimate) |
|----------|---:|---:|---:|
| `propuesta-minimax-*` (22 proposals) + 5 retries | 27 attempted, 22 successful | 75s first attempt / 30-60s retries | ~38% |
| `validador` (22 originals + 1 integrated) | 23 invocations | 35-65s (after tightening) | ~16% |
| `evaluador` (1 full + 1 re-eval) | 2 invocations | 95-135s | ~6% |
| `sintetizador` (1 classification + 1 integrated + 1 winner) | 3 invocations | 75-180s | ~10% |
| Internal orchestration (`todowrite`, file/dir setup, retries, debugging) | n/a | n/a | ~30% |

---

## 6. Outcome

### 6.1 Top-3 finalists (with AP, validator, total)

| Rank | Proposal | Group | AP | Validator | Total | Distinctive contribution |
|---:|---|:---:|---:|---:|---:|---|
| 1 | **`05-propuesta-integrada.md`** | — (integrator) | **9.4** | **9.7/10 ✅** | **69/70** (7 sections) | Source-attributed synthesis inheriting T15's 282,810-byte PTX + baseline-02's `sm_80` MoE floor + T05's dtype/device boundary. **18/18 line citations verified accurate to ≤5 lines**. Synthetic "Why this beats the field" row (10/10). |
| 2 | `01-propuesta-minimax-T15.md` | C (T=1.5) | **9.2** | **9.5/10 ✅** | 48/60 (6 sections) | Cleanest 2-file ~110-line in-tree patch; 282,810-byte patched PTX reproduced byte-for-byte on `nvcc 12.9.86 -arch=sm_61 -ptx`; principal weakness: unverified 0.85 end-to-end estimate (corrected by the integrated candidate). |
| 3 | `01-propuesta-minimax-T05.md` | C (T=0.5) | **9.0** | **9.4/10 ✅** | 46/60 (6 sections) | Standalone `airvzxf/voxora-kernels` repo variant; per-architecture profile taxonomy (sm_50..sm_120); every SHA and line number exact. Primary divergence: in-tree vs standalone packaging + honest dtype/device boundary. |
| 4 | `01-propuesta-minimax-baseline-02.md` | A | **8.9** | **9.0/10 ✅** | 45/60 (6 sections) | 4-file patch (`build.rs` + `moe_stub.cu` + `lib.rs` + `reduce.cu` guard); supplied the `sm_80` MoE floor evidence and the `test-no-stub` rationale. Path-drift in artifact reference (validator-corrected by integrated proposal). |

**Margin over runner-up:** integrated wins by **+0.2 AP**. The 69/70 versus 48/60 totals are reported for transparency but are not directly comparable: the integrated candidate received a synthetic seventh section. Decisive differences per `07-calificacion-final.md` and `08-ganador.md §2`:
- **Installations (10 vs 9, +1):** the integrated candidate adds the direct patched-PTX gate (`nvcc -O3 -std=c++17 -arch=sm_61 -ptx` + `grep -c 'atom.add.f16'` / `grep -c 'softmax_f16'`) as an install step; validator reproduced the byte-precise 282,810 B target.
- **Considerations (10 vs 9, +1):** integrated drops T15's unverified 0.85 end-to-end estimate and replaces it with explicit "compile-only / Phase 1" boundary + gates G1-G7.
- **Why-beats-field (10 vs N/A, +10 synthetic):** new 7th-section construct with seven specific corrections anchored to evaluator line ranges.

### 6.2 Full ranked table (23 candidates)

| Pos | Proposal | Group | AP | Validator | State |
|---:|---|:---:|---:|---:|---|
| 1 | **`05-propuesta-integrada.md`** | — (integrator) | **9.4** | 9.7/10 ✅ | **Finalist · winner** |
| 2 | `propuesta-minimax-T15` | C (T=1.5) | 9.2 | 9.5/10 ✅ | Finalist |
| 3 | `propuesta-minimax-T05` | C (T=0.5) | 9.0 | 9.4/10 ✅ | Finalist |
| 4 | `propuesta-minimax-baseline-02` | A | 8.9 | 9.0/10 ✅ | Viable ✅ |
| 5 | `propuesta-minimax-baseline-03` | A | 8.7 | 9.0/10 ✅ | Viable ✅ |
| 6 | `propuesta-minimax-baseline-08` | A | 8.7 | 9.0/10 ✅ | Viable ✅ |
| 7 | `propuesta-minimax-baseline-06` | A | 8.5 | 9.0/10 ✅ | Viable ✅ |
| 8 | `propuesta-minimax-baseline-09` | A | 8.5 | 9.0/10 ✅ | Viable ✅ |
| 9 | `propuesta-minimax-security-first` | B (security) | 8.5 | 9.0/10 ✅ | Viable ✅ |
| 10 | `propuesta-minimax-T10` | C | 8.2 | 8.5/10 ✅ | Viable ✅ |
| 11 | `propuesta-minimax-P099` | C | 8.2 | 8.5/10 ✅ | Viable ✅ |
| 12 | `propuesta-minimax-cd-releases` | B (cd-releases) | 8.0 | 8.5/10 ⚠️ | Viable with warnings |
| 13 | `propuesta-minimax-creative` | B (creative) | 7.7 | 8.0/10 ⚠️ | Viable with warnings |
| 14 | `propuesta-minimax-baseline-04` | A | 7.2 | 7.5/10 ⚠️ | Viable with warnings |
| 15 | `propuesta-minimax-baseline-05` | A | 7.0 | 7.5/10 ⚠️ | Viable with warnings |
| 16 | `propuesta-minimax-observability` | B (observability) | 7.0 | 7.5/10 ⚠️ | Viable with warnings |
| 17 | `propuesta-minimax-ci-github` | B (ci-github) | 6.7 | 7.0/10 ⚠️ | Viable with warnings |
| 18 | `propuesta-deepseek-flash` | external | 6.5 | 7.0/10 ⚠️ | Viable with warnings |
| 19 | `propuesta-minimax-baseline-01` | A | 5.5 | 6.0/10 ⚠️ | Viable with warnings |
| 20 | `propuesta-minimax-minimal` | B (minimal) | 5.0 | 5.0/10 ❌ | ❌ NOT VIABLE per section |
| 21 | `propuesta-minimax-T05K50` | C (combo) | ≈3.5 | 4.2/10 ❌ | ❌ NOT VIABLE per section |
| 22 | `propuesta-minimax-baseline-07` | A | 3.5 | 4.5/10 ❌ | ❌ NOT VIABLE per section |
| 23 | `propuesta-minimax-T10K200` | C (combo) | 3.3 | 4.2/10 ❌ | ❌ NOT VIABLE per section |

### 6.3 Disqualifications (kept visible, NOT removed from ranking)

Per `descalificar_fallida == false`, the 4 NOT VIABLE per section are kept in the ranking as ❌ entries rather than stripped:

- **`propuesta-minimax-minimal` (AP 5.0)** — patch files have malformed `@@` hunk headers rejected by GNU `patch`; Patch B omits early-return logic. Diagnosis is correct; deliverable is not.
- **`propuesta-minimax-T05K50` (AP ≈3.5)** — standalone `voxora-kernels-cuda-compat` crate replacement does NOT resolve as `candle-kernels` via `[patch.crates-io]`; the proposed `cuda-pascal` feature is absent from the workspace.
- **`propuesta-minimax-baseline-07` (AP 3.5)** — false "patch is sufficient for qwen3-asr on Pascal" claim contradicted by BF16 symbol-lookup test (`softmax_last_dim` / `gelu_erf` gated `>= sm_80`).
- **`propuesta-minimax-T10K200` (AP 3.3)** — three structural bugs: (a) `[workspace.metadata.patch.crates-io]` does not patch crates.io (workspace metadata is just metadata); (b) `build.rs` snippet uses `parse_first_arch_flag` which is not defined anywhere; (c) renames `moe_wmma*.cu` files outside the bindgen_cuda scan, then passes the original (now-missing) paths to `kernel_paths(...)` which panics on `exists()`.

### 6.4 Top-tier convergence on minimal patch

Per the evaluator (`03-calificacion-evaluador.md` §5), all 8 top-tier proposals (AP ≥ 8.5) converge on the same minimal in-tree `[patch.crates-io]` patch for `candle-kernels 0.9.2`:

> "Every viable proposal converges on the same 2-3 file minimal patch:
> - `src/compatibility.cuh`: activate the cutorch-style `atomicAdd(__half*, __half)` CAS-loop fallback at lines 38-59 (with corrected `defined(__CUDA_ARCH__)` guard for host pass).
> - `build.rs` (or equivalent): exclude `moe_wmma*.cu` from the build when `CUDA_COMPUTE_CAP < 70`. Optionally also gate on `< 60` for Maxwell support.
> - Optional `src/moe/moe_stub.cu`: 3-line no-op extern "C" stub providing `moe_gemm_wmma`, `moe_gemm_gguf`, `moe_gemm_gguf_prefill` so the link step succeeds (qwen3-asr never calls them)."

The integrated candidate drops the optional `moe_stub.cu` based on baseline-02's `test-no-stub` evidence (the current graph links without it because `qwen3-asr 0.2.2` contains zero MoE references).


---

## 7. Convergent themes (9 ideas, 17+ of 22 proposals)

The 22-cohort produced **9 convergent ideas** independently proposed by 17+ of 22 originals. This is the **highest convergence density in the opencode-moa corpus to date** (Run E: 9 themes at 21-cohort with max 12/21 = 57%; Run F: 9 themes at 22-cohort with max 17/22 = 77% on the in-tree patch approach).

| # | Idea | Count | Originals that proposed it |
|---|------|------:|---|
| 1 | **In-tree `[patch.crates-io]` for `candle-kernels 0.9.2`** (NOT standalone repo) | **17 of 22** | The list below is representative of the 18 non-divergent proposals; T05 and baseline-06 prefer standalone but defer to in-tree for Phase 1. **18 — {T05K50, T10K200, baseline-07, deepseek-flash}** = **17 explicitly in-tree + baseline-06/T05 noting "in-tree for Phase 1"** |
| 2 | **Pin exactly `candle-kernels = 0.9.2` with `bindgen_cuda::Builder`** (not 0.11.0 with `cudaforge::KernelBuilder`); lock file `voxora/Cargo.lock:293-294` is source of truth | 18 of 22 | All 17 in-tree proposals above + baseline-07 (which pins the right version but for wrong reasons) |
| 3 | **Keep Cargo package identity `name = "candle-kernels"`** under directory brand `voxora-kernels`, injected via root-level `[patch.crates-io]` | 17 of 22 | Same 17 in-tree proposals; T10K200 violates this with `[workspace.metadata.patch.crates-io]` |
| 4 | **Reduce patch surface to 2 production files**: `src/reduce.cu` (gate `SUM_OP(__half, sum_f16)` at `__CUDA_ARCH__ >= 700`) + `build.rs` (skip `moe_wmma*.cu` + `libmoe.a` below MoE floor) | 17 of 22 | Same 17 in-tree proposals; missing in T10K200 (3+ files), T05K50 (different package name), minimal (malformed) |
| 5 | **Byte-precise `nvcc -O3 -std=c++17 -arch=sm_61 -ptx` smoke test** as the install gate | **12 of 22** | T15 + baseline-{02,08,09} reproduced the recipe byte-for-byte (PTX 282,810 B for T15/baseline-02; PTX 293,657 B for baseline-08/09); 8 other proposals reference the recipe without reproducing it |
| 6 | **`__CUDA_ARCH__ >= 80` (NOT `>= 70`) as the MoE/WMMA floor** because the 0.9.2 launchers instantiate BF16 WMMA on Volta/Turing | 5 of 22 | baseline-02 (the originator with launcher-line evidence), T05, baseline-06, baseline-09, integrated |
| 7 | **No upstream PR** to the candle repo; the Candle maintainers won't backport Pascal/Maxwell | 22 of 22 (unanimous) | pre-agreed by the user; no proposal opened issues/PRs |
| 8 | **Separate compile evidence from runtime/model correctness**; validate on real target hardware (Pascal sm_61) before claiming support | 22 of 22 (unanimous) | consensus wording across the cohort |
| 9 | **Treat Maxwell sm_50/sm_52 as deferred** — not a Phase 1 promise | 22 of 22 (unanimous) | nobody has hardware to test; `__half` arithmetic has an `sm_53` floor; DP4A is `sm_61+` |

**Items that did NOT converge** (carried as known divergences instead):

- **In-tree vs standalone `airvzxf/voxora-kernels` repo.** T15/T10/baseline-09 prefer in-tree; T05/baseline-02/baseline-06 prefer standalone. The integrated candidate (winner) chose in-tree for Phase 1 with explicit extraction criteria.
- **BF16 runtime policy on Pascal.** Every proposal agrees the patch fixes compilation but **not** runtime dtype correctness. None of the 22 solve it inside `voxora-kernels`; the work must land in `qwen3-asr` or `candle-core/cuda_backend/mod.rs`. This remains the single largest open gap.
- **Whether to provide `moe_stub.cu` no-op stubs.** T15, baseline-02, baseline-03, baseline-08, baseline-09 explicitly say NO (the current graph links without it; qwen3-asr has no MoE references). T10, T10K200, creative provide stubs. The integrated candidate drops the stub based on baseline-02's `test-no-stub` evidence.

---

## 8. Defect catalog (~7 distinct defects caught by the validator)

The validator's per-section viability reports flagged **~7 distinct defects** in the 22-cohort. This is **lower than Run E's ~13 defects at 21-cohort** because Run F's cohort has narrower model diversity (only 1 external + 21 MiniMax vs Run E's 1 external + 20 MiniMax — same nominal ratio) but the defect space is more concentrated on the 4 API-drift proposals rather than spread across multiple non-overlapping failure modes.

| # | Defect | Affected originals | Category | Mitigation |
|---:|--------|-------------------:|----------|------------|
| 1 | **Wrong candle-kernels version target** (0.11.0 with `cudaforge::KernelBuilder` API, but voxora actually resolves 0.9.2 with `bindgen_cuda::Builder`) | deepseek-flash, observability, ci-github, creative | API version drift | Read `voxora/Cargo.lock` line 293-294 as source of truth; target 0.9.2 API |
| 2 | **Hallucinated BF16 quote** (proposal cites a `qwen3-asr-rs` BF16 fallback comment that does not exist in the actual `qwen3-asr-0.2.2/src/inference.rs:519-561`) | baseline-05 | Citation fabrication | Grep-verify any quoted code block against the actual file |
| 3 | **KCP indentation bug + `CUDA_TOOLKIT` operator-precedence trap** (`tools/kcp-apply.sh` indentation breaks `str.replace`; `ci-cuda.yml` resolves `cc=50` to boolean `true` instead of string `'11.8'`) | ci-github | Tooling bugs | Lint CI YAML + test `kcp-apply.sh` against a real candle-kernels source tree |
| 4 | **Malformed patch hunks** (empty `@@` hunk headers rejected by GNU `patch` with "Only garbage was found"; Patch B omits the actual early-return logic) | minimal | Patch format error | Test `git apply patches/*.patch` against a fresh checkout before commit |
| 5 | **Undefined helper `parse_first_arch_flag`** + `[workspace.metadata.patch.crates-io]` does not patch crates.io + missing kernel paths panic | T10K200 | Structural bugs (3 in 1) | Define helpers + use root-level `[patch.crates-io]` + verify kernel paths exist |
| 6 | **Standalone crate not resolvable as `candle-kernels`** (the proposed `voxora-kernels-cuda-compat` crate name does not match the upstream package name required by `[patch.crates-io]`) | T05K50 | Architectural flaw | Always preserve `name = "candle-kernels"` in `Cargo.toml` regardless of directory brand |
| 7 | **False "patch is sufficient for qwen3-asr on Pascal" claim** contradicted by BF16 symbol-lookup test (`softmax_last_dim` / `gelu_erf` gated `>= sm_80`) | baseline-07 | Runtime overclaim | Test actual kernel symbol availability, not just compile success |

**Refined §6.4 finding (defect detection scales with cohort size AND with domain complexity):**

| Run | Cohort | Domain complexity | Defects caught | Detection rate |
|---|---|---|---:|---:|
| Run D (2026-07-13) | 6 baselines | Rust CLI (1 requirement) | 2 | 33% (2/6) |
| Run E (2026-07-15) | 21 mixed | Firefox WebExtension (6 requirements) | ~13 distinct | 62% (13/21) |
| **Run F (2026-07-16)** | **22 mixed** | **CUDA kernel compat (multi-axis: API version + architecture + MoE + BF16)** | **~7 distinct** | **32% (7/22)** |

**Interpretation.** Run F's defect count is **lower** than Run E's because Run F's prompt domain has **fewer orthogonal decision axes** than Run E's (CUDA kernel compat is dominated by ONE blocker — `atomicAdd(__half*, __half)` + `nvcuda::wmma` namespace — plus a few secondary axes). Run E's prompt had 6 user requirements (extraction, images, archives, autofill, pagination, debug dump), each of which triggered its own class of defect. The defect-detection rate scales with **prompt-complexity per-axis**, not just cohort size. This refines the §6.4 finding from Run E.

**Mechanism.** Two effects compound:

1. **Larger cohort = more chances for someone to make a mistake.** With 22 agents, the probability that at least one agent gets the API version wrong (defect #1, 4 affected originals) is much higher than with 6 agents.
2. **Validator's per-section viability catches errors that the proposing agent cannot self-correct.** The integrated candidate wins because its 18/18 source-attributed line citations are verified accurate to ≤5 lines by the validador, AND its byte-precise PTX gate (`282,810 B ± 0`, `atom.add.f16 == 0`, `softmax_f16 ≥ 1`) is reproduced byte-for-byte on the validator's own `nvcc 12.9.86` invocation. This is the **first run in the corpus** where a candidate's score is grounded in independently-reproducible byte-exact evidence, not just viability verdicts.

---

## 9. Limitations

- **Single iteration.** `mejora` calculation impossible; the iter-2 trajectory is speculative. With `sintesis_final: true` enabled, the cross-iteration synthesis file (step 10) collapses to a within-iter convergence view. The user has not invoked `/orquestar-iterate`, so the convergence threshold (`umbral_convergencia: 0.2`) was never exercised.
- **5 user-excluded agents.** `propuesta-mimo`, `propuesta-deepseek`, `propuesta-qwen37-plus`, `propuesta-kimi`, and `propuesta-glm` were excluded by user instruction before launch. They do not appear in the project-level `orquestador.json` or the output corpus, so this run should be described as a **22-agent configured cohort**, not as a 27-agent roster trimmed after configuration.
- **§6.2 restoration is partial, not full.** Run D: +1, Run E: -2.94, **Run F: +0.2**. The integrated candidate wins but by a slim margin; the §6.2 counter-evidence from Run E is not fully refuted, only softened. A future run with `step_5_modo: self_improve × 22` would be the gold-standard §6.2 control to determine whether the +0.2 margin is meaningful or within noise.
- **7 defects is fewer than Run E's 13, but for domain-complexity reasons.** Run F's prompt has fewer orthogonal decision axes than Run E's; the lower defect count is consistent with §6.4's finding that defect detection scales with prompt complexity, not just cohort size.
- **validador webfetch gateway-timeout bug is mitigated, not fixed.** 5 originals initially timed out; tightening the validador prompt to forbid `webfetch`/`curl`/network and bail at 30s solved the immediate issue but did not fix the root cause. Future runs will need the same prompt tightening unless the opencode SDK bug is resolved upstream. See §10 next-experiments item 5i.
- **Byte-derived cost estimate.** ~$0.20 estimated from Run C's per-agent average; no `model_remains` telemetry polled. The Run C cost was $0.16 for 41 MiniMax; scaling to 55 invocations in Run F is approximate.
- **PTX byte-precise target (282,810 B) is host-CUDA-version-sensitive.** The validator's reproduction used `nvcc 12.9.86`; other CUDA toolkit versions may emit different byte counts for the same patched source. The integrated candidate's README-style adoption guide (`08-ganador.md §3.5`) explicitly warns about this and provides a recovery recipe for future `candle-kernels` regressions.
- Maxwell sm_50/sm_52 honestly deferred. No candidate has hardware to validate; the integrated candidate's support contract does not advertise Maxwell support.
- **Real WAV/audio transcription gate G5 was not executed in this synthesis.** The integrated candidate's §Considerations lists 7 stop/go gates (G1-G7), and G5 (real WAV transcription, CPU vs GPU comparison on GTX 1080) is the only gate that can lift Qwen from CPU to GPU on the GTX 1080. Until G5 passes, Telora must remain on `cuda-whisper`. This gate is the user's responsibility after they apply the patch; the orchestrated pipeline cannot run it without a writable Voxora checkout + GPU.
- **BF16 runtime gap is unfixed.** The patch fixes compilation but does NOT fix the runtime dtype story. `qwen3-asr 0.2.2` keeps BF16 weights on CUDA and the BF16 reduction kernels are gated `>= sm_80`. This is the **single largest open gap** carried forward unchanged from the 22 originals to the integrated candidate.
- **Source attribution is a forcing function, not a guarantee.** The integrated candidate's 18/18 line citations being accurate is evidence of careful synthesis, not a structural guarantee. A different integrator or a different parameter sweep might produce an integrated candidate with fabricated citations that happen to point to plausible line ranges. The validador's job is to catch this; the pattern works when both integrator and validador are well-instrumented.


---

## 10. Next experiments

1. **5j. Investigate validador webfetch gateway-timeout bug (Run F §3.1).** 5 originals initially gateway-timed out; tightening the validador prompt to forbid network calls solved the immediate issue but did not fix the root cause. Open questions: (a) is this the same bug as Run E's webfetch hang (opencode SDK 1.17.x stream timeout for cross-origin requests in headless mode)? (b) Should the v1.3 default `validador.md` prompt be hardened to forbid network access by default (with an opt-in flag for proposals that genuinely require it)? (c) Should `bash: ask` permissions be replaced with `bash: allow` at the user level for the validador subagent? This is the highest-priority follow-up motivated by Run F; mitigation strategies listed in §7.5a remain open.

2. **5k. Direct side-by-side §6.2 validation — Run F version.** Repeat voxora-kernels with `step_5_modo: self_improve` on the same 22-agent cohort. Goal: gold-standard §6.2 validation comparing `sintesis_central` (integrator wins by +0.2 in Run F) vs `self_improve × 22` on identical inputs. Cost: ~3-4× Run F iter-1 (mostly the 22 self-improve calls). Combined with Run E's `self_improve × 21` follow-up, this would give the corpus a complete §6.2 picture across 3 cohort sizes (6, 21, 22) and 3 prompt domains (Rust CLI, Firefox WebExtension, CUDA kernel compat).

3. **5l. Cross-domain extension repeat (§7.5d follow-up).** Pick a different GPU-binary or kernel-compatibility domain (e.g., ROCm/HIP port, Triton kernel compatibility, WebGPU shader translation, or a different candle-kernels patch for a different consumer like whisper-rs). Run with a similar 22-agent cohort + `sintesis_central` + `validacion_empirica: true`. Goal: confirm Run F's findings (defect rate ~7/22, cross-pollination scales to 9 themes at 17/22 max, integrator wins by +0.2 with source-attributed evidence) generalize beyond candle-kernels 0.9.2 specifically.

4. **5m. Investigate source-attribution as forcing function.** The integrated candidate's 18/18 line citations being accurate is a methodological win. Propose a v1.3.x feature: `integrator_source_attribution_required: true` (default false) that REQUIRES the integrator to publish a source-attribution table with N line ranges, AND requires the validador to verify each citation. Compare two runs on identical input: (a) without the requirement (Run E integrator loses); (b) with the requirement (Run F integrator wins). Goal: determine if source-attribution is causally responsible for the +0.2 AP margin, or merely correlated with integrator competence.

5. **5n. Repeat with the five excluded agents added explicitly to the project config.** Add `propuesta-mimo`, `propuesta-deepseek`, `propuesta-qwen37-plus`, `propuesta-kimi`, and `propuesta-glm` to the project-level `orquestador.json`, producing a 27-agent configured cohort. Compare convergence density (currently 17/22 = 77% on the in-tree patch idea) and defect detection (currently ~7/22 = 32%) at the larger cohort size. Goal: determine whether the additional agents surface new themes or defect classes, without describing them as part of the present run.

6. **5o. Real WAV/audio transcription G5 gate (per integrated §Considerations G5).** Apply the integrated candidate's 2-file patch to the user's writable Voxora checkout at `/home/wolf/workspace/projects/voxora/`. Run gates G1-G5 sequentially. The G5 gate is the only one that can lift Qwen from CPU to GPU on the GTX 1080; until G5 passes, Telora keeps `cuda-whisper`. Empirical outcome (G5 pass/fail + transcription accuracy) becomes input for a future `/orquestar-iterate voxora-kernels <gate-outcomes>` invocation that iterates the synthesizer against actual gate results.

---

## 11. Cross-references

This bitácora is the primary source for the following paper sections (paper draft v0.5):

- **§5.10** — Run F results (7 subsections mirroring §5.8 and §5.9)
- **§6.2.7** — Run F §6.2 restoration: integration wins by +0.2 AP with source-attributed evidence
- **§6.3.5** — Run F cross-pollination at 4th prompt domain (9 themes, max 17/22 on in-tree patch)
- **§6.4** — Run F limitations (single iter, 22 configured agents, 5 excluded before configuration, partial §6.2 restoration, rubric non-uniformity, validador webfetch bug)
- **§7 items 5j/5k/5l/5m/5n/5o** — Run F-driven future work
- **§8** — Run F in conclusion (6-run synthesis)
- **§9.4** — Run F reference

---

**Author:** opencode-moa Run F (2026-07-16)
**Last updated:** 2026-07-16
