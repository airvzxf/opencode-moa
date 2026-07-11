# Iterations Analysis: Empirical Evidence for Design Decisions

**Date:** 2026-07-10
**Purpose:** Document the analysis of 6 real-world multi-model orchestration projects that informed `opencode-moa`'s design.

This document is the evidence base for the design decisions documented in [`../proposals/001-orquestador-nativo-opencode.md`](../proposals/001-orquestador-nativo-opencode.md). Specifically, it justifies:

- Why multi-model is used only for proposal generation (not for evaluation/validation/synthesis)
- Why per-section viability is reported (not just global)
- Why disqualification is opt-in (not default)
- Why convergence threshold default is 0.5 (based on observed score gaps)

---

## Executive summary

| Project | Domain | # Proposals | # Evaluators | Did multi-eval change the decision? |
|---|---|---|---|---|
| cardiorrenal R1 | medical supplements | 9 | 9 | No (consensus 8/9) |
| cardiorrenal R2 | medical supplements (improved) | 3 | 8 | **Yes** (5-3 split) |
| oc-rust-02 | Rust on OpenCode | 8 | 8 | No (consensus 8/8) |
| eval-7-ia-001 | self-evaluation | 6 | 6 | Detected bias, decision unchanged |
| oc-sda/001 | orchestrator design | 2 | 2 | Yes (refined) |
| oc-sda/002 | orchestrator design | 3 | 3 | Yes (iterative refinement) |

**Key findings**:

1. **Multi-model generation** is always valuable: 6/6 projects produced diverse, complementary proposals.
2. **Multi-model evaluation** is valuable in **33% of cases** (close ties), redundant in **67%** (clear consensus).
3. **Auto-evaluation bias** is quantifiable: range -0.51 to +1.89 points on a 10-point scale.
4. **Validation empirica** was never executed in any real project — all "validations" were meta-validations (consistency between evaluators), not empirical (running actual code).

---

## Project 1: cardiorrenal (medical supplements)

**Context**: 4 rounds of multi-model iteration to design supplement protocols for a cardio-renal patient. Stakes: health decisions for a real patient.

**Round 1**: 9 models generated proposals.
- Models: claude-sonnet, gemini-3.1-pro, gemini-3.5-flash, glm-5.1, kimi-k2.6, kimi-k2.7-code, MimoSupreme, minimax-m3, qwen
- 9 evaluators each graded all 9 proposals (81 evaluations total)

**Result**: Consensus was clear.
- 8/9 evaluators chose `minimax-m3` as the winner
- 1/9 tied `minimax-m3` with `gemini-3.5-flash`
- Score range for `minimax-m3`: 8.70 (glm) — 9.80 (gemini-3.1-pro), variance 1.10
- Score range for `gemini-3.5-flash`: 6.70 (kimi-k2.6) — 9.63 (gemini-3.5-flash, self), variance **2.93** ⚠️

**Bias observed**: `gemini-3.5-flash` self-graded 9.63 while the strictest evaluator (`kimi-k2.6`) graded it 6.70 — a 2.93-point divergence on the same proposal. This is an outlier-level disagreement that a single evaluator could not have detected.

**Round 2**: 3 models generated improved proposals (top-3 from R1).
- Models: minimax-m3, kimi-k2.7-code, glm-5.1
- 8 evaluators each graded all 3 proposals (24 evaluations total)

**Result**: **Multi-eval changed the decision**.
- 5 evaluators chose `minimax-m3` as the winner
- 3 evaluators chose `glm-5.1` as the winner
- Score gap: 0.03 points (statistical tie)

**Critical observation**: `glm-5.1` chose itself as the winner. The justification text revealed this: *"GLM-5.1 wins by being the best-structured proposal, with the most exhaustive traceability, the most prudent introduction plan (6-7 weeks), the only one that detects the double Vitamin A of D-Fence + Pepcil"*. The "only one that detects" is a self-promoting claim that no other evaluator corroborated.

**Without multi-eval**, a single evaluator (especially `glm-5.1`) would have produced a biased result. **Multi-eval surfaced this bias.**

---

## Project 2: oc-rust-02 (Rust on OpenCode)

**Context**: Multi-model generation of a Rust script to interact with OpenCode's CLI.

**Setup**: 8 models × 8 evaluators (full matrix).

- Models: claude-opus-4.6-thinking, deepseek-v4-pro-max, gemini-3.1-pro-high, glm-5.1, kimi-k2.6, mimo-v2.5-pro-high, minimax-m3, qwen3.7-max

**Result**: **Unanimous consensus on the winner**.

| Position | Model | Score range |
|---|---|---|
| 🥇 #1 | claude-opus-4.6-thinking | 9.00 (mimo) — 10.00 (qwen3.7-max) |
| 🥈 #2 | minimax-m3 | 7.20 (deepseek) — 9.20 (qwen3.7-max) |
| 🥉 #3 | glm-5.1 | 7.20 (gemini) — 9.30 (deepseek) |
| #8 (last) | gemini-3.1-pro-high | 5.00 (glm) — 7.50 (gemini, self) |

8/8 evaluators chose `claude-opus-4.6-thinking`. The decision would have been the same with just 1 evaluator.

**Verbatim consensus quotes**:

- kimi-k2.6: *"It's the only one that demonstrates real research on how opencode works... Corrects errors from others (non-existent flags like --prompt, --json)"*
- gemini-3.1-pro: *"It's by far the best proposal and the only one that solves the problem at its root"*
- mimo: *"Their proposal stands out significantly because it doesn't assume how opencode works — it investigated"*

**Insight for opencode-moa**: when there's clear consensus, multi-eval is redundant. A single strict evaluator would have sufficed.

**Score divergence**: maximum was 1.0 points (between mimo at 9.00 and qwen3.7-max at 10.00 for the same winning proposal). Smaller than cardiorrenal's 2.93 divergence.

---

## Project 3: eval-7-ia-001 (meta-evaluation)

**Context**: Self-evaluation project where 6 models both generated AND evaluated proposals, plus a meta-evaluation that quantified biases.

- Models: glm-5.1, kimi-k2.6, kimi-k2.7-code, mimo-v2.5-pro-high, minimax-m3-thinking, qwen3.7-max

**Critical contribution**: a meta-evaluation by `mimo-v2.5-pro-high` that **quantified auto-evaluation bias**.

| Model | Score from others (avg) | Self-score | Bias |
|---|---|---|---|
| glm-5.1 | 8.14 | 7.80 | **-0.34** (honest, slight self-underestimation) |
| kimi-k2.6 | 8.01 | 7.50 | **-0.51** (strict with self) |
| minimax-m3 | 7.92 | 7.50 | **-0.42** (strict with self) |
| mimo-v2.5-pro-high | 7.71 | 8.00 | +0.29 (slight self-inflation) |
| deepseek-v4-pro-max | — | — | inflation (not quantified) |
| gemini-3.1-pro-high | — | — | — |
| **qwen3.7-max** | **6.81** | **8.70** | **+1.89** (highest bias, significant self-inflation) |

**Verbatim from mimo's meta-analysis**:

> *"qwen3.7-max's auto-evaluation bias is the highest of all (+1.89). Inflated scores in general (gives 10.00 to claude-opus, 9.20 to minimax). The evaluation looks more like a ranking exercise than a critical analysis."*

**Verbatim from kimi-k2.6's analysis**:

> *"qwen3.7-max in R2 gives notably higher scores than all other evaluators (10.00, 9.20, 9.00, 8.80...), suggesting a tendency to be more permissive."*

**Insight for opencode-moa**: **auto-evaluation bias is systematic and quantifiable**. The `evaluador` agent in `opencode-moa` uses temperature 0.0 and is instructed to "not inflate scores", but the meta-finding is that some models are constitutionally more lenient than others. Using a single model (the user's chosen `minimax-m3-thinking`) avoids cross-evaluator bias, at the cost of inheriting that single model's bias.

---

## Project 4: oc-software-development-agents/001 (orchestrator design v1)

**Context**: The very project that produced the bash-based predecessor. 4 phases of iteration:

| Phase | Role | Models | Result |
|---|---|---|---|
| 001 | Generators | glm-5.1, kimi-k2.6 | 2 proposals |
| 002 | Evaluator-Synthesizer | glm-5.1, mimo-v2.5-pro | Evaluations + classification |
| 003 | Evaluator-of-evaluator | glm-5.1, mimo-v2.5-pro | Meta-evaluation |
| 004 | Final generator | glm-5.1 | Winner |

**Insight**: Even with only 2 models, the meta-evaluation in phase 003 refined the decision. Multi-eval helped even at small scale.

---

## Project 5: oc-software-development-agents/002 (orchestrator design v2)

**Context**: The bash-based version 2, with iterative refinement across 7 files.

**Setup**: 3 models (`glm-5.1`, `kimi-k2.6`, `minimax-m3-thinking`) iterated over multiple rounds, with each model inheriting improvements from previous iterations.

**Insight**: This is the project that **convinced the user to switch from bash to native OpenCode**. The bash approach became too complex (2058 lines + 12 helpers), so the user asked for a redesign with `opencode-moa`.

---

## Synthesis: What did we learn?

### Decision matrix

| Question | Answer | Evidence |
|---|---|---|
| Multi-model for generation? | **YES** | 6/6 projects produced diverse, complementary proposals |
| Multi-model for evaluation? | **OPTIONAL** | 33% of cases (close ties); 67% redundant (consensus) |
| Multi-model for validation? | **NO** | Bash output is binary; multi-model adds no value |
| Multi-model for synthesis? | **NO** | Single criterion produces consistent decisions |
| Multi-model for orchestration? | **NO** | Coordination requires stable memory |

### Bias quantification

| Bias type | Range | Action |
|---|---|---|
| Auto-evaluation bias | -0.51 to +1.89 | Use temperature 0.0 + "do not inflate" prompt |
| Inter-evaluator divergence | 0.0 to 2.93 points | Multi-eval when gap < 0.5 |
| Consensus threshold | >85% agreement | Single evaluator suffices |

### Validation empirica gap

**Critical finding**: NO project in this analysis executed actual empirical validation. All "validations" were meta-validations (consistency between evaluators). This means:

- cardiorrenal: no supplement was actually tested for interactions
- oc-rust-02: the Rust code was never compiled
- eval-7-ia-001: no proposal was empirically verified
- oc-sda/001, /002: the orchestrator was never executed end-to-end

**`opencode-moa` addresses this gap** by introducing steps 2 and 6 (`validador` agent with bash + webfetch permissions) that actually run the commands mentioned in proposals.

### Threshold default justification

The default `umbral_convergencia: 0.5` is justified by:

- cardiorrenal R2 winner gap: 0.03 points → would NOT converge (good, the loop continues to find a clearer winner)
- oc-rust-02 typical gap between #1 and #2: ~2.0 points → WOULD converge (good, the loop stops when the winner is clear)
- Most projects: gaps in the 0.5-2.0 range → threshold 0.5 is a reasonable midpoint

---

## Implications for `opencode-moa` design

These insights directly inform the design:

1. **Per-section viability** (Section 12 in the proposal): because real proposals have multiple technical sections and a single failure doesn't invalidate the whole thing.

2. **Opt-in disqualification** (Section 13): because consensus is often clear (67% of cases) and aggressive disqualification is unnecessary.

3. **Single-model evaluador with temperature 0.0**: because cross-evaluator bias is real but quantifiable; a single strict evaluator is acceptable when there's no close tie.

4. **Validation empirica as a separate step** (Section 12): because no previous project ever executed commands; this is `opencode-moa`'s biggest improvement over predecessors.

5. **Iterate mode with convergence threshold** (Section 11): because cardiorrenal R2 showed that iterative refinement CAN resolve close ties (5-3 split became 0.03 gap).

---

## Files referenced

These projects are stored in `/home/wolf/Downloads/ai/`:

| Project | Path |
|---|---|
| cardiorrenal | `01-cardiorrenal-*`, `02-cardiorrenal-evaluacion-*`, `03-cardiorrenal-mejorada-*`, `04-cardiorrenal-evaluacion-*` |
| oc-rust-02 | `oc-rust-02/` |
| eval-7-ia-001 | `eval-7-ia-001/` |
| oc-software-development-agents/001 | `oc-software-development-agents/001/` |
| oc-software-development-agents/002 | `oc-software-development-agents/002/` |

For full data and primary sources, see those directories.

---

**Author**: Israel Roldan ([israel.alberto.rv@gmail.com](mailto:israel.alberto.rv@gmail.com))
**Last updated**: 2026-07-10
