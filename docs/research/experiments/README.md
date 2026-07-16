# Experiment log — `opencode-moa`

This folder is the canonical record of empirical runs of `opencode-moa`.
Each entry documents one run end-to-end (prompt, models, configuration,
outputs, observations). The goal is reproducibility + cross-run
comparability — anyone should be able to take an entry, reproduce it, and
challenge its conclusions.

## Format

Each file is named `YYYY-MM-DD-<short-id>.md` and follows this layout:

1. **Setup** — orchestrator.json, propuesta agents list, user prompt,
   config flags (max_iter, validacion_empirica, step_5_modo, etc.).
2. **Models competing** — table: id_corto → provider/model → estimated cost per request.
3. **Wall-clock timeline** — start, per-step durations, end.
4. **Outputs** — paths to all generated files. Use absolute paths under
   `/tmp/opencode/opencode-moa-test/out/{id}/iter-N/`.
5. **Cost & token totals** — total $USD by model (from session telemetry),
   input/output/reasoning tokens.
6. **Outcome** — winner, scores, viability, score trajectory iteration N.
7. **Observations** — what converged, what diverged, anomalies,
   cross-pollination signals.
8. **Limitations** — what we cannot conclude from this single run.
9. **Next experiments** — concrete follow-ups this run motivates.

## Index

| Date       | ID                | Domain               | Status                                                                       | Best result          |
|------------|-------------------|----------------------|------------------------------------------------------------------------------|----------------------|
| 2026-07-11 | rust-gui-app      | Rust GUI             | Iter-1 complete, iter-2 partial (cuota cut)                                  | MiniMax-M3 42/50     |
| 2026-07-12 | rust-gui-app-v3   | Rust GUI             | Iter-1 complete (sintesis_central, steps 3/4/7/8 synthetic), iter-2 partial (1/12 propuesta) | integradora 46/50 (v0.3 sintesis_central) |
| 2026-07-13 | rust-gui-popup-v5 | Rust GUI             | 52-agent iter-1, step_5_modo:skip, validacion_empirica:false, 0 descalificadas, 26 ⚠️ | minimax-baseline-08 41/50 (gtk4 0.10) |
| 2026-07-13 | fib-rust-cli-v6   | Rust CLI             | 6-baseline iter-1, sintesis_central+validacion_empirica end-to-end, 0 descalificadas, 2 ⚠️ | integradora 45/50 (9.8/10 viabilidad) |
| 2026-07-15 | moodle-quiz-extractor-v7 | Firefox WebExtension | 21-agent iter-1 (8 baselines + 6 Grupo B + 6 Grupo C + 1 external), sintesis_central+validacion_empirica end-to-end, 1 descalificada (T05K50), 1 sin validación (baseline-02), 13 defectos detectados | propuesta-minimax-T15 43/50 (8.99/10, first T-variant to win; integradora ranked 16/22 with AP=1) |

## Why a separate log file for each run

- **Reproducibility**: the exact `orquestador.json` and full output
  corpus are too big for a CHANGELOG entry.
- **Cross-run comparison**: cost-per-model, ROI rankings, and
  cross-pollination patterns change run-to-run. A separate log lets us
  compare two runs side by side without mixing data.
- **Paper writing**: the entries here are the raw material for any
  paper draft in `docs/papers/`.
