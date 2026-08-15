# REST API — Design Notes

The expedition vertical slice has shipped. The endpoints below the
"Implemented" heading exist and are covered by feature tests; everything
after it is still design notes.

The API is designed around the playable vertical slice rather than around
speculative CRUD — the candidate resource list further down was never built
as written, and should be read as options rather than as a plan.

## Implemented (Task 018)

Player-scoped routes nest under `/players/{player}` so ownership is
explicit in the URL and enforceable before an auth layer exists. Hunters do
not nest: the Guild pool is shared and no player owns a Hunter.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/health` | app + database liveness |
| `POST` | `/api/players` | register (unchanged; response gained `g_balance`) |
| `GET` | `/api/players/{p}` | balance, Zoo totals, expedition counters |
| `GET` | `/api/players/{p}/zoo` | persisted animals with species + rarity |
| `GET` | `/api/players/{p}/maps` | released maps, each with per-player `unlocked` |
| `GET` | `/api/players/{p}/maps/{map}` | one map plus its full spawn table |
| `GET` | `/api/hunters?map_id=` | Guild pool; with a map, each Hunter costed and timed for it |
| `POST` | `/api/players/{p}/expeditions` | dispatch — debits G, returns the expedition |
| `GET` | `/api/players/{p}/expeditions` | list, newest first (never resolves) |
| `GET` | `/api/players/{p}/expeditions/{e}` | one expedition; resolves it if due |
| `POST` | `/api/players/{p}/expeditions/{e}/resolve` | compute the outcome (idempotent) |
| `POST` | `/api/players/{p}/expeditions/{e}/keep` | name it and add it to the Zoo |
| `POST` | `/api/players/{p}/expeditions/{e}/release` | let it go (returns 0 G) |

### Refusals

A rejected action returns a stable machine code alongside a message written
for a player:

```json
{"error": {"code": "insufficient_g",
           "message": "This expedition costs 4550 G. You have 1000 G."}}
```

`404` for a missing player / map / hunter / expedition, `409` for
`already_decided`, `422` for everything else (`map_locked`,
`insufficient_g`, `expedition_not_due`, `nothing_to_decide`,
`dev_instant_resolve_not_allowed`, …). The Application Layer throws
`ExpeditionRejected` with the code and never knows what a status code is;
the mapping lives in `bootstrap/app.php`.

### Idempotency

`resolve` is guarded by `expeditions.resolved_at` under a row lock: a second
call returns the first outcome without re-rolling. `keep` / `release` are
guarded by `decided_at`, with `UNIQUE(zoo_animals.expedition_id)` as the
structural backstop — re-sending the same decision returns the decided
expedition, sending the opposite one is a `409`.

### Development-only acceleration

`POST /players/{p}/expeditions` accepts `"dev_instant_resolve": true`, which
makes the expedition immediately resolvable. It requires all of: an allowed
environment (`local` / `testing`), the config flag, and the per-request
opt-in. Such expeditions carry `"dev_instant_resolve": true` in every
response and in PostgreSQL, and the canonical duration is preserved in
`planned_duration_minutes`. See
[`docs/game-design/RUNTIME_MASTER_DATA.md`](game-design/RUNTIME_MASTER_DATA.md).

---

## Earlier design notes (not implemented as written)

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
