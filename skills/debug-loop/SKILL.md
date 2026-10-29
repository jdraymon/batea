---
name: debug-loop
description: Find the root cause of a distributed-system fault from large logs and traces without reading them into context. Use when telemetry is too large to read and a fault's cause is unknown.
---

# Debug loop

Never read raw telemetry into context. Ask questions of it and read the answers.

## Loop

1. **State a hypothesis** in one sentence: which service, what failed, roughly when.
2. **Pick the cheapest tool that can test it:**
   - The question fits an exact pattern, field, status code, or numeric threshold → write a filter with `grep`, `jq`, or DuckDB.
   - The question needs judgment about free text ("does this line show a retry?", "is this error a symptom or a cause?") → call `sweep`.
3. **Narrow first.** Filter to the fault window and the services involved before sweeping. Sweeps cost money and time per record.
4. **Read the summary:** counts per answer, the time histogram, then the exemplars. Open the full match file only to filter it further.
5. **Decide:** confirm, refute, or refine the hypothesis. Repeat.

## Writing sweep questions

- One fact per question. Ask "does this line show a connection timeout?", not "is this line suspicious?"
- Name the evidence, not the conclusion.
- Choice questions: 8 options or fewer, always including "none of these".
- Ask several questions in one sweep; they share one read of each record.

## Stop when

- One service and one mechanism explain the timeline, and the earliest anomaly sits in that service.
- Or two sweeps in a row add nothing: report what is known and what is not.

## Report

Root-cause service, mechanism, earliest evidence with its timestamp, and the queries that support it.
