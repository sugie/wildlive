# Social Automation

## Goal

WildLive should eventually publish selected development and game-world events automatically.

The intended channel is X.

## Two event sources

### Development events

Derived from verifiable GitHub data, for example:

- PR merged
- feature completed
- release published
- CI test count
- autonomous-development metrics

### Game-world events

Derived from authoritative game data, for example:

- World First
- new globally discovered species
- major cooperative expedition
- world event
- weekly world statistics

## Publication rule

Public posts must be generated from verifiable source data.

The AI may write the wording.

The AI may not invent the underlying event.

## Initial policy

Do not implement automatic posting during the Docker-foundation task.

Before enabling automated X posting, define:

- credential storage
- posting rate
- duplicate suppression
- moderation / safety rules
- retry behavior
- audit log
- kill switch
