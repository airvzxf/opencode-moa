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
- --smoke-test={true|false|auto} — overrides smoke_test from config
- --force — deletes out/{id}/ before starting
- --no-validation — disables validation steps (2 and 6)

Behavior:
1. Read and merge orquestador.json (user + project + args)
2. Validate configuration
3. Execute steps 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
4. Write out/{id}/09-sumario.md with final score
5. Show summary to user

Examples:
/orquestar "Design a REST API for inventory management with JWT auth" auth-jwt
/orquestar "List the 7 colors of the rainbow in order"  # id auto-slugified: "list-the-7-colors"
/orquestar --smoke-test=true "Test the pipeline" smoke
/orquestar --force "Redo the calculation" calc-v2

Expected output:
- out/auth-jwt/01-propuesta-glm.md
- out/auth-jwt/01-propuesta-kimi.md
- out/auth-jwt/01-propuesta-mimo.md
- ... (all flow files)
- out/auth-jwt/08-ganador.md
- out/auth-jwt/09-sumario.md