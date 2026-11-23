# ADR-002: Amazon Bedrock and Nova Micro as the default model

**Status:** Accepted — 18 Nov 2026; amended for the 21 Nov 2026 region-guardrail test

## Context

The agents need an affordable model for repeated experiments, available in `ap-southeast-2`, with reliable tool-schema following.

## Decision

Use Amazon Bedrock with Nova Micro by default. Compare Claude Haiku in Phase 7 if an in-region route is available.

**Spike B results (24 Nov 2026, `ap-southeast-2`):** `amazon.nova-micro-v1:0` returned `Hello!` for a one-word prompt. `amazon.titan-embed-text-v2:0` returned a 1,024-dimensional embedding for `column renamed`.

The account guardrails allow only `ap-southeast-2` and `us-east-1`. Cross-region inference profiles are refused when they can route to a blocked region. If the Haiku comparison requires such a profile, choose among a reviewed guardrail change, an available in-region Claude model, or a second in-region Amazon model.

## Alternatives

- **Claude Sonnet by default:** Better reasoning, but approximately 10–20 times the token price.
- **Local models through Ollama:** Free, but small-model tool-calling reliability could teach the wrong lessons.
- **OpenAI API:** Adds a second cloud bill and credential without a project benefit.

## Consequences

Model spending stays low. Evals are model-specific and must be rerun after a model change. Revisit if Nova Micro misses the Phase 5 threshold of at least 17/20 eval cases; if Haiku becomes the default, choose an allowed route and re-price the cost model.
