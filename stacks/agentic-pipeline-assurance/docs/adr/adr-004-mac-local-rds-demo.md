# ADR-004: Mac-local development for Phases 1–7; RDS for the Phase 8 demo

**Status:** Accepted — 18 Nov 2026; amended in later plan revisions

## Context

The account is paid and does not qualify for assumed free RDS hours. An RDS `db.t3.micro` costs more than the monthly budget if left running, and a cloud Lambda cannot reach a database on the Mac.

no credits, verified 24 Nov 2026

## Decision

Run the pipeline, agent runtime, and MCP tool servers locally on the Mac with `uv` and Docker PostgreSQL in Phases 1–7. They call Bedrock, S3, DynamoDB, SNS, and X-Ray as real AWS services using a scoped runtime profile. Step Functions and EventBridge stay in the cloud and drive local work through the polling worker in ADR-012.

Deploy RDS for the Phase 8 demo only, then delete it the same day with a snapshot. The Mac-local and Lambda implementations use the same Python code; Phase 8 is a deployment change, not a rewrite. This avoids VPC costs during development.

## Alternatives

- **RDS from Phase 1, left running:** Simplest, but exceeds the monthly budget.
- **RDS from Phase 1 in a VPC:** Adds NAT or VPC endpoint costs for Lambda access to Bedrock and SNS.
- **Start and stop RDS each session:** Saves money but adds repeated operational work.
- **Neon or Supabase free tier:** Provides free PostgreSQL with pgvector, but moves the database off AWS.

## Consequences

Build costs stay low and no VPC is needed before Phase 8. The RDS deployment is practiced once for the demo and removed afterward; a stopped instance is not sufficient because it can restart automatically after seven days. Revisit if a credit balance appears, but keep the Mac-local decision because credits expire.

**Guide deviation:** The guide names the scoped profile `kazi-dev-apa`; the plan's summary also refers to it by the shorter name `apa`.
