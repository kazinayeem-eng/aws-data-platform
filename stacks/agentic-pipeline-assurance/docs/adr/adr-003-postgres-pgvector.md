# ADR-003: PostgreSQL and pgvector for analytics, sandboxing, and RAG

**Status:** Accepted — 18 Nov 2026

## Context

The system needs a relational analytics table, a scratch copy for safe testing, and vector search over runbooks. The budget does not allow a dedicated vector database.

## Decision

Use one PostgreSQL database with pgvector for `customers`, `customers_test`, `customers_prev` (rollback), `applied_approvals` (single-use ledger), and the `documents` embedding table.

## Alternatives

- **Bedrock Knowledge Bases and OpenSearch Serverless:** AWS-native RAG, but OpenSearch Serverless has a high monthly minimum.
- **DynamoDB plus a separate vector store:** Adds stores and bills; DynamoDB is not a good fit for analytics.
- **SQLite and local vectors:** Free, but would diverge from the deployed analytics database.

## Consequences

There is one database to learn and pay for, and retrieval quality can be measured with a 10-question test. pgvector at 1.2-million-row scale is not a production vector store. Revisit if retrieval precision remains below the Phase 3 threshold after chunking and prompt improvements.
