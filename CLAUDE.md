# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

A tool that lets coding agents debug distributed systems without reading raw telemetry, plus a benchmark that measures whether it helps.

- `pan/` asks typed questions (Choice, Score, Noul) over logs and traces using a System 1 decision model, and returns a compact summary.
- `bench/` runs headless Claude Code against labeled failure cases (RCAEval) in two arms, and scores tokens, wall time, and root-cause accuracy.

## Layout

```
pan/                CLI and library
  backends/         base.py (interface), jev.py
  models.py         Question, Answer, SweepSummary
  cli.py
pan_mcp/            thin MCP server over the pan library
skills/debug-loop/  SKILL.md shipped to users
bench/
  datasets/         RCAEval loader; data lives in data/ (gitignored)
  runner/           launches benchmark runs
  scoring/          root-cause matching and metrics
  configs/          ISOLATED agent configs for benchmark runs only
results/            raw run logs and summaries
docs/decisions/     one file per decision
```

## Rules

1. **Benchmark isolation.** Never edit `bench/configs/` unless the task explicitly asks for it. Those configs define what the agent under test sees. Benchmark runs must not load this file or any development config.
2. **Never read raw telemetry into context.** Datasets are millions of lines. Inspect them with `head`, `wc`, DuckDB, or `jq`, and read samples only.
3. **Results are append-only.** Never edit or delete files in `results/raw/`. New runs get new directories.
4. **Secrets come from the environment.** API keys are read from env vars, populated from the macOS Keychain locally and from podman secrets in containers (ADR 0004). Never write keys into code, configs, or logs.
5. **Backends are swappable.** Anything backend-specific stays in `pan/backends/`. The CLI, MCP server, and summary format don't know which model ran.
6. **Record decisions.** A change to the sweep output format, scoring method, or benchmark protocol gets a new file in `docs/decisions/`.

## Commands

```
uv sync                 # install
uv run pytest           # tests
uv run ruff check .     # lint
uv run pan --help       # CLI
```

## Conventions

- Python 3.12, type hints throughout, ruff for lint and format.
- Tests for every backend use recorded fixtures; no live API calls in the test suite.
- Keep the summary format stable. Downstream scoring depends on it.
