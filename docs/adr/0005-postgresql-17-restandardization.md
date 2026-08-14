# ADR-0005: Restandardize on PostgreSQL 17

- Status: Accepted
- Date: 2026-08-14
- Supersedes: [`ADR-0004: Standardize on PostgreSQL 15`](0004-postgresql-15-standardization.md).
  ADR-0004's body is preserved unchanged as an accurate record of what
  was believed at the time; only its status line is updated to point
  at this ADR.

## Context

ADR-0004 pinned WildLive's development and CI environments on
PostgreSQL 15 on the assumption that the production database would
be the Sakura Cloud PostgreSQL Appliance, whose supported major
version is PostgreSQL 15.

That assumption is no longer correct. A subsequent review of the
production network topology found that the Sakura Cloud PostgreSQL
Appliance cannot be reached from the API server under the network
plan WildLive will use. The appliance therefore will not be used at
all by WildLive.

WildLive's production database will instead be an existing
PostgreSQL cluster (referred to internally as "PostgreSQL Cluster 1"
in operations documentation) running **PostgreSQL 17** with
**pgvector**.

Concrete production-side infrastructure details (host names, ports,
PgBouncer configuration, credentials, OS) are intentionally not
recorded in this repository. They live in operations documentation
outside the WildLive repository.

The rationale in ADR-0004 for choosing PostgreSQL 15 therefore
disappears entirely. Holding the development environment at
PostgreSQL 15 while shipping to a PostgreSQL 17 cluster in
production would leave a permanent, silent major-version-skew
hazard — exactly the failure mode ADR-0004 was written to prevent.

## Decision

WildLive standardises on **PostgreSQL 17** for the local
development environment, the CI environment, and the production
PostgreSQL cluster.

Concretely:

- `docker-compose.yml` pins **`pgvector/pgvector:pg17`** — the
  official pgvector image built on PostgreSQL 17. This is the same
  major version as production and provides the `vector` extension
  out of the box, which production also provides.
- `.github/workflows/ci.yml` pins the same tag as the
  `services.postgres.image`, and the job name is updated to
  `PHPUnit (PHP 8.5 / PostgreSQL 17 + pgvector)` for visibility in
  the Actions UI.
- Every future change to the PostgreSQL major version requires a
  new ADR. Bumping to 18 or later, or downgrading to 15 or 16, is
  not allowed without one.
- `postgres:latest` remains banned everywhere in the repository
  (ADR-0004 already established this ban; this ADR keeps it).

## Consequences

### Positive

- Development, CI, and production share the same PostgreSQL major
  version again — this time on the correct version.
- The `vector` extension is available in every environment,
  matching the production cluster's pgvector support. WildLive's
  design work (see `docs/DECISIONS_PENDING.md` and future ADRs)
  can assume `CREATE EXTENSION vector` succeeds in dev, CI, and
  production without special handling.
- The image tag is explicit — no `latest`, no ambiguity about
  which major version is in use.

### Cost

- Any existing local Docker volume that was initialised by
  PostgreSQL 15 (i.e. everyone who ran the Task 006 stack) must be
  wiped before PostgreSQL 17 will start. PostgreSQL refuses to open
  a data directory from a different major version, regardless of
  direction. For local dev this is a one-time `docker compose down
  -v`; no production data lives on developer machines.
- The historical bilingual reports for Task 006 refer to
  "PostgreSQL 15" in their validation tables. Those references are
  a correct snapshot of what was actually run at the time and are
  intentionally left in place. The report for Task 007 (this
  work) is the new source of truth for the current version.
- The Task 006 X Development Live post — publicly visible at
  `https://x.com/i/status/2088205139912044809` — announced the
  PostgreSQL 15 standardisation. It cannot be un-posted. Task 007
  ships a follow-up X post that plainly states the reversal.

### Boundaries of this decision

- **In scope.** The Docker image, the CI service image, the
  version rationale in `docs/DEVELOPMENT.md`, the version claim in
  `CLAUDE.md`. Marking ADR-0004 as superseded in its status line
  only, without editing its body.
- **Out of scope.** The production API server topology, the exact
  PostgreSQL cluster configuration (host names, ports, PgBouncer,
  credentials, OS), backup / restore policy, network isolation,
  and pricing. Those live outside this repository. This task did
  not touch the production database in any way.

### pgvector

Production runs pgvector 0.8.5. The dev image
`pgvector/pgvector:pg17` ships whatever pgvector version its
upstream tag currently points at; WildLive does not pin a
pgvector patch version in this ADR because no application code
currently depends on a specific pgvector feature. If a future
task adds vector-index code that relies on a particular pgvector
feature, that task should pin the pgvector image to a specific
tag and record the pin in a new ADR.

Verified in dev by:

```
docker compose exec postgres psql -U wildlive -d wildlive \
  -c 'CREATE EXTENSION IF NOT EXISTS vector;'
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';"
```

Exact output is recorded in
[`docs/reports/en/task-007-postgres-17-restandardization.html`](../reports/en/task-007-postgres-17-restandardization.html).

### PostgreSQL 17 compatibility audit

Performed as part of this task. No repository changes required
beyond what this ADR ships:

- No raw SQL migrations exist. All three shipped migrations use
  Laravel Blueprint methods that compile to portable SQL supported
  on both PostgreSQL 15 and 17.
- The one PostgreSQL identity assertion in
  `tests/Feature/HealthTest.php` (`stringContainsStringIgnoringCase('postgresql', $version->version)`)
  works identically against 17.x.
- No application code uses any PostgreSQL-15-only construct.

### Live verification

Performed against the shipped `docker-compose.yml` on a clean
`postgres-data` volume:

```
docker compose exec postgres psql -U wildlive -d wildlive -c 'SELECT version();'
→ PostgreSQL 17.x on <arch>-linux-gnu, compiled by <toolchain>

docker compose exec postgres psql -U wildlive -d wildlive -c 'SHOW server_version;'
→ 17.x

docker compose exec postgres psql -U wildlive -d wildlive -c \
  'CREATE EXTENSION IF NOT EXISTS vector;'
→ CREATE EXTENSION

docker compose exec postgres psql -U wildlive -d wildlive -c \
  "SELECT extversion FROM pg_extension WHERE extname = 'vector';"
→ 0.x.x (exact patch recorded in the Task 007 report)

docker compose exec app php artisan migrate --force
→ 3 framework migrations applied

docker compose exec app vendor/bin/phpunit
→ 5 tests, 9 assertions, all pass on PHP 8.5.9 + PostgreSQL 17
```

### Non-goals

- No change to any application code, controller, route, migration,
  dependency, or workflow permission.
- No modification to the historical Task 001 – Task 006 bilingual
  reports, X manifests, or AI session archive records. Those are
  audit snapshots of what was true at their time of writing and
  must remain intact.
- No connection to, or change to, the production PostgreSQL
  cluster. This task did not run any DDL, DML, or configuration
  change against production.

### Human intervention

The human (repository owner) discovered that the Sakura Cloud
PostgreSQL Appliance is not viable for WildLive's network
topology, confirmed that the production database is the existing
PostgreSQL Cluster 1 running PostgreSQL 17 with pgvector, and
decided the restandardisation. The AI (Claude Code) audited the
PR-#10 changeset, identified which parts corresponded strictly to
the PostgreSQL 15 spec change (as opposed to preserved historical
audit records), performed the reversal with minimum footprint,
live-verified against a running PostgreSQL 17 + pgvector stack,
and wrote this ADR. No push, no PR, no merge was performed —
those are held for explicit human authorisation.
