# ADR-012: Step Functions Activities bridge the cloud state machine to the Mac

**Status:** Draft — 21 Nov 2026; pending plan approval

## Context

ADR-004 runs code on the Mac during Phases 1–7, while ADR-006 places pipeline orchestration in cloud Step Functions. A cloud state machine cannot directly call a process on a laptop behind a home router; the earlier plan did not resolve that gap.

## Decision

Keep the state machine and EventBridge schedule in the cloud from Phase 1. In Phases 1–7, use Step Functions Activities for the load, incident, resume, and publish work. A small `uv`-run worker on the Mac long-polls `GetActivityTask`, calls the same handler functions used by Lambda in Phase 8, and reports success or failure. The worker only makes outbound calls; it needs no inbound port or tunnel. In Phase 8, replace the four Activity states with Lambda invokes without changing handler contracts. Keep the approval wait, SNS, and approval endpoint in the cloud in every phase. Set Activity timeouts to 15 minutes.

## Alternatives

- **SQS plus `waitForTaskToken`:** Similar pattern, but requires creating and draining a queue; Activities are simpler here.
- **Start executions only from the Mac:** Simpler, but delays learning Step Functions until Phase 8.
- **Expose the Mac through a tunnel:** Opens an inbound path to a laptop holding the database.
- **Put PostgreSQL in the cloud from Phase 1:** Rejected on cost in ADR-004.

## Consequences

Phase 1 teaches Step Functions, and Phase 8 changes four states rather than rewriting the pipeline. Progress requires the worker to be running, so the Mac must be awake; keep the schedule disabled in Phases 1–7 and start learning runs on demand. A missing worker causes a visible timeout and failure. Spike C proves the pattern before Phase 1 depends on it. If the always-awake requirement becomes burdensome, proceed to Phase 8 rather than adding infrastructure.
