# ADR-008: A fixed 20-case eval set, with no eval platform

**Status:** Accepted — 18 Nov 2026

## Context

One successful run is not evidence that agents behave reliably. The project needs repeatable proof and regression checks.

## Decision

Maintain 20 versioned eval cases: 10 retrieval, 5 diagnosis, and 5 end-to-end incident replays. Run them with a plain pytest script, score automatically, and commit the results. Do not use a third-party eval platform.

## Alternatives

- **Hosted LangSmith or Langfuse:** Better tooling, but adds an account, bill, and hosted traces.
- **Manual testing:** Easy, but does not produce repeatable evidence.
- **Bedrock model evaluation jobs:** Useful for the Phase 7 comparison, not for the regular evaluation loop.

## Consequences

Every phase gate requires passing evals, and the eval set is a runnable portfolio artifact. Writing good cases takes real effort, so it is budgeted as Phase 5 work.
