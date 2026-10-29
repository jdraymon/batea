# Benchmark agent configs

These define everything the agent under test can see. Do not edit them during development.

- `baseline/`: no skill, no sweep tool
- `sweep/`: the debug-loop skill and the sweep MCP server, nothing else

Changes here change the experiment. Record a decision before touching them.
