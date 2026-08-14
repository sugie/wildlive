# REST API — Design Notes

No stable API exists yet.

The API should be designed around the first playable vertical slice rather than around speculative CRUD.

## Candidate resources

```text
/api/me
/api/zoo
/api/hunters
/api/regions
/api/explorations
/api/species
/api/discoveries
/api/world
```

## Candidate flow

### Start an exploration

```http
POST /api/explorations
```

Server validates:

- hunter ownership / availability
- region availability
- cost
- duration
- game rules

Server chooses authoritative timestamps.

### Inspect an exploration

```http
GET /api/explorations/{id}
```

### Resolve an expired exploration

Possible approaches:

```http
POST /api/explorations/{id}/resolve
```

or lazy resolution during retrieval.

The final contract should favor explicit, testable behavior and idempotency.

## API principles

- JSON
- server-authoritative state
- explicit validation errors
- stable error structure
- no authoritative rewards submitted by clients
- timestamps in a clearly documented standard
- authentication added before public multiplayer access
