# ADR-007 — DynamoDB for memory; no separate memory service

**Status:** Accepted — 18 Nov 2026

## Context

Agents need short-term memory (this run) and long-term memory (past incidents). Managed memory services exist, but they are another bill and another API.

## Decision

DynamoDB table `apa-memory`, on-demand, inside the always-free allowance. Short-term notes are written per run; long-term lessons are explicit records, not embeddings. Approvals are NOT stored here — they live in `apa-approvals` (ADR-011), in a separate trust boundary.

## Alternatives considered

- **Bedrock AgentCore Memory** — managed and good, but pay-per-use and it would hide the memory design the portfolio is meant to show.
- **Postgres for memory too** — possible, but mixing run memory into the analytics database blurs the boundary the architecture is trying to teach.
- **Files on disk / in S3** — free, but no querying and no story about memory as a system component.

## Consequences

Memory is a visible, testable design: the Phase 3 test proves a lesson changes the diagnosis. Cost: DynamoDB's data model (partition/sort keys) must be learned in Phase 3 — it is scoped to one table and one access pattern, deliberately.
