# ADR-004 — Mac-local for Phases 1–7; RDS only for the Phase 8 demo, then deleted

**Status:** Accepted — 18 Nov 2026

## Context

The account is paid, so the 12-month RDS free tier is assumed expired. An RDS db.t3.micro left running costs ~$13–15/month — over budget alone. And a cloud Lambda cannot reach a database on the Mac, so the topology must be decided before any phase is written: either the database moves to the cloud (and the plan must price the VPC), or the code runs on the Mac (and Phase 8 is the deployment).

## Decision

Phases 1–7 run on the Mac: the pipeline job, the agent runtime and the MCP tool servers run locally with uv against PostgreSQL in Docker, calling Bedrock, S3, DynamoDB, SNS and X-Ray as real AWS services via the `apa` profile. The deployed Lambda path (ADR-005/ADR-010) is the Phase 8 target, not how Phases 1–7 execute — no phase's definition of done requires a cloud Lambda to reach the Mac. RDS is deployed once, in Phase 8, for the recorded demo, and deleted the same day (with a snapshot) — not stopped, because a stopped RDS instance auto-restarts after 7 days. This keeps Phases 1–7 free of VPC costs: no NAT gateway, no VPC endpoints.

## Alternatives considered

- **RDS from Phase 1, left running** — simplest, but breaches the budget every month.
- **RDS from Phase 1 in a VPC** — Lambdas in a VPC need NAT or VPC endpoints to reach Bedrock and SNS; NAT alone adds ~$30/month and breaks the budget.
- **RDS started/stopped per session** — saves money but adds a start/stop ritual to every 2-hour session and teaches nothing.
- **Neon/Supabase free tier** — genuinely free Postgres with pgvector, but it moves the database off AWS and weakens the "built on AWS" portfolio story.

## Consequences

Build cost stays at $1–3/month and no VPC is needed until Phase 8. The deployment step is practised exactly once, deliberately, in Phase 8 — and the demo recording is the evidence it worked. The Mac-local code and the deployed Lambda code are the same Python (uv packaging, ADR-009), so Phase 8 is a deployment change, not a rewrite. Revisit if: the account is found to still hold RDS free-tier hours in the Phase 0 spike (Spike A), in which case RDS can be used from Phase 1 at no cost — but only if the VPC cost is also covered.

## Spike A result (recorded 21 Nov 2026)

No RDS free-tier hours remain. The account is paid. This confirms the Mac-local decision: RDS stays demo-only in Phase 8.
