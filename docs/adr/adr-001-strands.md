# ADR-001 — Strands Agents SDK as the agent framework

**Status:** Accepted — 18 Nov 2026

## Context

The system needs a model-driven agent loop, MCP tool consumption, multi-agent patterns, human-approval interrupts, and tracing — and the builder is learning, so the framework must not demand framework expertise first.

## Decision

Use Strands Agents SDK (Python), with Amazon Bedrock as the model provider.

## Alternatives considered

- **LangGraph** — explicit graph control and the best debugging story, but every step is hand-wired, which is more framework to learn before the first agent runs.
- **Bedrock Agents (managed)** — no code, but the learning goal is the code, and console configuration cannot be reviewed in a repo.
- **Raw boto3 + hand-rolled loop** — maximum learning about the loop, but re-implements retries, tool parsing and interrupts badly.

## Consequences

Fastest path to a working agent; MCP and A2A are native, not adapters. Cost: the agent loop's behaviour is partly the framework's, so the plan includes reading the loop code in Phase 2 rather than treating it as magic. Revisit if: Strands cannot express the approval handoff cleanly in Phase 4 — LangGraph is the named fallback.
