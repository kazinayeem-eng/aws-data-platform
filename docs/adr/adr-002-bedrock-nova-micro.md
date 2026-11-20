# ADR-002 — Amazon Bedrock, Nova Micro as the default model

**Status:** Accepted — 18 Nov 2026

## Context

Agents need a model that is cheap enough to run hundreds of learning iterations, available in ap-southeast-2, and capable enough to follow tool schemas.

## Decision

Bedrock with Nova Micro by default; Claude Haiku used for one comparison run in Phase 7 so the evals can show the cost/quality trade-off with numbers.

## Model access

Bedrock now grants access to serverless foundation models by default — no per-model access request. Anthropic models still need a one-time usage form. Nova Micro in Sydney may need an `apac.` cross-region inference profile ID rather than the plain model ID `amazon.nova-micro-v1:0`; Phase 0 Spike B tests which ID works and records the working ID here.

## Alternatives considered

- **Claude Sonnet as default** — better reasoning, but roughly 10–20× the token price; unjustifiable while the loop itself is what is being learned.
- **Local models via Ollama** — free, but tool-calling reliability on small local models is poor and would teach the wrong lessons about agent behaviour.
- **OpenAI API** — fine model, wrong cloud: it adds a second bill and a second credential for no benefit.

## Consequences

Model spend stays in cents. The evals in Phase 5 are model-specific and must be re-run if the model changes — that is documented, not hidden. Revisit if: Nova Micro fails the tool-calling evals in Phase 5 (pass mark: 20-case set ≥ 17/20, §11); Haiku becomes the default and the cost model is re-priced.
