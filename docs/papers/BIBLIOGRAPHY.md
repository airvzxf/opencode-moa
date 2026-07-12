# Bibliography

References relevant to `opencode-moa` and the multi-model orchestration
line of work. Citation keys are short strings (e.g. `[wang2024moa]`);
use them in `docs/papers/DRAFT-multi-model-orchestration.md`.

## Primary

- `[wang2024moa]` Wang, J., et al. (2024). **Mixture-of-Agents: Enhancing
  Large Language Model Capabilities through Collaborative
  Multi-Agent Systems.** *arXiv preprint.* [arXiv:2406.04692]
  (https://arxiv.org/abs/2406.04692). The foundational paper that
  demonstrated that stacking heterogeneous LLM layers in series yields
  AlpacaEval 2.0 scores above any single model in the ensemble.
  Establishes the "diversity of mental models > best single model" thesis
  that opencode-moa builds on. opencode-moa differs in that the
  iteration structure is horizontal (one prompt per round, N rounds)
  rather than vertical (one stack per query); the two are
  complementary rather than competing.

- `[together2024moa]` Together AI Blog (2024). **Mixture-of-Agents (MoA)
  — architecture diagram and benchmarks.**
  (https://www.together.ai/blog/moa). Companion blog to `[wang2024moa]`
  with engineering diagrams. Useful for `opencode-moa` readers who
  haven't read the paper but want a visual overview of the
  multi-layer composition idea.

## Multi-agent debate and role-based collaboration

- `[du2023improvingfactualityreasoning]` Du, Y., et al. (2023).
  **Improving Factuality and Reasoning in Language Models through
  Multiagent Debate.** *arXiv preprint.* [arXiv:2305.14325]
  (https://arxiv.org/abs/2305.14325). Shows that two agents debating
  over a question produce more factual answers than either alone.
  `opencode-moa`'s step 8 (winner selection by the synthesizer after
  per-criterion scoring) is a structured form of this; we don't have
  free-form debate across all 12, but the synthesizer's justification
  paragraph in `08-ganador.md` does engage competing proposals.

- `[hong2023metagpt]` Hong, S., et al. (2023). **MetaGPT: Meta
  Programming for a Multi-Agent Collaborative Framework.**
  *arXiv preprint.* [arXiv:2308.00352]
  (https://arxiv.org/abs/2308.00352). Introduces role-based
  multi-agent collaboration (ProductManager, Architect, Engineer,
  QA). `opencode-moa` keeps roles **distinct and singular** — one
  agent = one purpose = one model — rather than multi-role agents.
  This is intentional: it reduces interference between role
  instructions and matches the common "ten specialized agents > one
  multi-role agent" empirical pattern.

- `[wu2023autogen]` Wu, Q., et al. (2023). **AutoGen: Enabling Next-Gen
  LLM Applications via Multi-Agent Conversation.** *arXiv preprint.*
  [arXiv:2308.08155](https://arxiv.org/abs/2308.08155). Foundational
  framework for multi-agent programming. `opencode-moa` borrows the
  `Director + Worker` topology but replaces Python with markdown.
  Specifically, `opencode-moa` argues that for small orchestrations
  (≤ 12 agents, ≤ 15 steps), the engineering tax of a programming
  framework dwarfs the algorithmic benefit. AutoGen remains the right
  choice for larger orchestration shapes.

## Compiling / orchestration frameworks

- `[khattub2023dspy]` Khattab, O., et al. (2023). **DSPy: Compiling
  Declarative Language Model Calls into Self-Improving Pipelines.**
  *arXiv preprint.* [arXiv:2310.03714]
  (https://arxiv.org/abs/2310.03714). Treats orchestration as a
  compilation problem (modules + signatures + teleprompters).
  `opencode-moa` and DSPy are complementary: DSPy optimizes prompt
  strings programmatically; `opencode-moa` relies on the orchestrator
  agent's reasoning to choose modules. For zero-code iteration, the
  latter; for production retries and metric-driven optimization, the
  former.

- `[anthropic2024claude]` Anthropic (2024). **The Claude 3 Model
  Family.** (https://www.anthropic.com/news/claude-3-family). Cited
  here not for the model itself but for Anthropic's "Constitutional
  AI" framing: rules-as-text that shape agent behavior. `opencode-moa`'s
  `orquestador.md` is exactly this — natural-language rules governing
  an agent's behavior across steps.

## Native agent platforms

- `[opencode]` sst/opencode (2024-2026). **OpenCode — AI coding
  agent.** (https://opencode.ai). The CLI tool that hosts
  `opencode-moa` as native agents. OpenCode's `mode: primary` and
  `mode: subagent` distinction, its `task` subagent invocation
  mechanism, and its slash-command engine are what allow
  `opencode-moa` to ship as a pure-markdown bundle without external
  runtimes. The `CLI` docs describe `opencode run --agent <name>` and
  the permission system that gates tool calls; these primitives are
  what `opencode-moa`'s "zero bash" and "model declared per agent"
  rules depend on.

## Misc references

- `[anthropic2025anthropicproviderpricing]` Provider pricing for the
  models used in the 2026-07-11 experiment: see each provider's
  public pricing page (Anthropic, OpenAI, MiniMax, etc.). The bundle
  does not depend on specific rates; the cost table in
  `docs/research/experiments/2026-07-11-rust-gui-app.md` is a raw
  observation, not a commitment.

## How to add new references

When you read a paper or blog post that informs this line of work, add
it here with:

1. A citation key `[authorYYYYkeyword]` matching the format above.
2. Full bibliographic info (authors, year, title, arXiv ID if any).
3. A 2-4 sentence note on **why it matters to opencode-moa** (not a
   generic abstract — what specifically does it inform or conflict
   with).
4. Then cite it in `DRAFT-multi-model-orchestration.md` (and any
   future papers) with the key in square brackets.
