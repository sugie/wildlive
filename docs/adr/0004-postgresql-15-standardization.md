# ADR-0004: Standardize on PostgreSQL 15

- Status: Accepted
- Date: 2026-08-14
- Supersedes (in part): the PostgreSQL version choice recorded in
  [`docs/reports/en/task-001-docker-foundation.html`](../reports/en/task-001-docker-foundation.html)
  and its Japanese counterpart. The Task 001 report claimed
  "PostgreSQL 16, not 17 — chosen for alignment with the Sakura
  Cloud PostgreSQL appliance". That claim turned out to be wrong
  about the appliance's actual major version. This ADR corrects
  the choice going forward. **The historical reports are left
  intact as an accurate audit record of what was believed at their
  time of writing.**

## Context

WildLive's production database will be the Sakura Cloud PostgreSQL
Appliance. The human (repository owner) has confirmed that the
appliance's supported major version is **PostgreSQL 15**.

Task 001 pinned the local Docker Compose PostgreSQL to
`postgres:16-alpine`, and Task 001's CI workflow used the same tag.
Both were pinned in the belief that the Sakura Cloud appliance was
PostgreSQL 16 (or at least tolerant of 16). That belief was
incorrect. Keeping development on PostgreSQL 16 while shipping to
PostgreSQL 15 in production would leave a permanent, silent
version-skew hazard.

## Decision

WildLive standardises on **PostgreSQL 15** for the local
development environment, the CI environment, and (for the
avoidance of doubt) the production Sakura Cloud PostgreSQL
Appliance.

Concretely:

- `docker-compose.yml` pins `postgres:15-alpine` (exact major
  version tag; the `-alpine` variant is the smallest official
  image and matches what the repository used before).
- `.github/workflows/ci.yml` pins the same tag as the
  `services.postgres.image`, and the job name is updated to
  `PHPUnit (PHP 8.5 / PostgreSQL 15)` for clarity in the Actions
  UI.
- Every future change to the PostgreSQL major version requires a
  new ADR under `docs/adr/`. Bumping to 16, 17, 18, or `latest`
  is not allowed without one.
- `postgres:latest` is banned everywhere in the repository.

## Consequences

### Positive

- Development, CI, and production share the same PostgreSQL major
  version. Concurrency, index-plan, and SQL-syntax behaviour will
  match at every stage of the pipeline.
- The Docker image tag is explicit — no `latest`, no "whatever the
  minor happens to be today" ambiguity.
- Locking the decision into an ADR makes an accidental future bump
  ("everyone else is on 16, let's upgrade") visible in review.

### Cost

- Any existing local Docker volume that was initialised by
  PostgreSQL 16 must be wiped before PostgreSQL 15 will start.
  PostgreSQL will refuse to open a data directory from a newer
  major version. For local dev this is a one-time
  `docker compose down -v`; there is no production data on
  developer machines.
- The historical bilingual reports for Task 001 and later refer to
  "PostgreSQL 16" in their validation tables. Those references are
  a correct snapshot of what was actually run at the time and are
  intentionally left in place.

### Boundaries of this decision

- **In scope.** The Docker image, the CI service image, the
  version rationale in `docs/DEVELOPMENT.md`, the version claim in
  `CLAUDE.md`.
- **Out of scope.** The production API server topology, the
  appliance provisioning process, backup / restore policy, network
  isolation, and pricing. Those live in
  [`docs/DEPLOYMENT.md`](../DEPLOYMENT.md) and later deployment
  ADRs.

### PostgreSQL-15 compatibility audit

Performed as part of this task. No changes required:

- No `pgvector` extension is present or referenced anywhere in the
  repository.
- No raw SQL migrations exist; all three migrations
  (`0001_01_01_000000_create_users_table`,
  `0001_01_01_000001_create_cache_table`,
  `0001_01_01_000002_create_jobs_table`) use Laravel's Blueprint
  API, which compiles to portable PostgreSQL syntax supported by
  PostgreSQL 15 and earlier.
- Application code uses `DB::selectOne('select version() as version')`
  in the health check and one PostgreSQL identity assertion in
  `tests/Feature/HealthTest.php`; both work identically on 15.x.
- No PostgreSQL-16-or-newer-only SQL feature (e.g. `MERGE` with
  `RETURNING`, `IS JSON`, expanded logical-replication surface,
  ICU database defaults) is used.

### Live verification

Performed against the shipped `docker-compose.yml` on a clean
`postgres-data` volume:

```
docker compose exec postgres psql -U wildlive -d wildlive -c 'SELECT version();'
→ PostgreSQL 15.19 on aarch64-unknown-linux-musl,
  compiled by gcc (Alpine 15.2.0) 15.2.0, 64-bit

docker compose exec postgres psql -U wildlive -d wildlive -c 'SHOW server_version;'
→ 15.19

docker compose exec app php artisan migrate --force
→ 3 framework migrations applied

docker compose exec app vendor/bin/phpunit
→ 5 tests, 9 assertions, all pass on PHP 8.5.9 + PostgreSQL 15.19
```

### Human intervention

The human (repository owner) decided this standardisation and the
production-parity rationale. The AI (Claude Code) audited the
repository, made the minimal edits, verified the live server
version, and wrote this ADR.
