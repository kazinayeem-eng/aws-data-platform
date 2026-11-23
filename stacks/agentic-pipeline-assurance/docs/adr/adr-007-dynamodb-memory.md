# ADR-007: DynamoDB for agent memory; no separate memory service

**Status:** Accepted — 18 Nov 2026

## Context

Agents need short-term memory for the current run and long-term memory of past incidents. A managed memory service would add another bill and API.

## Decision

Use the on-demand DynamoDB table `apa-memory`. Store short-term notes per run and long-term lessons as explicit records, not embeddings. Keep approvals separate in `apa-approvals` (ADR-011). Agents access memory only through MCP tools such as `save_note` and `recall_lessons`.

## Alternatives

- **Bedrock AgentCore Memory:** Managed, but pay-per-use and hides the memory design.
- **PostgreSQL for memory:** Possible, but mixes run memory with analytics data.
- **Files or S3:** Free, but offer limited querying and a weaker memory-system design.

## Consequences

Memory is a visible, testable design; the Phase 3 test demonstrates a lesson changing a diagnosis. DynamoDB's partition and sort keys must be learned, but the design is limited to one table and one access pattern.
