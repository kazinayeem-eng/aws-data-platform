# ADR-006: Step Functions for the pipeline; Strands for agent teamwork

**Status:** Accepted — 18 Nov 2026

## Context

The nightly pipeline is a fixed sequence with failure handling. Incident response is a goal split into tasks with a human decision in the middle. These are different orchestration problems.

## Decision

Step Functions owns the pipeline: schedule, load, failure handling, agent invocation, approval notification and wait, resume, and publish. In Phases 1–7, work states use Step Functions Activities served by the Mac worker (ADR-012); in Phase 8, they become Lambda invokes. Strands owns agent teamwork: the Orchestrator splits goals and delegates. The failure event is the boundary between the two.

## Alternatives

- **Everything in Step Functions:** Agent reasoning would be awkward, and prompt changes would require state-machine deployments.
- **Everything in Strands:** Reimplements scheduling and pipeline retries in Python.
- **Cron and Lambda chaining:** Works, but makes failures less visible than a state-machine execution.

## Consequences

Each orchestrator is used for the work it handles best, and the portfolio demonstrates both. Two systems must be learned, so Phase 1 teaches Step Functions before agents are introduced.
