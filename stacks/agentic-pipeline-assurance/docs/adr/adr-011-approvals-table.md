# ADR-011: A separate approvals table; only the approve endpoint writes

**Status:** Draft — 20 Nov 2026; amended 21 Nov 2026, pending plan approval

## Context

The table-swap operation must require a verifiable human approval. If approvals share a table with agent memory, an agent that can write memory could approve its own work.

## Decision

Use a separate on-demand DynamoDB table, `apa-approvals`. Only the approval endpoint's Lambda role can write; tool servers can read, and the agent runtime has no direct table access. Bind each record to the incident ID, the current hash of `customers_test`, and an expiry. `swap_tables` refuses missing, mismatched, expired, or previously applied approvals. Enforce single use atomically during the swap by recording the approval ID in PostgreSQL's unique-key `applied_approvals` ledger.

The approval link contains the incident ID, test-copy hash, and Step Functions task token. A GET displays confirmation without changing state; only a deliberate POST writes the record and resumes the state machine.

## Alternatives

- **Store approval in `apa-memory`:** Rejected because the Fixer can write memory and could approve itself.
- **Item-level IAM in one table:** Coarse and harder to audit than a separate trust boundary.
- **A `used` flag in `apa-approvals`:** Would require the swap tool to write to the endpoint-only table.
- **Use only the Step Functions token:** Does not provide a durable record tied to the test-copy hash.

## Consequences

Approval is durable and auditable, at the cost of one additional on-demand table and an approval Lambda plus confirmation page. The Mac profile must remain read-only on the approvals table; a Phase 4 test verifies that a write is denied. If multiple approvers are later required, add an approver field without changing the boundary.
