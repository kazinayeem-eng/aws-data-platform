# ADR-011 — Approvals in their own DynamoDB table; only the approve endpoint writes

**Status:** DRAFT — 20 Nov 2026 (new in v2.0, for approval with this plan)

## Context

The swap must not run without a human approval, and the approval must be checkable by the tool that performs the swap. If the approval record lives in the same table the agents write memory to, any agent that can write memory can approve its own work — the Fixer could approve itself.

## Decision

A separate DynamoDB table `apa-approvals`, on-demand, inside the always-free allowance. Only the approve endpoint (Lambda Function URL) can write to it. The approval record is bound to the incident ID, the hash of the test copy, an expiry, and a single-use flag. `swap_tables` reads the record and refuses unless all four match. The email link opens a confirmation page (so a scanner prefetching the link cannot approve); approving needs a deliberate click that sends a signed single-use token.

## Alternatives considered

- **Approval record in `apa-memory`** — one fewer table, but the Fixer writes memory, so it could write its own approval; rejected on the trust boundary.
- **Key-scoped IAM on one table** — DynamoDB item-level IAM is coarse and hard to audit; a separate table is a clearer boundary.
- **Approval as a Step Functions token only, no table** — the token proves the human clicked, but the swap tool needs a durable, checkable record tied to the test copy's hash; the token alone does not carry it.

## Consequences

The approval is a durable, auditable record a reviewer can read. Cost: one more on-demand table inside the always-free allowance — $0. The approve endpoint is a second Lambda to deploy (Phase 4), and the confirm page is a small static page. Revisit if: the approval flow needs more than one approver, in which case the record gains an approver field — the table shape, not the boundary, changes.
