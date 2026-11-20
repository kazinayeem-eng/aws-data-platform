# ADR-003 — PostgreSQL + pgvector for the table, the sandbox, and RAG

**Status:** Accepted — 18 Nov 2026

## Context

The system needs a relational analytics table, a scratch copy for safe testing, and vector search over runbooks. The budget forbids a dedicated vector database.

## Decision

One PostgreSQL database (pgvector extension) holds `customers`, `customers_test`, and the `documents` embedding table.

## Alternatives considered

- **Bedrock Knowledge Bases + OpenSearch Serverless** — the AWS-native RAG path, but OpenSearch Serverless has a ~$70/month minimum: seven times the entire budget, before a single query.
- **DynamoDB + a separate vector store** — two stores, two bills, and DynamoDB is a poor fit for the analytics table.
- **SQLite + local vectors** — free, but SQLite cannot be the deployed analytics table, so the deployment would diverge from development.

## Consequences

One database to learn, one to pay for, and retrieval quality is measurable with a 10-question test. Cost: pgvector at 1.2M-row scale is not a production vector store; nobody should claim it is. Revisit if: retrieval precision falls below the Phase 3 pass mark after chunking and prompt fixes.
