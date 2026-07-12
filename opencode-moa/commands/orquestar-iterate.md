---
description: Orchestrate with iterate mode (loop until convergence or max_iterations)
agent: orquestador
model: opencode-go/minimax-m3
subtask: true
---

Execute the multi-model competition in iterate mode.

Arguments:
- $1 = user prompt
- $2 = id (optional)

Same optional flags as /orquestar.

Behavior:
1. Same as /orquestar, but after step 9:
   - Read current iteration's score from sumario
   - Compare with previous iteration's score (if exists)
   - If improvement >= threshold AND N < max_iter: continue to iter N+1
   - Otherwise: stop with consolidated final summary

Examples:
/orquestar-iterate "Design a REST API for inventory management" auth-jwt
/orquestar-iterate --max-iter=5 --convergence=0.3 "Design a complex system" complex

Expected output:
- out/auth-jwt/iter-1/ (all files)
- out/auth-jwt/iter-2/ (all files, if there was sufficient improvement)
- out/auth-jwt/iter-N/ (until convergence)
- out/auth-jwt/iter-N/09-sumario.md with final winner's score