"""Jev backend (TypeSafe AI, hosted).

TODO(spike): verify request and response shapes against the current docs
at docs.typesafe.ai before relying on this. Record a fixture of a real
response under tests/fixtures/ and test against that, not the live API.
"""

from __future__ import annotations

import os
from collections.abc import Sequence

from pan.backends.base import Backend
from pan.models import Answer, Question


class JevBackend(Backend):
    name = "jev"

    def __init__(self, model: str = "jev-latest") -> None:
        # Imported lazily so the package installs without the SDK.
        from typesafe_sdk import TypeSafeClient  # type: ignore[import-not-found]

        if not os.environ.get("TYPESAFE_API_KEY"):
            raise RuntimeError("TYPESAFE_API_KEY is not set")
        self._client = TypeSafeClient()
        self._model = model
        self._cost = 0.0

    def ask(self, records: Sequence[str], questions: Sequence[Question]) -> list[dict[str, Answer]]:
        # One call per record: all questions answered in parallel against one state.
        # TODO(spike): batch several records per call if the API allows, to cut latency.
        raise NotImplementedError("Implement during the spike, against a recorded fixture.")

    def cost_usd(self) -> float | None:
        return self._cost
