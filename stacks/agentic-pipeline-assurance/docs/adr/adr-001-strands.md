# ADR-001: Strands Agents SDK as the agent framework

**Status:** Accepted — 18 Nov 2026

## Context

The system needs a model-driven agent loop, MCP tools, multi-agent patterns, human-approval interrupts, and tracing. The builder is learning, so the framework should not require framework expertise before the first agent works.

## Decision

Use the Strands Agents SDK for Python, with Amazon Bedrock as the model provider.

## Alternatives

- **LangGraph:** Offers explicit graph control and good debugging, but requires hand-wiring every step.
- **Bedrock Agents:** Managed and code-free, but hides the implementation and is difficult to review in the repository.
- **Raw boto3 and a hand-built loop:** Teaches the loop, but reimplements retries, tool parsing, and interrupts.

## Consequences

Strands is a fast path to a working agent, with native MCP and A2A support. Some loop behavior belongs to the framework, so Phase 2 includes reading its implementation. Revisit if Strands cannot express the Phase 4 approval handoff; LangGraph is the fallback.
