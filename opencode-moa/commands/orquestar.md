---
description: Orchestrate a complete multi-model competition (10 steps)
agent: orquestador
model: minimax-coding-plan/MiniMax-M3
subtask: true
---

Execute the complete multi-model competition.

Arguments:
- $1 = user prompt (in quotes if it has spaces)
- $2 = id (optional; if missing, the orchestrator slugifies $1)

Optional flags (parsed by the orchestrator):
- --force — deletes {id}/ before starting (the entire per-run tree)
- --no-validation — disables validation steps (2 and 6)
- --step-5-modo={sintesis_central|self_improve|skip} — overrides the `step_5_modo` config field for this run
- --multi-eval={true|false} — overrides the `multi_eval` config field for this run

Behavior:
1. Read and merge orquestador.json (user + project + args)
2. Validate configuration
3. Execute steps 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
4. Write {id}/orquestador/proposal/09-sumario.md with final score
5. Show summary to user

Examples:
/orquestar "Design a REST API for inventory management with JWT auth" auth-jwt
/orquestar "List the 7 colors of the rainbow in order"  # id auto-slugified: "list-the-7-colors"
/orquestar --force "Redo the calculation" calc-v2
/orquestar --step-5-modo=sintesis_central --multi-eval=false "Design a Rust CLI" rust-cli-v1

Expected output (v1.6 layout: `{id}/{subagent}/{proposal,work,log}/`):
- {auth-jwt}/orquestador/proposal/03-calificacion-evaluador.md
- {auth-jwt}/orquestador/proposal/04-clasificacion.md
- {auth-jwt}/orquestador/proposal/05-propuesta-integrada.md
- {auth-jwt}/orquestador/proposal/07-calificacion-final.md
- {auth-jwt}/orquestador/proposal/08-ganador.md
- {auth-jwt}/orquestador/proposal/09-sumario.md
- {auth-jwt}/propuesta-glm/proposal/01-propuesta-glm.md
- {auth-jwt}/propuesta-kimi/proposal/01-propuesta-kimi.md
- {auth-jwt}/propuesta-mimo/proposal/01-propuesta-mimo.md
- ... (one folder per agent in agentes_a_competir)