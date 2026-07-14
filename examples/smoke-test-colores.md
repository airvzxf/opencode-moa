# Smoke Test Example

The fastest way to verify that `opencode-moa` is installed and working correctly.

## Prerequisites

- `opencode-moa` installed (see [`../docs/installation.md`](../docs/installation.md))
- At least the 3 default models configured: `glm-5.1`, `kimi-k2.6`, `minimax-m3:thinking`

## Run the smoke test

From any directory (or from inside OpenCode), run:

```
/orquestar --smoke-test=true "test" smoke
```

## What happens

1. **Step 0** (init): The orchestrator reads `~/.config/opencode/orquestador.json`, validates the 3 model agents exist, and creates `out/smoke/iter-1/`.

2. **Step 1** (proposals): Three `task` calls run in parallel, one per model. Each model generates a short proposal listing the 7 colors of the rainbow.

3. **Step 2** (validation): The validator checks if any commands in the proposals are executable (in this case, none — the proposals are too simple).

4. **Step 3** (evaluation): The evaluator grades the 3 proposals. All should score high (probably 45-50/50) because the task is trivial.

5. **Step 4** (classification): The synthesizer produces a ranking. Likely all 3 are tied or very close.

6. **Step 5** (improvement): Each model produces an "improved" proposal (also listing the 7 colors, possibly with formatting).

7. **Step 6** (validation of improved): Same as step 2.

8. **Step 7** (re-evaluation): Re-grades the improved proposals.

9. **Step 8** (winner selection): Picks the winner.

10. **Step 9** (summary): Writes `out/smoke/iter-1/09-sumario.md` with the final result.

## Expected output

The orchestrator creates THREE sibling directories per iteration.
For the smoke test, only the `out/` directory will have content —
`work/` and `logs/` will exist but stay empty (or near-empty) since
the proposal agents have no empirical work to do:

```
out/smoke/iter-1/
├── 01-propuesta-glm.md       (~30 lines, lists 7 colors)
├── 01-propuesta-kimi.md      (~30 lines, lists 7 colors)
├── 01-propuesta-mimo.md      (~30 lines, lists 7 colors)
├── 02-validacion-glm.md      (minimal, no commands to validate)
├── 02-validacion-kimi.md
├── 02-validacion-mimo.md
├── 03-calificacion-evaluador.md  (~80 lines, grades all 3)
├── 04-clasificacion.md       (ranking table)
├── 05-mejorada-glm.md        (~30 lines)
├── 05-mejorada-kimi.md
├── 05-mejorada-mimo.md
├── 06-validacion-mejorada-glm.md
├── 06-validacion-mejorada-kimi.md
├── 06-validacion-mejorada-mimo.md
├── 07-calificacion-final.md  (~80 lines)
├── 08-ganador.md             (winner announcement)
└── 09-sumario.md             (final summary with score)

work/smoke/iter-1/            (created but empty for the smoke test)
logs/smoke/iter-1/            (one empty .log file per subagent)
```

Total: 16 `.md` files in `out/` + 10 (possibly empty) `.log` files
in `logs/` + empty `work/` subdirs.

## Success criteria

- [ ] All 16 `.md` files are generated in `out/smoke/iter-1/`
- [ ] `out/smoke/iter-1/09-sumario.md` contains a winner name and score
- [ ] `logs/smoke/iter-1/` has one `.log` file per subagent invocation (10 files total)
- [ ] `work/smoke/iter-1/` exists with the 10 subagent subdirs (may be empty for the smoke test)
- [ ] The session log shows all 10 steps completed
- [ ] No error messages in the OpenCode output

## Cost

Approximate token usage:
- 3 proposals × ~500 tokens = 1,500 tokens (input + output)
- 3 validations × ~200 tokens = 600 tokens (mostly SKIP since no commands)
- 1 evaluation × ~2,000 tokens = 2,000 tokens (input + output)
- 1 classification × ~500 tokens = 500 tokens
- 3 improvements × ~500 tokens = 1,500 tokens
- 3 validations × ~200 tokens = 600 tokens
- 1 re-evaluation × ~2,000 tokens = 2,000 tokens
- 1 winner selection × ~300 tokens = 300 tokens
- Summary writing ~200 tokens

**Total**: ~9,200 tokens across all models. Should cost less than $0.05 with most providers.

## If the smoke test fails

1. Check `~/.config/opencode/agents/` has all 7 agent files
2. Check `~/.config/opencode/orquestador.json` is valid JSON: `python3 -m json.tool < ~/.config/opencode/orquestador.json`
3. Check your model providers are configured in OpenCode: `/connect` in the TUI
4. Re-run with explicit flags: `/orquestar --smoke-test=true --max-iter=1 --no-validation "test" smoke`
5. Check OpenCode's session log for error messages

## Next steps

After the smoke test passes, try a real prompt:

```
/orquestar "Design a REST API for inventory management with JWT auth" auth-jwt
```

Or with iterate mode:

```
/orquestar-iterate "Design a complex system with multiple components" complex-system
```

See [`auth-jwt-rest-api.md`](auth-jwt-rest-api.md) for a full example.