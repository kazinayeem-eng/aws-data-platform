# ADR-005: Lambda for deployed jobs and tools; no EC2

**Status:** Accepted — 18 Nov 2026

## Context

The jobs and tools need a runtime. The Lambda always-free allowance is more than sufficient for this workload.

## Decision

In the deployed Phase 8 topology, run ingest, transform, MCP tool servers, agent runtime, and publisher as Lambda functions. During Phases 1–7, run those components locally on the Mac as described in ADR-004 and ADR-012. The approval endpoint is a Lambda in every phase. Do not use EC2.

## Alternatives

- **Bedrock AgentCore Runtime:** Managed, but pay-per-use and hides the runtime the portfolio is meant to demonstrate.
- **EC2 `t3.micro`:** Familiar, but requires patching and incurs idle cost.
- **ECS/Fargate:** Appropriate at larger scale, but excessive for one nightly run.

## Consequences

There is no idle compute cost. Lambda's 15-minute limit constrains transforms, so the seeded load is sized to finish in under five minutes. Human approval waits in Step Functions, not inside a Lambda. Revisit if a phase needs a long-running process.
