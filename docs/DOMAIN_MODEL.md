# Domain Model — Working Notes

This file is a design workspace. It is not yet a database specification.

## Likely aggregates / entities

### User

Represents the account.

### Zoo

The player's persistent collection and progression surface.

### Hunter

A hunter / explorer who can be assigned to expeditions.

Potential properties:

- level
- exploration skill
- luck
- specialization
- availability

### Region

A place that can be explored.

Potential properties:

- difficulty
- unlock requirements
- species pool
- temporary world modifiers

### Species

A species definition shared globally.

Potential properties:

- rarity
- discovery status
- first discovery

### Exploration

A player's time-based assignment.

Core states should remain simple:

- pending / active
- resolvable
- resolved
- cancelled, only if cancellation is intentionally supported

### Discovery

A factual record that a player discovered a species or unknown creature.

## Later multiplayer concepts

- HunterContract
- CooperativeExpedition
- ExpeditionMember
- WorldEvent

## Open questions

Do not answer these by assumption during implementation.

- Does a hunter belong permanently to one player?
- Can hunters be injured, exhausted, or unavailable?
- Is capture guaranteed after discovery?
- Are individual animals distinct instances or only collection counts?
- How is zoo income calculated?
- Can players trade animals?
- What makes a species globally unique?
- Are unknown creatures generated dynamically or pre-authored?
