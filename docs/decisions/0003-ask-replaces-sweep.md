# 0003: System 1 makes decisions over query results; sweep is demoted

- **Date:** 2026-10-29
- **Decision:**
  - The core primitive is `pan ask`. The agent pipes a query result (DuckDB, jq, grep) into `pan ask` with one typed question (Choice, Score, or Noul). It reads back only the answer, its probability, the backend's cost, and pointers to the supporting rows. The query result itself never enters the agent's context.
  - Two S1 roles are in scope. **Distiller:** turn a query result into a decision ("which service shows the anomaly?"). **Judge:** test evidence against a hypothesis ("does this support H?"), and decide whether to stop ("is the root cause established, or keep looking?").
  - Sweep, where S1 labels every telemetry record and returns a histogram and exemplars, becomes an optional mode. It is not in the main path or the benchmark arms.
  - The interface is a CLI. An MCP server is deferred.
- **Why:** The expensive step in an agent's RCA loop is the frontier model reading a large tool result to make what is really a yes/no or few-way decision. That result is billed when it enters the context and again at the cache-read rate on every later turn. A decision model can make that call for a fraction of the cost and return a probability, so the agent can accept confident answers and fall back to reading the raw result when S1 is unsure. Sweep goes after a different cost, bulk reading of telemetry, which a competent agent already avoids with aggregate queries. A CLI used in a pipeline keeps results out of context by construction, and adding an MCP server later is cheap.
- **Not decided here:** Branch prediction (S1 choosing among hypotheses or next steps) is deferred until the role is specified in its own ADR. The Haiku control and the arm definitions get their own ADRs.
- **Reverse if:**
  - Baseline runs show that tool results over about 1k tokens make up a small share of run cost, so there is little to distill.
  - In decision replay, S1 agrees with the label or with Claude's own decision no better than Haiku does at similar cost, or its probabilities are not calibrated well enough to gate escalation.
  - Jev can't take a typical query result (about 5–20k tokens) in one call, and chunking erases the cost advantage.
