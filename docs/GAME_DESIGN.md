# Game Design

## Core loop

The first playable loop is deliberately small:

1. Contract or select a hunter / explorer.
2. Choose a region.
3. Start an expedition.
4. Leave the game.
5. Return after the expedition ends.
6. Receive an expedition report.
7. Discover or capture an animal.
8. Add it to the player's zoo.
9. Increase zoo value / income / reputation.
10. Unlock better hunters and harder regions.

If this loop is not fun, multiplayer systems must not be used to hide the problem.

## Design principles

### Text first

The game must remain playable without illustrations.

Text is not a temporary placeholder. It is a core aesthetic.

### Asynchronous multiplayer

The MVP does not require real-time sockets or synchronous combat.

Players influence one persistent world while participating at different times.

### Server authoritative

The server determines:

- expedition timing
- expedition results
- ownership
- discoveries
- currency
- rarity
- World First winners
- contracts
- cooperative expedition outcomes

Clients are never trusted to calculate authoritative rewards.

## Initial multiplayer systems

### World First

Some species or unknown creatures can be discovered for the first time globally.

The first valid discovery is permanently recorded.

### Hunter contracts

A player may eventually make a developed hunter available for another player to contract for a limited period.

### Cooperative expeditions

Multiple players contribute hunters or exploration power to one expedition.

The expedition resolves asynchronously.

### Shared world events

Examples:

- migration
- unusual weather
- rare-animal activity
- red moon
- closed region
- mysterious tracks

World events modify game rules for a fixed time window.

## Zoo

A zoo is the player's persistent collection and progression surface.

Possible later attributes:

- visitors
- reputation
- income
- species count
- rare species
- themed areas
- global rank

Do not build all of these for the first playable version.

## Mystery layer

The early game should contain familiar animals.

Later, the world may introduce unknown or unclassified creatures.

The mystery must emerge gradually from expedition reports rather than immediately turning into a horror game.

## MVP-0

MVP-0 is complete when one player can:

- exist
- own one zoo
- own or select a hunter
- start one expedition
- wait for its end time
- resolve it exactly once
- receive a deterministic server-side result
- add an animal to the zoo
- observe progression

Multiplayer comes after this vertical slice is reliable.
