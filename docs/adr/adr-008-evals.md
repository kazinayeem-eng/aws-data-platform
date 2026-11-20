# ADR-008 — Evals are a fixed 20-case set, run on every change; no eval platform

**Status:** Accepted — 18 Nov 2026

## Context

"It worked once" is not evidence. The portfolio needs repeatable proof that the agents behave — and that a change did not break them.

## Decision

A versioned set of 20 eval cases (10 retrieval, 5 diagnosis, 5 end-to-end incident replays) run by a plain pytest script, scored automatically, with results committed to the repo. No third-party eval platform.

## Alternatives considered

- **LangSmith / Langfuse hosted** — better tooling, but another account, another bill, and hosted traces of a learning project.
- **Manual "try it and see"** — the default for tutorials and the reason most agent demos cannot be trusted.
- **Bedrock model evaluation jobs** — useful for the Phase 7 model comparison only, not for the daily loop.

## Consequences

Every phase gate includes "evals still pass". The eval set itself is a portfolio artefact a reviewer can run. Cost: writing good eval cases is real work — it is budgeted as its own phase (Phase 5), not squeezed into a Friday night.
