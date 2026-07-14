# Full Example: REST API with JWT Authentication

A complete walkthrough of using `opencode-moa` for a real-world prompt.

## The prompt

```
Design a REST API for inventory management with JWT authentication.

Requirements:
- CRUD operations for products (id, name, quantity, price)
- User registration and login (with bcrypt password hashing)
- JWT token issuance and validation
- Role-based access control (admin, user)
- SQLite database for simplicity
- Express.js or Fastify framework
- Clear documentation of all endpoints
- Sample curl commands for testing
```

## Run

```
/orquestar-iterate "Design a REST API for inventory management with JWT auth, with CRUD for products, user registration/login with bcrypt, JWT tokens, role-based access control (admin/user), SQLite database, Express.js or Fastify, full endpoint documentation, and sample curl commands for testing" auth-jwt
```

Note: the prompt is detailed because the `propuesta` agents produce better proposals with more context. The id is `auth-jwt`.

## Expected flow

### Step 0 — Initialization

The orchestrator:
1. Reads `~/.config/opencode/orquestador.json` (3 models, max 3 iter, threshold 0.5)
2. Validates id `auth-jwt` matches regex `^[a-z0-9][a-z0-9-]{2,29}$` ✓
3. Verifies 3 propuesta agents exist
4. Creates `out/auth-jwt/iter-1/`
5. todowrite: [step 1-9]

### Step 1 — Proposals (parallel)

Three proposals are generated simultaneously:
- `out/auth-jwt/iter-1/01-propuesta-glm.md` — GLM-5.1's design
- `out/auth-jwt/iter-1/01-propuesta-kimi.md` — Kimi K2.6's design
- `out/auth-jwt/iter-1/01-propuesta-mimo.md` — MiniMax-M3-thinking's design

Each proposal includes:
- Executive summary
- Architecture (folder structure, modules)
- Tech stack (Express vs Fastify, JWT library, ORM choice)
- Database schema
- API endpoints (REST routes)
- Authentication flow
- Installation commands (e.g., `npm init`, `npm install express jsonwebtoken bcrypt better-sqlite3`)
- Security considerations
- Sample curl commands

### Step 2 — Empirical validation (parallel)

The validator runs each proposal's commands:
- `command -v node` — check Node.js installed
- `node --version` — check version >= 18
- `command -v npm` — check npm
- `npm init -y` — verify package.json can be created
- `npm install express` — verify installation succeeds
- `npm install jsonwebtoken bcrypt better-sqlite3` — verify dependencies
- `node --check server.js` — verify JS syntax (if a code snippet is included)
- `curl -sI https://www.npmjs.com/package/express` — verify package exists on npm

Each command's result is captured. The validator reports viability **per section**:
- Installation: 9/10 (works, minor warnings)
- External endpoints: 10/10 (npm registry responds)
- Code snippet: 8/10 (syntax OK, minor style suggestions)
- Environment assumptions: 10/10 (Node 18+ available)

Global viability: 9/10. Verdict: ✅ VIABLE.

### Step 3 — Evaluation

The evaluator grades each proposal with criteria:
- TQ (Technical Quality): 0-10
- CO (Completeness): 0-10
- AP (Applicability): 0-10
- SE (Security): 0-10
- IN (Innovation): 0-10

Example scores (hypothetical):
| Proposal | TQ | CO | AP | SE | IN | Total | Viability |
|---|---|---|---|---|---|---|---|
| glm-5.1 | 9 | 8 | 9 | 8 | 7 | 41/50 | 9/10 |
| kimi-k2.6 | 8 | 9 | 8 | 9 | 8 | 42/50 | 8/10 |
| mimo-m3 | 9 | 9 | 9 | 9 | 9 | 45/50 | 9/10 |

The evaluator adjusts AP based on the per-section viability reports. Since all proposals are highly viable, AP is full.

### Step 4 — Classification

The synthesizer produces a ranking. With these hypothetical scores:
1. 🥇 minimax-m3 (45/50)
2. 🥈 kimi-k2.6 (42/50)
3. 🥉 glm-5.1 (41/50)

### Step 5 — Improvement (parallel)

Each model receives its own proposal + feedback from the evaluator and produces an "improved" version. Improvements typically include:
- Better error handling
- More comprehensive input validation
- Better SQL queries (avoiding N+1)
- Additional security middleware (helmet, cors, rate-limit)
- More sample curl commands

### Step 6 — Validation of improved

Same as step 2 but for the improved proposals.

### Step 7 — Re-evaluation

The evaluator grades the improved proposals. New hypothetical scores:
| Proposal | TQ | CO | AP | SE | IN | Total | Viability |
|---|---|---|---|---|---|---|---|
| glm-5.1 (improved) | 9 | 9 | 9 | 9 | 8 | 44/50 | 9/10 |
| kimi-k2.6 (improved) | 9 | 9 | 9 | 9 | 9 | 45/50 | 9/10 |
| mimo-m3 (improved) | 10 | 10 | 10 | 9 | 9 | 48/50 | 10/10 |

### Step 8 — Winner selection

The synthesizer selects the winner. Hypothetically: minimax-m3 with 48/50.

The winner file `08-ganador.md` includes:
- Winner: minimax-m3
- Total score: 48/50
- Empirical viability: 10/10
- Decision analysis: explains why this proposal won
- Winning proposal: full text of `05-mejorada-mimo.md`

### Step 9 — Summary

The orchestrator writes `09-sumario.md` with:
- Final score and winner
- Iteration 1 metrics
- Convergence status (since we used iterate mode)

## Iterate decision

Since this is `/orquestar-iterate` mode, after step 9:

- Current score: 48/50
- Previous score: 0 (first iteration)
- Improvement: 48 - 0 = 48
- Threshold: 0.5

`48 >= 0.5` → CONTINUE to iteration 2.

### Iteration 2

The orchestrator starts a new iteration, this time with the winner as a seed (via `--iterative-seed` env var, handled by the propuesta agents).

The 3 models now produce proposals that:
- Build on minimax-m3's improved design
- Add additional features or refinements
- Try to address any remaining weaknesses

The full flow repeats: validate, evaluate, classify, improve, re-validate, re-evaluate, select winner.

### Iteration 2 hypothetical outcome

- mimo-m3 iter-2 score: 49/50 (improved by 1 point)
- Improvement: 49 - 48 = 1
- Threshold: 0.5

`1 >= 0.5` → CONTINUE to iteration 3.

### Iteration 3 hypothetical outcome

- mimo-m3 iter-3 score: 49/50 (no change)
- Improvement: 49 - 49 = 0
- Threshold: 0.5

`0 < 0.5` → **CONVERGED. STOP.**

## Final output

After 3 iterations, each of `out/auth-jwt/`, `work/auth-jwt/`, and
`logs/auth-jwt/` contains:
```
iter-1/  (16 files, winner mimo-m3 with 48/50)
iter-2/  (16 files, winner mimo-m3 with 49/50)
iter-3/  (16 files, winner mimo-m3 with 49/50, same as iter-2)
```

The `out/` directory is the canonical pipeline output. The
matching `work/auth-jwt/iter-N/` holds each subagent's private
empirical artifacts (cargo scaffolds, downloaded dependencies,
intermediate test code, compiled binaries) — naming mirrors `out/`:
e.g. `out/auth-jwt/iter-3/01-propuesta-mimo.md` ↔
`work/auth-jwt/iter-3/01-propuesta-mimo/`. The `logs/auth-jwt/iter-N/`
directory holds the bash session log captured for each subagent
(e.g. `logs/auth-jwt/iter-3/01-propuesta-mimo.log`).

Total: 48 `.md` files in `out/` plus per-subagent work dirs in
`work/` (most empty; the one with the winning implementation may
hold 50–200 MB of `node_modules/` and the compiled server) plus
per-subagent `.log` files in `logs/`. The iter-3 `09-sumario.md`
contains the final winner and convergence status.

## Cost estimate

Approximate token usage across 3 iterations:
- Per iteration: ~25,000 tokens (detailed proposal + 3 evaluations + improvements)
- 3 iterations: ~75,000 tokens total
- Cost (varies by provider): $0.20-$1.00

For cheaper experiments, reduce `max_iteraciones` to 2 or increase `umbral_convergencia` to 1.0.

## Next steps

After getting the winning proposal:

1. **Read it**: `cat out/auth-jwt/iter-3/05-mejorada-mimo.md`
2. **Implement it**: follow the architecture and commands in the proposal
3. **Test it**: use the sample curl commands to verify
4. **Iterate manually**: if you want more improvements, run another `/orquestar-iterate` with a more detailed prompt

## Variations to try

- **Different models**: edit `orquestador.json` to add `opencode-go/claude-sonnet-4` to `modelos_a_competir` and create a matching agent
- **Stricter validation**: set `"descalificar_fallida": true` in `orquestador.json`
- **Smoke test mode**: set `"smoke_test": "auto"` for small prompts
- **More iterations**: set `"max_iteraciones": 5` for complex prompts