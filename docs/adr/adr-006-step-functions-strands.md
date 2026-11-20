# ADR-006 — Step Functions orchestrates the pipeline; Strands orchestrates the agents

**Status:** Accepted — 18 Nov 2026

## Context

Two different orchestration problems exist: the nightly pipeline (a fixed sequence with a failure branch) and the incident response (a goal split into tasks, with a human decision in the middle). One tool for both would be a compromise.

## Decision

Step Functions owns the pipeline: schedule → load → on failure, invoke agents → on approval-needed, send the SNS email and hold the wait with `waitForTaskToken` (30-minute timeout) → on approval, resume → on success, finish. Strands owns the agent teamwork: the Orchestrator agent splits the goal and delegates. The boundary is the failure event, and the return is the approval decision.

## Alternatives considered

- **Everything in Step Functions** — visible and robust, but agent reasoning does not belong in a state machine; every prompt change becomes a deployment.
- **Everything in Strands** — the pipeline schedule and retries would be re-implemented in Python for no benefit.
- **Cron + Lambda chaining** — works, but failures are invisible compared with a state-machine execution view.

## Consequences

Each orchestrator does what it is good at, and the portfolio shows both. Cost: two things to learn instead of one — Phase 1 teaches Step Functions before any agent exists, so the learning is sequenced.
