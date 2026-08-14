# ADR-0002: WildLive Core Game System Foundation

- Status: Accepted
- Date: 2026-08-14

## Context

Task 001 established the technical foundation (Laravel 13 / PHP 8.5 /
PostgreSQL on Docker) but left every game-design question open. Before
any domain migration, Eloquent model, or gameplay endpoint is written,
WildLive needs a settled answer to the basic question:

**What kind of game is WildLive, exactly?**

This ADR records the answers the repository owner has decided in an
interactive design session with the AI. It supersedes any contradicting
statement in earlier working notes (`docs/GAME_DESIGN.md`,
`docs/DOMAIN_MODEL.md`, `docs/DECISIONS_PENDING.md`, `docs/ROADMAP.md`).
Where earlier working notes agree, they remain in force.

This ADR is a **product-level design decision**, not a technical
specification. Concrete columns, formulas, price tables, and species
lists are deliberately *not* decided here — they are called out as
still open at the end.

## Decision

### 1. Core concept

WildLive is a **text-only, asynchronous multiplayer game in which the
player commissions Hunters to capture real wild animals, builds a
personal Zoo, and grows that Zoo's value over time**.

The primary loop is **animal collection**, not zoo-management
simulation.

```text
G
  ↓
Guild
  ↓
Contract a Hunter
  ↓
Choose a Map / Region
  ↓
Dispatch the Hunter
  ↓
Wait (real elapsed time)
  ↓
Hunter returns
  ↓
Animal captured — or no capture
  ↓
Exhibit in Zoo — or Release
  ↓
Zoo Value rises
  ↓
Visitors increase
  ↓
G earned
  ↓
Contract a better Hunter
```

### 2. Real wildlife only

WildLive uses **real, existing wild animals**. Fictional, fantasy, or
invented creatures are not used.

"Mystery" is not banned as a mood — a rare individual or an unusual
real trait may be described evocatively in an expedition report — but
the underlying entity is always a real species with plausible biology.

### 3. Species

`Species` is global master data representing a real-world animal
species (e.g. Lion, African Elephant, Giraffe, Zebra).

- **Design target: 120 species.** This is a design goal, not a hard
  technical limit. The system must not treat "120" as an immovable
  constant.
- Progress may be displayed to players as e.g. `37 / 120`.

### 4. Animal

`Animal` and `Species` are strictly separated.

- An `Animal` is a **single individual** captured by a Hunter.
- Two individuals of the same species are two distinct `Animal`s.
- An `Animal` is designed to eventually carry at least these
  per-individual attributes (concrete columns are not decided here):
  - species
  - sex
  - weight
  - body size
  - traits
  - rarity
  - captured_at
  - captured_by
  - player-assigned name
- After capture, the player may give the Animal a name.

### 5. Rare individuals

Rarity applies at two levels: **Species rarity** *and* **individual
rarity within a Species**.

Individual rarity favours **biologically plausible real traits** over
easy fantasy variants. Examples that are considered in scope:

- leucism
- albinism
- melanism
- exceptional body size
- exceptional antlers / horns / mane
- other real, unusual biological traits

Examples that are considered out of scope: "Golden Lion", "Rainbow
Elephant", etc.

Rare Animals are the main high-value collection targets — the primary
reason Zoo Value can keep rising without inflating raw headcount.

### 6. Hunter

The official term is **Hunter**. `Explorer` is deprecated wherever it
appears in earlier notes.

- Hunters have differing ability.
- **A low-cost basic Hunter must always be available**, so any player —
  including a complete beginner — can always start the game.
- **Higher-skill Hunters cost more** to contract.
- Guiding principle: "Anyone can hire the minimally-competent
  specialist; hiring an outstanding specialist is expensive."
- Exact stats, ranks, and pricing are **not decided here**.

### 7. Hunters Guild

Hunters are contracted from a **Guild**.

- The Guild displays currently-available Hunters.
- The Guild's Hunter pool is authoritative and server-managed
  (persisted in the database).
- **Especially skilled Hunters are a finite shared resource across all
  players.** If player A has contracted a top Hunter, player B cannot
  simultaneously contract the same Hunter.
- **Basic Hunters never dry up.** The system must guarantee that
  starter-tier Hunters remain available even under contention, so the
  game is never unplayable for a newcomer.
- Any earlier note that describes a **player-owned Hunter being lent
  to another player** is superseded: that mechanic is not part of MVP.
  It may be reconsidered later, but only as an explicit future item.
- Pool generation cadence, availability rules, cooldowns, and contract
  duration are **not decided here**.

### 8. Map and Regions

After contracting a Hunter, **the player decides which Hunter goes to
which Region**.

WildLive has a world map / Region system. Each Region has, at least
conceptually:

- difficulty
- expedition duration
- possible species
- rarity profile

An African-inspired setting is the working assumption. Concrete Region
names are **not decided here** and the AI must not invent them
autonomously.

### 9. Expedition duration

Region difficulty and distance drive the elapsed real-world time before
the Hunter returns. Working design range:

- easy Region — about 10 minutes
- medium Region — tens of minutes to a few hours
- high-difficulty Region — roughly 8–12 hours
- very-high-difficulty Region — up to roughly 24 hours

The precise timer table is **not decided here**. The intent of the
range is to serve different lifestyles: a quick session, a
work-day-long background wait, a night-long wait, or a next-day wait.

### 10. Difficulty and failure

Hunter ability and Region difficulty interact:

- Sending a weak Hunter to a high-difficulty Region is **not
  forbidden**.
- However, the likelihood of returning with **zero animals** rises
  sharply.
- Every expedition therefore resolves as either **capture success** or
  **no capture**.
- WildLive is intentionally **not** a game in which a Hunter always
  brings something home.
- Whether more granular outcomes (partial success, injury, etc.) exist
  is **not decided here**.

### 11. Zoo

Captured Animals may be exhibited in the player's Zoo.

- Unwanted Animals can be **Released** back to the wild.
- Selling Animals is **not** a core loop.
- The Zoo is **not** a heavy management simulation. The following are
  explicitly **out of scope for MVP**:
  - food cost
  - land cost
  - zookeeper staffing
  - cleaning
  - animal illness management
  - maintenance budgeting
- The player does not need to perform daily upkeep to keep Animals
  alive. They focus on **which Animals to collect, and how**.

### 12. Zoo Value

`Zoo Value` is a first-class Zoo attribute and the primary candidate
metric for competition between players.

It is intended to eventually incorporate:

- Species diversity
- Species rarity
- Animal individual rarity
- Collection completeness
- Special / historical animals

The exact formula is **not decided here**. Two design constraints are
locked in now:

- Adding more of the same Animal must **not** cause unbounded Zoo Value
  growth.
- The ranking must not be trivially dominated by mass-farming the same
  Animal. Diminishing returns (or an equivalent mechanism) must be part
  of the eventual formula.

### 13. Visitors

`Visitors` is a Zoo attribute that gives the player a felt sense of
growth.

Intended economic loop:

```text
better collection → higher Zoo Value → more Visitors → more G
  → better Hunter → better collection
```

The Visitor calculation and the G-generation formula are **not decided
here**.

### 14. Currency

The in-game currency is **`G`**.

- Primary use: contracting Hunters.
- Additional uses may be introduced later.

### 15. Multiplayer

WildLive is multiplayer, but in a specific shape:

- Players may **visit** other players' Zoos.
- Visible information includes another player's collection and their
  Rare Animals.
- Zoo Value rankings are a candidate feature.

Hard rule: **another player's Animals cannot be stolen.** WildLive's
competitive surface is:

- collection
- Zoo Value
- ranking
- **shared scarcity of top Hunters** (see §7)

It is explicitly **not**:

- attacking other players
- destroying other players' assets
- theft

### 16. Seasonal Events

WildLive supports **Seasonal Events** as a long-term operating
mechanism.

Example — a Christmas / winter season may feature real cold-climate
animals such as Reindeer, Arctic Fox, or Snowy Owl.

A Seasonal Event can, for a limited time, change:

- appearance rates of specific Species
- rare-trait rates
- state of specific Regions

Concrete Seasonal Event formulas are **not decided here**. Fictional
"holiday creatures" are not used — only real wildlife appropriate to
the season.

### 17. Continuous Rare Animal introduction (no power inflation)

WildLive deliberately **rejects power inflation** as its long-term
progression treadmill.

- The game does not add "stronger and stronger" Animals over time.
- New collection targets are added as **rarer** Animals, not stronger
  ones.
- The base Species list does not need to grow endlessly. Instead, new
  content mostly takes the form of new **individual rarity** within
  existing Species — rare traits, unusual individuals, seasonal
  individuals, event-specific individuals.

### 18. Historical / Event identity

Animals captured during a Seasonal Event or a specific in-game moment
may retain that provenance, e.g. `Captured during Winter Wilds 2026`.

- After the event ends, the Animal stays in the Zoo.
- Old Animals must **not** simply become weaker or lose value versus
  newer Animals. Historical identity is a design pillar for
  long-term-player attachment.
- The exact schema for recording provenance is **not decided here**.

### 19. Monetization — future only

Real-money monetisation is a **future** consideration, not part of
current scope.

Direction, when it is eventually addressed:

- `G` remains earnable through normal gameplay.
- Additional `G` may be purchasable via IAP.
- A subscription plan is also a candidate, with recurring benefits.
- RevenueCat is a candidate integration provider.

Explicit exclusions from this ADR:

- No prices, benefits, paywalls, or balance decisions.
- No RevenueCat integration, no payment flows, no subscription code.

This ADR records the direction only. Any monetisation implementation
requires its own future decision.

## Consequences

### What this ADR closes

The following previously-open questions are considered **decided** as
of 2026-08-14 and are removed from the active pending list:

- Hunter vs. Explorer terminology → **Hunter**.
- Individual animals vs. species counts → **Individual `Animal`
  instances**, distinct from `Species`.
- Core progression currency → **`G`**.
- Failure / partial-success behaviour at the coarsest level →
  **capture success or no capture**; finer partial-success behaviour
  remains open.
- How mysterious creatures enter the world → **they don't**; the
  system uses only real wildlife and expresses "mystery" through rare
  real traits and expedition-report language.
- Hunter-contract ownership rules → **Guild-owned shared pool**; no
  player-to-player Hunter lending in MVP.
- Whether players can attack, destroy, or steal from another player's
  Zoo → **No**. Competition is collection / Zoo Value / ranking /
  shared scarce Hunters only.
- Whether the Zoo is a management simulation → **No** for MVP (no
  food, land, staff, cleaning, illness, or budget).
- Whether animal-selling is a core loop → **No**. `Release` is the
  disposal mechanic.
- Whether long-term progression relies on power inflation → **No**.
  New collection targets are rarer, not stronger.

### What this ADR intentionally does not close

The following remain open and require further decisions before the
corresponding features are built. They belong in
`docs/DECISIONS_PENDING.md`:

- The full 120-species list.
- Concrete Region names, count, and unlock model.
- Exact Hunter attribute schema.
- Exact Hunter contract prices and price scaling.
- Guild Hunter availability / regeneration algorithm and how basic
  Hunters are guaranteed to remain reachable.
- Exact rarity probability tables (Species and individual level).
- Exact Zoo Value formula (with the diminishing-returns constraint
  from §12).
- Exact Visitor formula and G-generation formula.
- Precise expedition timing table.
- Seasonal Event content, cadence, and formulas.
- Historical / event provenance schema.
- IAP pricing, subscription benefits, RevenueCat contract.
- Authentication mechanism.
- Anti-abuse policy.
- Whether trading between players is ever allowed (theft is banned
  regardless).
- Whether cooperative expeditions or World First mechanics remain in
  scope for the eventual multiplayer phase.

### Effect on the roadmap

Phase 2 of `docs/ROADMAP.md` ("Game specification") is largely
satisfied at the design-decision level by this ADR. It does **not**
authorise Phase 3 (domain / DB design), Phase 4 (REST API), or Phase 5
(first playable) to begin — those require their own tasks and their
own decisions.

### Human intervention

The design decisions above were made by the repository owner (human)
in an interactive design session. The AI's role in this ADR is to
**organise and document** those decisions, resolve their impact on
earlier notes, and flag anything the human did not decide as still
open. The AI did not invent game rules on its own; where a detail was
not decided, the ADR says so explicitly.
