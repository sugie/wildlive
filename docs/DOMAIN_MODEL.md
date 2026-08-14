# Domain Model — Working Notes

> **Design authority.** These notes are a design workspace, not a
> database specification. Where anything here conflicts with
> [`docs/adr/0002-game-system-foundation.md`](adr/0002-game-system-foundation.md),
> ADR-0002 wins.
>
> **See also** [`docs/ER_MODEL.md`](ER_MODEL.md) — the minimal ER
> model. That document fixes the entity set, relationships,
> cardinality, and PostgreSQL-level concurrency invariants. This file
> remains the *conceptual* workspace; `ER_MODEL.md` is the *structural*
> contract that a future migration task must respect. Where the two
> disagree, `ER_MODEL.md` wins (and the discrepancy should be fixed
> here).

The concrete database schema, columns, and constraints are still to be
designed in a later task. Do **not** treat this file as authorisation
to create migrations.

**Note on naming.** Earlier notes used `User` for the account entity.
`docs/ER_MODEL.md` renames it to `Player`, matching the game
vocabulary. Both refer to the same aggregate; treat any remaining
`User` mention here as `Player`.

## Likely aggregates / entities

### User

Represents the account. The account model — authentication method,
identity fields, GDPR posture — is not yet decided.

### Zoo

The player's persistent Animal collection. **Not** a management
simulation: no food cost, land cost, staffing, cleaning, illness, or
budgeting in MVP (ADR-0002 §11).

Design-level attributes it is expected to carry:

- `Zoo Value` (see below)
- `Visitors`

### Zoo Value

The primary competitive metric between players. Intended to reflect
species diversity, species rarity, individual `Animal` rarity,
collection completeness, and special / historical animals. The exact
formula is not decided, but it must include diminishing returns so
that mass-farming the same Animal cannot dominate the ranking
(ADR-0002 §12).

### Visitors

Player-facing indicator of Zoo growth. Drives `G` income. Exact
formula not decided (ADR-0002 §13).

### Hunter

An NPC contracted from the `Guild` and dispatched to a `Region`.
Terminology: **Hunter** (the earlier "Explorer" naming is deprecated).

Design-level notes:

- Hunters have differing ability.
- Higher ability means higher contract cost.
- Ability, ranks, and pricing are not yet defined as attributes.
- Whether a Hunter can be injured, exhausted, or temporarily
  unavailable is not yet decided.

### Guild

The authoritative source of contractable Hunters (ADR-0002 §7).

- The Guild's Hunter pool is server-managed.
- Top-tier Hunters are a **shared scarce resource across all players**
  — concurrent contracts on the same top Hunter are not allowed.
- Basic-tier Hunters must always remain contractable so a beginner
  can always play.
- The pool generation / availability / cooldown / contract-duration
  algorithm is not yet designed.

### Species

Global master data for a real-world animal species (ADR-0002 §3).

- Design target: 120 species. Not a hard technical constant.
- May carry a species-level rarity.
- The full 120-species list is not authored yet.

### Animal

A single captured individual (ADR-0002 §4). Distinct from `Species`.

Per-individual attributes that the design expects, at least
conceptually:

- species (reference to `Species`)
- sex
- weight
- body size
- traits (including biologically plausible rare traits — leucism,
  albinism, melanism, exceptional body size, exceptional antlers /
  horns / mane, etc.)
- rarity
- captured_at
- captured_by (player)
- player-assigned name
- optional event provenance (e.g. "Captured during Winter Wilds 2026")

Concrete columns and types are not decided here.

### Region

A place a Hunter can be dispatched to (ADR-0002 §8).

Conceptual attributes:

- difficulty
- expedition duration
- possible species (subset of `Species`)
- rarity profile
- optional temporary Seasonal Event modifiers

Concrete Region names and count are not yet authored.

### Expedition

A time-bounded assignment of a Hunter to a Region. Core states should
remain simple:

- pending / active
- resolvable (elapsed time reached)
- resolved

Whether cancellation is supported is not yet decided.

Resolution outcome is coarsely one of:

- `capture success` — produces one or more `Animal` instances
- `no capture` — produces nothing

Finer partial-success behaviour is not yet decided. Resolution must be
idempotent (see `docs/ARCHITECTURE.md`).

### Seasonal Event

A bounded-time modifier of species appearance rates, rare-trait rates,
or Region state (ADR-0002 §16). Uses only real wildlife appropriate
to the season. Content, cadence, and formulas are not decided.

## Deferred multiplayer concepts

- Player-to-player Hunter lending is **not** part of MVP; the Guild
  model supersedes it (ADR-0002 §7). May be reconsidered later as an
  explicit future item.
- Cooperative expeditions and World First mechanics are outside the
  ADR-0002 decision scope and remain open.

## Deleted / superseded ideas

- "Unknown creatures" / "unclassified creatures" — removed. The world
  contains only real wildlife (ADR-0002 §2).
- `Discovery` as a first-class entity for "unknown creature discovery"
  — no longer required. If a `Discovery` concept is later needed
  (e.g. "the first player to capture Species X"), it will be
  reintroduced under a decided scope.

## Open questions

Do not answer these by assumption during implementation.

- Whether individual Hunters can be injured, exhausted, or
  temporarily unavailable.
- Whether cancellation of an in-flight expedition is supported.
- Whether trading Animals between players is ever allowed (theft is
  banned regardless — ADR-0002 §15).
- Exact schema for event provenance on an `Animal`.
- Exact Guild Hunter availability / regeneration algorithm.
- Exact rarity probability tables (Species-level and individual-level).
- Whether cooperative expeditions or World First mechanics remain in
  scope for the eventual multiplayer phase.
