# 0003: Agent under test is Claude Code headless on Sonnet 5.5

- **Date:** 2026-10-29
- **Decision:** The agent under test is Claude Code in headless mode with `--model claude-sonnet-5-5`. The model is pinned by alias only; each run records the model reported in its stream-json `init` event. The Claude Code version is pinned in the per-arm container image, and each run records the image digest. All arms in the pilot and main batch use the same image and alias.
- **Why:** Sonnet is the model most Claude Code users run, and its cost per run fits the budget better than Opus. The alias is the only model control the API offers, so recording what each run reports is the best available check that runs are comparable. Pinning in the image keeps Claude Code from changing during a batch.
- **Reverse if:** the pilot shows Sonnet solves almost no cases in any arm (a floor effect), or measured $/run leaves fewer than about 3 runs per cell.
