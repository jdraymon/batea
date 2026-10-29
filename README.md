# batea

Debug distributed systems with a coding agent, without pouring raw telemetry into its context.

**Status:** pre-alpha. Nothing here is measured yet.

## The idea

A coding agent (System 2) forms a hypothesis about a fault. A System 1 decision model answers typed questions over logs and traces in milliseconds. The agent gets back counts, a time histogram, and a few exemplars, then decides what to ask next.

When a question fits a structured filter (grep, jq, DuckDB), the agent should write the filter instead. The sweep is for questions no filter can express.

## What this repo will measure

Tokens, wall time, and root-cause accuracy for Claude Code on labeled failure cases from [RCAEval](https://github.com/phamquiluan/RCAEval), in two arms:

| Arm | Agent has |
| --- | --- |
| Baseline | grep, jq, DuckDB |
| Sweep | the baseline tools, plus `sweep` and the debug-loop skill |

Results, scenarios, and raw run logs will be published here, including cases where the sweep made things worse.

## Backends

- **Jev** (TypeSafe AI): hosted, zero-shot
- **Ollama** (planned): a local model such as Clef, for comparison

