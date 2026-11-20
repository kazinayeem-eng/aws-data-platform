# ADR-005 — Lambda for every job and tool; no EC2, no AgentCore Runtime as primary

**Status:** Accepted — 18 Nov 2026

## Context

Jobs and tools need somewhere to run. The always-free Lambda allowance (1M requests + 400,000 GB-seconds/month) covers this workload many times over.

## Decision

Ingest, transform, MCP tool servers and the agent runtime all run as Lambda functions in the deployed (Phase 8) topology, and locally on the Mac during Phases 1–7 (ADR-004). No EC2.

## Alternatives considered

- **Bedrock AgentCore Runtime** — the managed agent host, but it is pay-per-use with no free tier and hides the runtime the portfolio is meant to demonstrate.
- **EC2 t3.micro** — a familiar server, but it must be patched, kept running, and paid for when idle.
- **ECS/Fargate** — the right answer at real scale, and the wrong answer for one nightly run.

## Consequences

Zero idle cost; cold starts are irrelevant at one run a night. Cost: Lambda's 15-minute limit constrains the transform job — the seeded load is sized to finish in under 5 minutes, and the plan says so explicitly. The human approval wait never sits inside a Lambda — Step Functions holds it with `waitForTaskToken` (§7), so the 15-minute cap cannot be hit by an 18-minute human. Revisit if: a phase needs a long-running process (it should not — see §11).
