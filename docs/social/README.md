# WildLive Social Automation

WildLive publishes selected development milestones to external social
networks. This directory holds everything a reviewer needs to
understand what may be posted, when, and why — before it is sent.

The current channels are:

- **X** — see [`x/`](x/) and [ADR-0003](../adr/0003-x-development-live.md).

## Two rules that apply to every channel

1. **AI writes the wording, Git records it, PR reviews it, then a
   workflow publishes it.** The runtime never calls an LLM. Every
   post that ever leaves the WildLive repository can be traced back
   to a specific manifest file in a specific merged PR.
2. **The AI may not invent the underlying event.** Posts are
   generated from verifiable repository, PR, and CI state. If the
   AI cannot verify a claim, the post must not make it. See
   `docs/GUARDRAILS.md` → *Public reporting*.

## Governance references

- [`docs/SOCIAL_AUTOMATION.md`](../SOCIAL_AUTOMATION.md) — highest-level policy.
- [`docs/adr/0003-x-development-live.md`](../adr/0003-x-development-live.md) — accepted decision record for X posting.
- [`docs/GUARDRAILS.md`](../GUARDRAILS.md) — truthfulness rules.
- [`docs/AUTONOMY.md`](../AUTONOMY.md) — where in the autonomy
  progression this sits.
