# Benchmark

## Protocol (draft; changes need a decision record)

1. **Cases.** RCAEval RE2 and RE3. Start with 5 cases across fault types; grow once the harness is stable.
2. **Arms.**
   - `baseline`: Claude Code, headless, with Bash (grep, jq, DuckDB). Config in `configs/baseline/`.
   - `sweep`: same, plus the `sweep` tool and the debug-loop skill. Config in `configs/sweep/`.
3. **Prompt.** Identical in both arms: the case's telemetry paths, the system description, and "find the root-cause service and mechanism." No hints from the labels.
4. **Isolation.** Each run starts in a fresh directory containing only the case data and its arm's config. No repo CLAUDE.md, no user settings, no memory.
5. **Runs.** 5 or more per case per arm.
6. **Hypothesis.** Write the expected result in `docs/decisions/` before each batch.

## Metrics per run

- Total tokens (input, output, cache), from the run's usage log
- Wall time
- Tool calls, and sweep cost in USD
- Root cause correct: service (exact match to the label), mechanism (graded against a fixed rubric)

## Layout

```
datasets/   RCAEval loader and case index
runner/     launches runs, collects usage logs into results/raw/<run-id>/
scoring/    turns raw logs into results/summary/*.csv
configs/    baseline/ and sweep/ agent configs (isolated)
```
