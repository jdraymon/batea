"""Backend interface. Everything model-specific lives behind this."""

from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Sequence

from pan.models import Answer, Question


class Backend(ABC):
    name: str

    @abstractmethod
    def ask(self, records: Sequence[str], questions: Sequence[Question]) -> list[dict[str, Answer]]:
        """Answer every question for every record.

        Returns one dict per record, keyed by question key, in input order.
        Implementations handle their own batching, windowing, and retries.
        """

    def cost_usd(self) -> float | None:
        """Cumulative cost of calls made by this instance, if known."""
        return None
