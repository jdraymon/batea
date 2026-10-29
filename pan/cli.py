"""Command-line entry point.

Planned usage:

    pan run --input logs.jsonl --questions questions.yaml \
        --since 2026-01-01T10:00 --until 2026-01-01T10:15 \
        --backend jev --out results/matches/

Prints a SweepSummary as compact JSON on stdout. That output is what the
agent reads, so keep it small.
"""

from __future__ import annotations

import argparse


def main() -> None:
    parser = argparse.ArgumentParser(prog="pan")
    sub = parser.add_subparsers(dest="cmd", required=True)

    run = sub.add_parser("run", help="sweep telemetry with typed questions")
    run.add_argument("--input", required=True)
    run.add_argument("--questions", required=True)
    run.add_argument("--since")
    run.add_argument("--until")
    run.add_argument("--backend", default="jev", choices=["jev"])
    run.add_argument("--exemplars", type=int, default=8)
    run.add_argument("--out", default="matches/")

    args = parser.parse_args()
    raise SystemExit(f"'{args.cmd}' is not implemented yet (spike, week 1).")


if __name__ == "__main__":
    main()
