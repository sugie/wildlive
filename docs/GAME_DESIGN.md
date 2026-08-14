# Game Design

> **Source of truth.** The design decisions summarised in this document
> are ratified by [`docs/adr/0002-game-system-foundation.md`](adr/0002-game-system-foundation.md).
> If this file conflicts with ADR-0002, ADR-0002 wins.

## What WildLive is

WildLive is a **text-only, asynchronous multiplayer game in which the
player commissions Hunters to capture real wild animals, builds a
personal Zoo, and grows that Zoo's value over time**.

The main activity is **animal collection**. Zoo-management simulation
(feeding, staffing, land, illness) is intentionally out of scope for
MVP.

## Core loop

```text
G  →  Guild  →  Contract a Hunter  →  Choose a Region  →  Dispatch
   →  Wait (real elapsed time)  →  Hunter returns
   →  Animal captured, or no capture
   →  Exhibit in Zoo, or Release
   →  Zoo Value rises  →  Visitors increase  →  G earned
   →  Contract a better Hunter
```

If this loop is not fun, multiplayer systems must not be used to hide
the problem.

## Design principles

### Text first

The game must remain playable without illustrations. Text is not a
temporary placeholder; it is a core aesthetic.

### Asynchronous multiplayer

The MVP does not require real-time sockets or synchronous combat.
Players influence one persistent world while participating at
different times.

### Server authoritative

The server determines:

- expedition timing
- expedition results (capture success or no capture)
- ownership
- currency (`G`)
- rarity — both `Species` rarity and individual `Animal` rarity
- Guild Hunter availability
- Zoo Value
- ranking

Clients are never trusted to calculate authoritative rewards or
outcomes.

### Real wildlife only

WildLive uses only real, existing wild animals. Fictional or fantasy
creatures are not part of the world. "Mystery" is expressed through
rare real traits and evocative expedition-report language, not through
invented creatures. See ADR-0002 §2.

### No power inflation

New content is added as **rarer** Animals, not stronger ones. The base
`Species` list does not grow endlessly; new individual rarity within
existing Species is the primary long-term expansion vector. See
ADR-0002 §17.

## Entities used in this document

- **`Species`** — global master data for a real-world animal species.
  Design target: 120 species (a goal, not a hard constant). See
  ADR-0002 §3.
- **`Animal`** — a single captured individual. Two animals of the same
  species are two distinct entities and may carry different traits and
  rarity. See ADR-0002 §4.
- **`Hunter`** — an NPC contracted from the Guild. Skill varies; cost
  scales with skill. See ADR-0002 §6.
- **`Guild`** — the source of contractable Hunters. Top-tier Hunters
  are a shared scarce resource across all players; a basic-tier Hunter
  is always available. See ADR-0002 §7.
- **`Region`** — a place a Hunter can be dispatched to. Carries a
  difficulty, an expedition duration, a species pool, and a rarity
  profile. See ADR-0002 §8.
- **`Zoo`** — the player's persistent Animal collection. Not a
  management simulation. See ADR-0002 §11.
- **`Zoo Value`** — the primary competitive metric. Diminishing
  returns on repeated identical Animals is a locked-in constraint on
  the eventual formula. See ADR-0002 §12.
- **`Visitors`** — player-facing indicator of Zoo growth; drives `G`
  income. See ADR-0002 §13.
- **`G`** — the in-game currency. Primary use: contracting Hunters.
  See ADR-0002 §14.
- **`Seasonal Event`** — a bounded-time modifier of species appearance
  rates, rare-trait rates, or Region state. Uses real wildlife
  appropriate to the season. See ADR-0002 §16.

## Rare individuals

Rarity applies both at the Species level and at the individual
`Animal` level. Individual-level rarity uses biologically plausible
real traits — leucism, albinism, melanism, exceptional body size,
exceptional antlers / horns / mane, and similar — rather than fantasy
variants such as "Golden Lion". See ADR-0002 §5.

## Difficulty, failure, and expedition time

- A weak Hunter may be sent to a high-difficulty Region — this is not
  forbidden — but the chance of **no capture** rises sharply.
- Every expedition resolves as either `capture success` or `no
  capture`. Finer partial-success behaviour is not yet decided.
- Working duration range (exact table not yet decided):
  - easy — about 10 minutes
  - medium — tens of minutes to a few hours
  - high difficulty — about 8–12 hours
  - very high difficulty — up to about 24 hours

The intent is to fit different lifestyles: a short session, a workday
wait, an overnight wait, or a next-day wait.

## Multiplayer

Multiplayer is present from the design's core, but takes a specific
shape:

- Players may **visit** other players' Zoos and see their collections,
  including Rare Animals.
- **Zoo Value ranking** is a candidate competitive surface.
- **Top Hunters are a shared scarce resource** — if player A holds a
  top Hunter contract, player B cannot simultaneously hold the same
  contract. Basic Hunters must never dry up.
- **Attacking, destroying, or stealing from another player's Zoo is
  forbidden.** This is a design pillar, not a temporary MVP
  simplification.

Player-to-player Hunter *lending* (an earlier idea) is superseded by
the Guild model and is not part of MVP. It may be reconsidered later
as an explicit future item.

## Seasonal Events and historical identity

Seasonal Events change appearance rates, rare-trait rates, or Region
state for a bounded time (see ADR-0002 §16). Animals captured during a
Seasonal Event may retain that provenance
(e.g. `Captured during Winter Wilds 2026`).

Old Animals stay in the Zoo after the event ends and must not simply
become weaker or lose value versus newer Animals — historical identity
is a design pillar for long-term-player attachment. See ADR-0002 §18.

## Monetisation

Real-money monetisation is a future concern only. Direction (not yet
in scope): `G` remains earnable through gameplay; additional `G` may
be sold as IAP; a subscription plan is a candidate; RevenueCat is a
candidate provider. No prices, benefits, paywalls, or payment code are
decided or implemented at this time. See ADR-0002 §19.

## MVP-0

MVP-0 is complete when one player can:

- exist
- own one Zoo
- contract one Hunter (from the Guild)
- dispatch that Hunter to one Region
- wait for the real elapsed time to pass
- resolve the expedition exactly once (idempotent)
- receive a deterministic server-side result (`capture success` or
  `no capture`)
- add a captured Animal to the Zoo — with per-individual identity —
  or Release it
- see Zoo Value change accordingly

Multiplayer surfaces (Zoo visits, ranking, shared Hunter scarcity)
come after this vertical slice is reliable.
