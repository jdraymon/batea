"""Core data types shared by every backend, the CLI, and the MCP server.

The summary format is a contract: benchmark scoring depends on it.
Change it only with a decision record in docs/decisions/.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class QuestionKind(str, Enum):
    CHOICE = "choice"  # pick one of N options
    SCORE = "score"  # position on an ordered rubric
    NOUL = "noul"  # probability a yes/no statement is true


@dataclass(frozen=True)
class Question:
    key: str
    kind: QuestionKind
    instructions: str
    # Choice: option name -> description. Score: ordered level labels.
    # Noul: {"true": ..., "false": ...} criteria.
    options: dict[str, str] | list[str] = field(default_factory=dict)


@dataclass(frozen=True)
class Answer:
    """One backend answer for one record and one question."""

    question_key: str
    value: str | float  # chosen option, expected score, or P(true)
    probabilities: dict[str, float] = field(default_factory=dict)
    confidence: float | None = None


@dataclass(frozen=True)
class Exemplar:
    record_id: str
    timestamp: str | None
    text: str
    answers: dict[str, Answer]


@dataclass
class SweepSummary:
    """What the agent sees. Keep it small."""

    records_scanned: int
    counts: dict[str, dict[str, int]]  # question key -> answer -> count
    histogram: list[tuple[str, int]]  # (time bucket start, match count)
    exemplars: list[Exemplar]
    matches_path: str  # full match set on disk, for follow-up filtering
    backend: str
    cost_usd: float | None = None
