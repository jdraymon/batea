# 0001: Benchmark on RCAEval first

- **Date:** 2026-10-26
- **Decision:** Use RCAEval RE2 and RE3 as the first benchmark data. Build a custom fault lab only after the harness works.
- **Why:** Labeled root causes from a third party, so the benchmark isn't graded on data I designed.
- **Reverse if:** the baseline arm finds most root causes in about 3 tool calls, meaning the logs are too clean for a sweep to matter.
