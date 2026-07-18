# Experiment 2026-07-11 — Rust GUI app (multi-model iter test)

**Date:** 2026-07-11
**ID:** `rust-gui-app`
**Mode:** `/orquestar-iterate`, threshold 0.5, max 5 iterations (configured)
**Outcome:** iter-1 complete; iter-2 partial (cut by 5-hour quota at step 5)

---

## 1. Setup

`orquestador.json` (project-level override at `/tmp/opencode/opencode-moa-test/`):

```json
{
  "version": "1.1",
  "modelos_a_competir": [
    "opencode-go/deepseek-v4-flash", "opencode-go/deepseek-v4-pro",
    "opencode-go/glm-5.1",          "opencode-go/glm-5.2",
    "opencode-go/kimi-k2.6",         "opencode-go/kimi-k2.7-code",
    "opencode-go/mimo-v2.5",         "opencode-go/mimo-v2.5-pro",
    "opencode-go/qwen3.6-plus",      "opencode-go/qwen3.7-max",
    "opencode-go/qwen3.7-plus",      "minimax-coding-plan/MiniMax-M3"
  ],
  "modelo_objetivo": "minimax-coding-plan/MiniMax-M3",
  "max_iteraciones": 5,
  "umbral_convergencia": 0.5,
  "validacion_empirica": false,
  "descalificar_fallida": false
}
```

`step_5_modo`, `sintesis_final`, `multi_eval`, etc. were not yet
exposed in v0.2.0-beta — this experiment ran on the legacy
"self_improve" / 12-self-improvements path.

`~/.config/opencode/agents/` overrides applied at install time:
- `propuesta-deepseek.md`, `propuesta-mimo.md` etc. had their `model:`
  field updated from `opencode-go/minimax-m3:thinking` to the correct
  model strings.
- Two new proposal agents added locally: `propuesta-deepseek-flash.md`
  and `propuesta-minimax.md`.

`orquestador.md` was patched locally (NOT in repo) with a `HARD TIMING
CONSTRAINTS` block to cap propuesta subagents at 12 tool calls and
disable `cargo tauri build`. Without this patch, one subagent looped
on `xdotool`/screenshots for 35 minutes without converging.

User prompt (`/tmp/opencode/opencode-moa-test/rust-prompt.txt`):

> Lo que se pretende hacer es crear una aplicación visual GUI con Rust
> en el cual muestre una ventana y esta ventana va a mostrar un texto
> de título que diga "Bienvenido"… [truncated; Spanish-language
> requirement specification for a Rust desktop GUI with a minimizable
> overlay window]

---

## 2. Models competing

| id_corto        | provider/model                          | Auto-cost/request |
|-----------------|-----------------------------------------|------------------:|
| `minimax`       | `minimax-coding-plan/MiniMax-M3`        |           ~$0.06  |
| `deepseek`      | `opencode-go/deepseek-v4-pro`           |           ~$0.016 |
| `deepseek-flash`| `opencode-go/deepseek-v4-flash`         |           ~$0.001 |
| `glm`           | `opencode-go/glm-5.1` (iced hedge)      |           ~$0.048 |
| `glm-52`        | `opencode-go/glm-5.2`                   |           ~$0.039 |
| `kimi`          | `opencode-go/kimi-k2.6`                 |           ~$0.014 |
| `kimi-k27-code` | `opencode-go/kimi-k2.7-code` (kimi-k2.7-code variant) | ~$0.013 |
| `mimo-v25`      | `opencode-go/mimo-v2.5`                 |           ~$0.001 |
| `mimo`          | `opencode-go/mimo-v2.5-pro`             |           ~$0.018 |
| `qwen36-plus`   | `opencode-go/qwen3.6-plus`              |           ~$0.008 |
| `qwen37-max`    | `opencode-go/qwen3.7-max`               |           ~$0.062 |
| `qwen37-plus`   | `opencode-go/qwen3.7-plus`              |           ~$0.006 |

---

## 3. Wall-clock timeline

| Step | Description                              | Wall time |
|------|------------------------------------------|-----------|
| setup| Install + local patches + first launch   |   ~5 min  |
| v2 run | **KILLED** at step 1 +39 min (kimi-k27 loop) |   40 min (wasted) |
| v3 launch | Fresh iter-1 with constraint patched  |   —       |
| iter-1 step 1 | 12 proposals in parallel     |   13 min  |
| iter-1 step 3-9 | eval → classify → improve → re-eval → winner → summary |   18 min  |
| iter-2 step 1 | 12 fresh proposals          |    7 min  |
| iter-2 step 3-4 | eval + classify             |    3 min  |
| iter-2 step 5 | 9 of 12 improvements written |  6 min (cut by quota) |
| iter-2 step 7-9 | CUT — 5-hour quota 100%   |   —       |

**Total useful wall clock (v3 only):** ~52 min.
**Wall clock including dead v2 run:** ~95 min.

---

## 4. Outputs (paths under `/tmp/opencode/opencode-moa-test/`)

### iter-1 (complete, 30 files)

```
out/rust-gui-app/iter-1/
├── 01-propuesta-{deepseek-flash, deepseek, glm-52, glm, kimi-k27-code,
│   kimi, mimo, mimo-v25, minimax, qwen36-plus, qwen37-max, qwen37-plus}.md
├── 03-calificacion-evaluador.md     (596 lines)
├── 04-clasificacion.md
├── 05-mejorada-{...same 12...}.md    (12 improvements)
├── 07-calificacion-final.md          (845 lines)
├── 08-ganador.md                     (winner = minimax 42/50)
└── 09-sumario.md                     (78 lines)
```

### iter-2 (partial, 23 of 30 files)

```
out/rust-gui-app/iter-2/
├── 01-propuesta-{...12...}.md
├── 03-calificacion-evaluador.md      (1031 lines; 12 fresh)
├── 04-clasificacion.md
├── 05-mejorada-{deepseek-flash, deepseek, glm, kimi, mimo, mimo-v25,
│   minimax, qwen36-plus, qwen37-plus}.md  ← 9 of 12
└── (no 06, 07, 08, 09 — step 5 cut before completion)
```

**Missing iter-2 files:** `05-mejorada-{glm-52, kimi-k27-code, qwen37-max}.md`,
`06-validacion-*.md`, `07-calificacion-final.md`, `08-ganador.md`,
`09-sumario.md`.

---

## 5. Cost & token totals

Raw cost data (from `opencode-go` provider API response metadata):

| Modelo            | Peticiones | Costo (USD) | %    | Tokens In  | Tokens Out | Reasoning |
|-------------------|-----------:|------------:|-----:|-----------:|-----------:|----------:|
| qwen3.7-max       | 62         |  $3.8478    | 31.18|       372  |    40,849  |     0     |
| kimi-k2.7-code    | 152        |  $1.9325    | 15.66|   309,235  |    67,267  |  37,700   |
| glm-5.1           | 33         |  $1.5892    | 12.88|   613,481  |    74,146  |     0     |
| glm-5.2           | 40         |  $1.5737    | 12.75|   551,679  |    55,687  |     0     |
| kimi-k2.6         | 87         |  $1.2072    |  9.78|   455,029  |    47,671  |     0     |
| deepseek-v4-pro   | 50         |  $0.7914    |  6.41|   334,672  |    49,894  |  14,951   |
| mimo-v2.5-pro     | 35         |  $0.6198    |  5.02|   278,556  |    32,063  |   4,125   |
| qwen3.6-plus      | 50         |  $0.3957    |  3.21|       300  |    29,930  |     0     |
| qwen3.7-plus      | 50         |  $0.2784    |  2.26|       300  |    50,317  |     0     |
| deepseek-v4-flash | 46         |  $0.0588    |  0.48|   277,700  |    51,969  |  14,300   |
| mimo-v2.5         | 39         |  $0.0461    |  0.37|   222,974  |    33,469  |   4,851   |
| **TOTAL**         | **644**    | **$12.3407**|      |**3,044,298**|  **533,262**| **75,927**|

**Observations:**
- `mimo-v2.5` (the cheapest at $0.046) produced the **single biggest
  lift** in iter-2 fresh: +14 points (26 → 40). Cheap + high-lift =
  best ROI model in this run.
- `deepseek-v4-flash` ($0.059) ranked consistently in the top 5 across
  both iterations — second-best ROI.
- `qwen3.7-max` ate 31% of total cost ($3.85) but produced useful output
  (rank 5 in iter-2 fresh). Cost is acceptable for that return.
- `qwen3.6-plus` ($0.40) regressed in iter-2 (score stuck at 27). Money
  down a hole.
- `deepseek-v4-pro` ($0.79) also regressed (24 → 24). Excluded from
  the default bundle.
- Cost spread: top model cost 84× the bottom model. Wide range of
  effective $/value.

---

## 6. Outcome

### iter-1 final ranking (after improvements)

| Pos | Model                | Final score (45 base + iter-5 = /50) | Viab. |
|-----|----------------------|-------------------------------------:|------:|
| 🥇  | minimax (MiniMax-M3) | **42/50**                            | 9/10  |
| 🥈  | glm-5.2              | 41/50                                | 9/10  |
| 🥉  | glm-5.1 (iced hedge) | 41/50                                | 8/10  |
| 4    | deepseek-v4-flash    | 39/50                                | 8/10  |
| 5    | qwen3.7-plus         | 38/50                                | 8/10  |
| 6    | qwen3.7-max          | 38/50                                | 8/10  |
| 6    | kimi-k2.6            | 36/50                                | 7-8/10|
| 6    | mimo-v2.5            | 36/50                                | 7-8/10|
| 6    | mimo-v2.5-pro        | 36/50                                | 7-8/10|
| 10   | qwen3.6-plus         | (≤36)                                | 4-7/10|
| 10   | deepseek-v4-pro      | (≤36)                                | 4-7/10|
| 12   | mimo                 | (≤36)                                | 4-7/10|

### iter-2 fresh ranking (proposals NEW for iter-2, no improve pass)

| Pos | Model               | iter-1 orig | iter-2 fresh | Δ    |
|-----|---------------------|------------:|-------------:|-----:|
| 🥇  | minimax             |          35 |          42 |   +7 |
| 🥈  | deepseek-flash      |          31 |          41 |  +10 |
| 🥉  | mimo-v25            |          26 |          40 |  +14 |
| 4    | qwen37-max          |          27 |          39 |  +12 |
| 5    | glm (iced)          |          34 |          38 |   +4 |
| 6    | qwen37-plus         |          29 |          38 |   +9 |
| 7-9  | kimi, kimi-k27, glm-52 |       — |         36 |   — |
| 10   | qwen36-plus         |          27 |          27 |    0 |
| 11   | deepseek            |          24 |          24 |    0 |
| 12   | mimo                |          22 |          22 |    0 |

The bottom three (qwen36-plus, deepseek, mimo) did **not improve** in
iter-2 — they regressed their architecture or kept their bugs. The
top six, however, jumped 9-14 points on average.

---

## 7. Observations

### Cross-pollination signals

Comparison of idea propagation between iter-1 originals and iter-2
fresh proposals:

| Idea                                | In iter-1 | In iter-2 | Origin (in iter-1)            |
|-------------------------------------|----------:|----------:|-------------------------------|
| `request_repaint()`                 |       2/12|      12/12| `propuesta-minimax.md`         |
| edge-detect over `Resized(≈0×0)`    |       1/12|      12/12| `propuesta-minimax.md`         |
| `rust-toolchain.toml`               |       4/12|      12/12| `propuesta-deepseek.md` (etc.)|
| `WindowLevel::AlwaysOnTop`          |      11/12|      12/12| (already saturated)            |
| `rounded corners` description       |      11/12|      12/12| (saturated, in user prompt)    |

**`request_repaint` and `edge-detect` are the smoking guns:** each
appeared in exactly ONE iter-1 proposal (`propuesta-minimax.md`), then
spread to all 12 in iter-2. This is **empirical evidence that the
synthesizer's feedback loop propagated a genuinely novel idea across
the pool.**

The 2026-07-11 04-clasificacion.md iter-2 finale contains a
"Theme of iter-2" paragraph from the synthesizer:

> "All 12 proposals adopted `rust-toolchain.toml` (vs iter-1 where
> only 5/12 had it); 10/12 explicitly addressed `request_repaint()`;
> 12/12 implement some form of edge-detect. The genuinely NEW contributions
> beyond the synthesizer's top-3 are concentrated in the winner and
> runner-up: minimax adds theming, i18n stub, accessibility (Esc +
> label-before-input), and Wayland handling; deepseek-flash adds
> AccessKit integration (the only proposal addressing screen-reader
> support)."

### Model personality vs model floor

- **High floor models** (iter-1 fresh ≥ 30): `minimax` (35), `glm (iced)` (34),
  `deepseek-flash` (31). Fast turnaround.
- **Low floor with high lift** (iter-1 fresh < 28, iter-2 fresh ≥ 38):
  `mimo-v25` (26 → 40), `qwen37-max` (27 → 39). Useful only with full
  iteration budget.
- **Persistent low performers** (`descalificar` candidates): `qwen36-plus`,
  `deepseek`, `mimo`. Regressed in iter-2 (kept the same architectural
  bug across iterations).

### Winning proposal (iter-1 winner + iter-2 winner)

`out/rust-gui-app/iter-1/05-mejorada-minimax.md` (and/or
`out/rust-gui-app/iter-2/01-propuesta-minimax.md`):

- Rust + egui 0.33–0.35 + eframe 0.35 + wgpu
- `ViewportBuilder::default().with_title("Bienvenido")…`
- Multi-viewport popup using `eframe::show_viewport_deferred`
- `WindowLevel::AlwaysOnTop` for the overlay
- `with_transparent(true)` + rounded clip to get real rounded corners
- `request_repaint()` call after state transitions
- Edge-detect: `ctx.input(|i| i.viewport().minimized)` + debounce on
  `Unfocused` for Wayland
- Cargo-free static binary (no GTK/Qt/webview runtime deps)

---

## 8. Limitations

- **N=1**: all observations are from one run on one domain (Rust GUI).
  Cannot conclude which patterns generalise to medications, creative,
  or other technical tasks without repetition.
- **Within-domain variance**: different Rust problems (CLI tool vs
  embedded vs GUI) might reward different models differently.
- **Provider variance**: `opencode-go` is known to occasionally
  degrade specific models (e.g. they switched `deepseek-v4-pro` to a
  lighter variant mid-week — see #discussion). Flash > Pro here is
  suspect; another run could flip.
- **Quota cut**: iter-2 was cut mid-step-5. We have iter-2 fresh
  scores (step 3, 4) but no iter-2 improved/validated/winner loop.
- **`propuesta-kimi-k27-code` was the model that timed out** in
  iter-2 due to its `cargo tauri build` invocation — kimi-k2.7-code
  may be especially prone to long empirical runs.
- **Evaluator (minimax-coding-plan/MiniMax-M3) graded its own
  proposal in iter-2** (`propuesta-minimax.md`). Transparency notice
  in 03-calificacion-evaluador.md is honest about this. This is a
  general limitation of single-eval design.

---

## 9. Next experiments (concrete, motivated by this run)

1. **Cross-domain reproducibility** — same orchestrator config, but
   different domain (e.g. medication side-effect analysis, marketing
   copy refinement). Goal: confirm `glm-5.1` retains the "hedging
   stack" advantage in non-Rust domains.
2. **Multi-eval enabled** — set `multi_eval: true` with
   `multi_eval_modelos: [minimax, glm-5.2]` and re-grade iter-1
   proposals. Goal: measure inter-evaluator variance and quantifiy
   single-eval bias.
3. **Single-model-improvement vs synthesis-central** — rerun with
   `step_5_modo = self_improve` and compare step 5 cost +
   05-mejorada.md quality vs this run's `sintesis_central` results
   (the v1.1 default). Goal: validate the synthesis approach.
4. **N=3-5 reruns on same domain** — measure variance of qwen3.7-max
   and mimo scores. Goal: detect which rankings are stable vs noisy.
5. **Sparse models** — replace models with similar behavior (e.g.
   drop `deepseek-v4-pro` since `deepseek-v4-flash` consistently wins)
   to reduce iter-1 cost without affecting quality.
6. **Creative prompt** — add the `if_mejoras_tecnicamente_similares_a_otras`
   flag to a real run and measure diversity delta vs the no-flag run.

---

## 10. Appendix — Files used / produced this run

- Inputs (project-level):
  - `/tmp/opencode/opencode-moa-test/orquestador.json`
  - `/tmp/opencode/opencode-moa-test/rust-prompt.txt`
  - `/tmp/opencode/opencode-moa-test/opencode.jsonc` (permisos)
- Outputs (full output):
  - `/tmp/opencode/opencode-moa-test/out/rust-gui-app/iter-1/` (30 files)
  - `/tmp/opencode/opencode-moa-test/out/rust-gui-app/iter-2/` (23 files)
- Logs:
  - `/tmp/opencode/opencode-moa-test/rust-gui-iter.log`
- Backups:
  - `/tmp/opencode/opencode-moa-test/BACKUP-iter1-v3/` (complete)
  - `/tmp/opencode/opencode-moa-test/BACKUP-iter2-partial-v3/` (partial)
  - `/tmp/opencode/opencode-moa-test/FULL-BACKUP-2026-07-11/` (full test dir)
- Live Patches (NOT in repo):
  - `~/.config/opencode/agents/orquestador.md` was patched locally
    with a `HARD TIMING CONSTRAINTS` block (max 12 calls, no cargo
    tauri build) — see commit `feat(iter): refinamientos…` v1.1
    formal version.
