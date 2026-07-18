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
/orquestar "Design a REST API for inventory management with JWT auth, with CRUD for products, user registration/login with bcrypt, JWT tokens, role-based access control (admin/user), SQLite database, Express.js or Fastify, full endpoint documentation, and sample curl commands for testing" auth-jwt
```

Note: the prompt is detailed because the `propuesta` agents produce better proposals with more context. The id is `auth-jwt`.

## Expected flow

### Step 0 — Initialization

The orchestrator:
1. Reads `~/.config/opencode/orquestador.json` (3 models by default)
2. Validates id `auth-jwt` matches regex `^[a-z0-9][a-z0-9-]{2,29}$` ✓
3. Verifies 3 propuesta agents exist
4. Creates `out/auth-jwt/`
5. todowrite: [step 1-9]

### Step 1 — Proposals (parallel)

Three proposals are generated simultaneously:
- `out/auth-jwt/01-propuesta-glm.md` — GLM-5.1's design
- `out/auth-jwt/01-propuesta-kimi.md` — Kimi K2.6's design
- `out/auth-jwt/01-propuesta-mimo.md` — MiniMax-M3-thinking's design

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
- Run metrics

## Final output

After the run, each of `out/auth-jwt/`, `work/auth-jwt/`, and
`logs/auth-jwt/` contains the 16 pipeline files (winner mimo-m3 with
48/50 in this hypothetical example):

```
out/auth-jwt/
├── 01-propuesta-glm.md
├── 01-propuesta-kimi.md
├── 01-propuesta-mimo.md
├── 02-validacion-glm.md
├── 02-validacion-kimi.md
├── 02-validacion-mimo.md
├── 03-calificacion-evaluador.md
├── 04-clasificacion.md
├── 05-mejorada-glm.md
├── 05-mejorada-kimi.md
├── 05-mejorada-mimo.md     ← the winning improved proposal
├── 06-validacion-mejorada-glm.md
├── 06-validacion-mejorada-kimi.md
├── 06-validacion-mejorada-mimo.md
├── 07-calificacion-final.md
├── 08-ganador.md
└── 09-sumario.md
```

The `out/` directory is the canonical pipeline output. The matching
`work/auth-jwt/` holds each subagent's private empirical artifacts
(cargo scaffolds, downloaded dependencies, intermediate test code,
compiled binaries) — naming mirrors `out/`: e.g.
`out/auth-jwt/01-propuesta-mimo.md` ↔
`work/auth-jwt/01-propuesta-mimo/`. The `logs/auth-jwt/` directory
holds the bash session log captured for each subagent (e.g.
`logs/auth-jwt/01-propuesta-mimo.log`).

Total: 16 `.md` files in `out/` plus per-subagent work dirs in
`work/` (most empty; the one with the winning implementation may
hold 50–200 MB of `node_modules/` and the compiled server) plus
per-subagent `.log` files in `logs/`. The `09-sumario.md` contains
the final winner and score.

## Cost estimate

Approximate token usage for a single run:
- ~25,000 tokens (detailed proposal + 3 evaluations + improvements)
- Cost (varies by provider): $0.10-$0.50

For cheaper experiments, reduce `agentes_a_competir` to a smaller subset
via project-level `orquestador.json`.

## Next steps

After getting the winning proposal:

1. **Read it**: `cat out/auth-jwt/05-mejorada-mimo.md`
2. **Implement it**: follow the architecture and commands in the proposal
3. **Test it**: use the sample curl commands to verify
4. **Re-run with feedback**: if you want more improvements, run another
   `/orquestar` with a more detailed prompt that incorporates what you
   learned from this run

## Variations to try

- **Different models**: edit `orquestador.json` to add another agent to
  `agentes_a_competir` and create the matching `propuesta-{agent}.md`
- **Stricter validation**: set `"descalificar_fallida": true` in
  `orquestador.json`
- **Smoke test mode**: set `"smoke_test": "auto"` for small prompts
- **Integrated synthesis**: set `"step_5_modo": "sintesis_central"` to
  produce one consolidated proposal instead of per-agent improvements
