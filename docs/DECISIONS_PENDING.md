# Decisions Pending

Decisions that must be made before the corresponding features are
implemented.

For decisions that have already been made, see
[`docs/adr/`](adr/). In particular,
[`docs/adr/0002-game-system-foundation.md`](adr/0002-game-system-foundation.md)
closes many of the game-design questions that used to live here.

## Resolved (see ADR-0002, 2026-08-14)

The following are no longer open and are recorded here only so the
old list is traceable:

- Hunter vs. Explorer terminology → **Hunter**.
- Individual animal instances vs. species counts → **individual
  `Animal` instances**, distinct from `Species`.
- Core progression currency → **`G`**.
- Failure vs. always-succeed model → **`capture success` or `no
  capture`** at the coarse level.
- How mysterious creatures enter the world → **they don't**; WildLive
  uses only real wildlife.
- Hunter-contract ownership rules → **Guild-owned shared pool**; no
  player-to-player Hunter lending in MVP.
- Zoo visit mechanics — high level → **visits allowed; theft,
  attack, and destruction are forbidden**.
- Trading policy — partial → **stealing is forbidden**; whether
  consensual trading is ever allowed remains open (see below).
- Zoo as management simulation → **no** for MVP (no food, land,
  staff, cleaning, illness, budget).
- Long-term progression via power inflation → **no**; new content is
  rarer, not stronger.

## Game — still open

- Full 120-species list.
- Concrete Region names, count, and unlock model.
- Exact Hunter attribute schema.
- Exact Hunter contract prices and price scaling.
- Guild Hunter availability / regeneration algorithm, including how
  basic-tier Hunters are guaranteed to remain reachable under
  contention.
- Exact rarity probability tables (Species and individual level).
- Exact Zoo Value formula (must include diminishing returns per
  ADR-0002 §12).
- Exact Visitor formula and G-generation formula.
- Precise expedition timing table.
- Finer expedition outcomes beyond `capture success` / `no capture`
  (partial success, injury, etc.).
- Whether cancellation of an in-flight expedition is supported.
- Whether Hunters can be injured, exhausted, or temporarily
  unavailable.
- Seasonal Event content, cadence, and formulas.
- Historical / event provenance schema on `Animal`.

## ER-model open questions (from [`ER_MODEL.md`](ER_MODEL.md))

Design questions raised while translating ADR-0002 into a minimal
entity model. Must be answered before a migration is written:

- `HunterContract → Expedition` cardinality: 1:1 (one expedition per
  contract) or 1:N (a contract can host several expeditions during
  its window)? Depends on the still-open contract-duration decision.
- `Expedition.outcome` — coarse enum only, or a richer JSON payload
  that captures resolution reasoning?
- `Animal.status` — is `released` reversible back to `in_zoo`, or a
  terminal state? Current ER-model default assumes one-way.
- Released `Animal` — row retained with `zoo_id = NULL`, or row
  deleted? Default assumption is *retained* (for provenance and Zoo
  Value history).
- `HunterContract` — do we carry a denormalised `is_active` column,
  or is `ended_at IS NULL` the sole source of truth?
- `SeasonalEvent` — numeric `code`, stable `slug`, both, or neither?
- Whether `Expedition` carries a `hunter_contract_id` FK, or the
  link is inferred at query time from `(player_id, hunter_id,
  timestamp window)`.
- Whether a `Guild` table is introduced (currently the pool is the
  set of `Hunter` rows; a `guild_id` FK would be added additively
  if needed).
- When the `G` currency subsystem is designed, whether it lives as a
  per-`Player` `Wallet` balance plus an append-only `GLedger`, or
  as some other shape.

## Multiplayer — still open

- World First eligibility (whether the mechanic is kept at all).
- Cooperative-expedition reward distribution (whether the mechanic is
  kept at all).
- Whether consensual player-to-player Animal trading is ever allowed.
- Anti-abuse policy.

## Product — still open

- Public player identity model.
- Authentication method.
- Initial client: web, mobile, or API-first.
- Japanese / English launch scope.

## Monetisation — still open (future)

- IAP pricing.
- Subscription benefits.
- RevenueCat contract.
- Where paywall (if any) sits relative to the core loop.

## Operations — still open

- X account strategy.
- Autonomous-post approval level.
- Deployment environments.
- Sakura Cloud AppRun release process.
- PostgreSQL backup / restore policy.
