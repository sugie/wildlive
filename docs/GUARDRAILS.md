# Guardrails

These rules are mandatory for humans and AI agents unless explicitly changed by the repository owner.

## Source control

- No direct push to `main`.
- `main` must remain deployable.
- Use short-lived branches.
- Use Pull Requests.
- Do not rewrite published shared history without explicit human approval.

## Tests

- New behavior requires tests where practical.
- Existing tests must not be removed merely to make CI green.
- Failing tests must be investigated.
- Test results must not be fabricated.

## Secrets

Never commit real:

- passwords
- tokens
- private keys
- API credentials
- cloud credentials
- social-media credentials

## Production

AI agents must not autonomously:

- delete production data
- reset production databases
- rotate production credentials
- make irreversible production changes
- weaken security controls
- create paid cloud resources without an approved budget policy
- enable billing or payment features

## Database

Prefer:

- additive migrations
- explicit constraints
- transactions
- idempotent operations
- rollback plans

Destructive schema changes require explicit review.

## Dependencies

Do not add a dependency without a concrete use case.

Security-sensitive or high-impact dependencies require additional review.

## Game fairness

The server is authoritative.

Never allow client-provided values to determine:

- rewards
- currency
- ownership
- rarity
- World First status
- timers
- contract completion

## Public reporting

Automated public posts must be derived from verifiable repository or game data.

Do not fabricate:

- development progress
- player numbers
- uptime
- World First events
- test counts
- deployment status
