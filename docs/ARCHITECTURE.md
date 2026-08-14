# Architecture

## Current direction

### Backend

- Laravel 13
- PHP 8.5
- REST / JSON API

### Database

- PostgreSQL

### Local development

- Docker Compose

### CI/CD

- GitHub Actions

### Cloud target

- Sakura Cloud AppRun
- Sakura Cloud PostgreSQL appliance

## Architectural principles

### Start small

Initial runtime dependencies should be limited to what is needed for the first vertical slice.

Do not add Redis, queues, WebSockets, Kafka, or additional services until a concrete requirement exists.

### Server-authoritative game state

All game-changing actions are validated and resolved server-side.

### Time-based idle actions

Long-running expeditions should usually be represented by timestamps:

- `started_at`
- `ends_at`
- `resolved_at`

The server does not need one continuously running worker per expedition.

An expired unresolved expedition can be resolved idempotently when:

- the player requests it
- a scheduled process scans it
- another game process requires the result

### Idempotency

Resolution must be safe to call more than once.

Exactly-once effects should be implemented using database constraints, transactions, state transitions, or explicit idempotency keys.

### Concurrency

PostgreSQL transactions and database constraints should protect:

- World First
- ownership transfer
- contract acceptance
- reward creation
- expedition finalization

## Initial domain candidates

These are candidates, not permission to create all tables immediately.

- User
- Zoo
- Hunter
- Region
- Species
- Animal / ZooAnimal
- Exploration
- Discovery
- HunterContract
- Expedition
- ExpeditionMember
- WorldEvent

Implement only what the current feature needs.

## API

REST contracts should be documented before broad frontend integration.

OpenAPI may be introduced when endpoint scope becomes stable enough to justify it.
