"""Thin MCP server over the pan library (Streamable HTTP or stdio).

Exposes one tool, `sweep`, with the same inputs as the CLI and the
SweepSummary as its result. No logic lives here; it calls pan/.

TODO(phase 3): implement with the official MCP Python SDK.
"""
