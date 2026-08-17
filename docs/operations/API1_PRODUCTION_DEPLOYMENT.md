# api1 production deployment (WildLive API backend)

> **Scope.** This document describes how the WildLive REST API is deployed on
> the `api1` host that WildLive shares with other services (notably
> HeyRasshai). It is the operational counterpart to the pre-production
> intent recorded in [`docs/DEPLOYMENT.md`](../DEPLOYMENT.md), which
> describes the *future* Sakura Cloud AppRun target. Both are valid: this
> file documents what is actually running today; `DEPLOYMENT.md` records
> where the deployment is heading.
>
> **Audience.** Humans, Claude Code, Devin, and any other AI agent who
> needs to reason about the api1 production configuration, deploy, or
> recover from an incident.
>
> **Non-goals.** Provisioning the host, managing the OS, or running the
> shared Enhanced Load Balancer. Those are outside the WildLive repository.

## Ground rules for editing this file

- Only document what is actually deployed. Mark anything else as
  **Recommended** or **Not yet implemented**.
- Never commit real secrets, passwords, `APP_KEY`, SCRAM secrets, API
  keys, SSH keys, or `.env` contents. Use placeholders such as
  `<REDACTED>`, `<APP_HOST_IP>`, or `<ELB_EGRESS_CIDR>`.
- Public IPs, private CIDRs, and shared-host details that are not
  strictly required for the WildLive workflow should also stay as
  placeholders.
- Prefer additive changes; if a section becomes wrong, replace it in the
  same edit rather than leaving contradictory guidance.

---

## 1. System architecture

```text
                   ┌───────────────────────────────────┐
                   │   Sakura Cloud Enhanced LB        │
                   │   (HTTPS termination, WAF, ACL)   │
   Internet  ───►  │   Public host: wlapi.misologic.com│
                   └───────────────┬───────────────────┘
                                   │  HTTP  (private, ELB egress only)
                                   ▼
                   ┌───────────────────────────────────┐
                   │   api1 host                       │
                   │                                   │
                   │  ┌─────────────────────────────┐  │
                   │  │ Docker (compose project:    │  │
                   │  │   wildlive, network:        │  │
                   │  │   isolated from HeyRasshai) │  │
                   │  │                             │  │
                   │  │  wildlive-app               │  │
                   │  │  FrankenPHP + Laravel 13    │  │
                   │  │  published: 127.0.0.1:8081  │  │
                   │  │  /up      liveness (no DB)  │  │
                   │  │  /api/health incl. DB SELECT│  │
                   │  └────────────┬────────────────┘  │
                   │               │ TCP               │
                   │               ▼                   │
                   │  ┌─────────────────────────────┐  │
                   │  │ PgBouncer (transaction pool)│  │
                   │  │ SCRAM-SHA-256 auth          │  │
                   │  └────────────┬────────────────┘  │
                   │               │                   │
                   │               ▼                   │
                   │  ┌─────────────────────────────┐  │
                   │  │ PostgreSQL 17 (+pgvector)   │  │
                   │  │ database: wildlive          │  │
                   │  │ role    : wildlive_app      │  │
                   │  └─────────────────────────────┘  │
                   │                                   │
                   │  UFW (host firewall)              │
                   │  iptables DOCKER-USER (Docker     │
                   │    published-port gate)           │
                   └───────────────────────────────────┘
```

Key points that the diagram encodes:

- The public entry point is `https://wlapi.misologic.com`, terminated at
  the Sakura Cloud Enhanced Load Balancer. `api1` never receives raw
  Internet traffic.
- On `api1`, WildLive publishes only `127.0.0.1:8081` at the Docker
  level; ingress from anything other than the Enhanced LB is rejected
  at the `DOCKER-USER` chain (see §5).
- PostgreSQL is reached through PgBouncer in transaction-pooling mode.
  Laravel opens a fresh connection per request but PgBouncer keeps the
  backend pool warm.
- WildLive and HeyRasshai share the host but not the Docker Compose
  project, the published port, the database, the role, or the
  deployment path (see §2 and §13).

## 2. Filesystem layout on api1

Three distinct roots keep code, deployment configuration, and secrets
on separate lifecycles.

| Path              | Owner / purpose                                                                                              | Committed to Git?         |
|-------------------|--------------------------------------------------------------------------------------------------------------|---------------------------|
| `/var/apps/wildlive` | Application source (checkout of `github.com/sugie/wildlive`). Docker builds run from here.                | Yes (this repository).    |
| `/opt/wildlive`   | Production deployment configuration: `docker-compose.override.yml` (if any), `deploy.env`, `deploy.env.previous`, systemd units, deploy helper scripts. | **No**. Managed on the host. |
| `/etc/wildlive`   | Secrets only: `.env`-style files with `APP_KEY`, database passwords, SCRAM verifiers, third-party keys.       | **Never**. Root-owned, mode `0700`, files `0600`. |

The split is intentional:

- `/var/apps/wildlive` can be wiped and re-cloned; nothing there is
  irreplaceable.
- `/opt/wildlive` describes *how* to run the current release
  (image tag, git SHA, ports). Rolling back a bad release is a matter of
  swapping `deploy.env` for `deploy.env.previous` and restarting the
  compose project.
- `/etc/wildlive` contains anything that would compromise the
  deployment if leaked. Nothing in it is ever printed in logs or
  committed to Git.

**Never** commit anything from `/opt/wildlive` or `/etc/wildlive` into
this repository, even redacted, unless it is a template with all secret
fields removed.

## 3. Docker / FrankenPHP / Laravel

### What the repository ships

The repository currently ships a *development* Docker stack only:
[`docker-compose.yml`](../../docker-compose.yml) plus
[`docker/php/Dockerfile`](../../docker/php/Dockerfile), which runs
`php artisan serve` on `php:8.5-cli-bookworm`. This is what
[`docs/DEVELOPMENT.md`](../DEVELOPMENT.md) documents and is what the
CI pipeline exercises.

### What runs on api1

`api1` runs the same Laravel 13 application code, but under **FrankenPHP**
rather than `artisan serve`, and behind a production compose file that
lives on the host (in `/opt/wildlive`), not in this repository.

- Compose project name: `wildlive` (isolates the network, containers,
  and volumes from HeyRasshai's compose project on the same host).
- Application container: FrankenPHP serving the Laravel `public/`
  document root.
- Published port: `127.0.0.1:8081` only — never a wildcard bind. The
  Enhanced LB reaches this via the host's private interface; see §4.
- Environment: sourced from `/etc/wildlive/*.env` (secrets) and
  `/opt/wildlive/deploy.env` (release metadata, non-secret).
- Image tag: pinned per release; the tag and the source git SHA are
  both recorded in `/opt/wildlive/deploy.env` so a running container
  can always be traced back to a commit.

### Release identity

Two fields in `/opt/wildlive/deploy.env` are load-bearing:

| Variable          | Meaning                                                    |
|-------------------|------------------------------------------------------------|
| `GIT_REVISION`    | Full SHA of the commit the running image was built from.   |
| `DOCKER_IMAGE`    | Fully qualified image reference (registry/name:tag).       |

Compose interpolates both, so **every `docker compose` invocation on
api1 must be run with `--env-file /opt/wildlive/deploy.env`**. Without
it, compose fails with `GIT_REVISION missing` (see §12).

## 4. Enhanced LB → api1:8081

- Frontend: Sakura Cloud Enhanced Load Balancer, listener
  `https://wlapi.misologic.com` (443, HTTPS).
- Backend: `api1` private address, TCP `8081`.
- LB health check: `GET /up`. This endpoint is provided by Laravel's
  built-in `health: '/up'` route configured in
  [`bootstrap/app.php:37`](../../bootstrap/app.php). It returns `200`
  without touching PostgreSQL, so it is safe to poll every few seconds
  and it will not go red during a transient DB blip.
- Application health check (for humans / on-call, not the LB):
  `GET /api/health`, defined in [`routes/api.php:11`](../../routes/api.php)
  and implemented in
  [`app/Http/Controllers/HealthController.php`](../../app/Http/Controllers/HealthController.php).
  This one runs `select 1` against PostgreSQL and returns HTTP `503`
  with `status=degraded` if the DB is unreachable. **Do not** wire this
  to the LB — a slow DB should not depool the whole API.

## 5. Firewall and DOCKER-USER

Two layers control who can reach `api1:8081`.

1. **UFW** on the host allows inbound `8081/tcp` only from the Enhanced
   LB's egress addresses (or from `127.0.0.1` for local debugging).
2. **iptables `DOCKER-USER` chain** enforces the same policy at the
   Docker layer.

The second layer is not redundant. Docker's own `iptables` rules run
*before* the standard `INPUT` chain that UFW manages, so a wildcard
publish (`0.0.0.0:8081->8081/tcp`) would bypass UFW entirely. Two
mitigations, both applied:

- Publish only on `127.0.0.1:8081` in compose. This is the primary
  defence: the port is not reachable on any external interface at all.
- Add explicit `DOCKER-USER` rules that drop traffic destined for the
  container's port from anything other than the Enhanced LB range and
  loopback. This is defence in depth in case the compose file is ever
  edited to bind to `0.0.0.0`.

Concrete CIDRs are intentionally not committed to this repository —
they belong in `/etc/wildlive` / host configuration. Placeholders used
below:

- `<ELB_EGRESS_CIDR>` — the Sakura Cloud Enhanced LB egress range.
- `<APP_HOST_IP>` — the api1 private-network address.

If you need to inspect what is currently in effect on a running host:

```bash
sudo ufw status verbose
sudo iptables -n -L DOCKER-USER --line-numbers
sudo ss -ltnp | grep 8081
```

## 6. PostgreSQL and PgBouncer

### PostgreSQL

- Version: PostgreSQL 17 with pgvector, matching the
  `pgvector/pgvector:pg17` line used locally and in CI (fixed by
  [`docs/adr/0005-postgresql-17-restandardization.md`](../adr/0005-postgresql-17-restandardization.md)).
- Database: `wildlive`.
- Owning role for application access: `wildlive_app`.
- The role is application-scoped: it owns the `wildlive` database
  objects but is not a superuser. Administrative work (creating the
  role, granting `CREATEDB`/`OWNER`, running major-version upgrades)
  is done by a separate superuser account that is **not** the role the
  application authenticates as.
- HeyRasshai on the same host uses a different database and a different
  role. WildLive's role has no rights on HeyRasshai's objects, and vice
  versa.

### PgBouncer

- Mode: **transaction pooling**. Laravel opens a short-lived logical
  connection per request; PgBouncer multiplexes those onto a small pool
  of long-lived PostgreSQL backend connections.
- Authentication: **SCRAM-SHA-256** for the `wildlive_app` role. The
  SCRAM verifier is copied from PostgreSQL's `pg_shadow` (or generated
  with `psql`'s `\password`) into PgBouncer's `userlist.txt`. PgBouncer
  itself must therefore be configured with `auth_type = scram-sha-256`.
- Registration: the `wildlive` database must be listed explicitly in
  `pgbouncer.ini`'s `[databases]` section. See §12 for the failure mode
  when it is not.
- Application connection: Laravel points `DB_HOST`/`DB_PORT` at
  PgBouncer, not at PostgreSQL directly. This is what the `wildlive_app`
  role's credentials in `/etc/wildlive` authenticate against.

### Transaction-pool caveats

Transaction pooling means server-side session state is not preserved
between statements. In practice for WildLive:

- Prepared statements with server-side plan caching must be avoided or
  scoped per-statement. Laravel's Eloquent uses PDO's
  `emulate_prepares=true` on PgSQL by default, which is compatible.
- `LISTEN`/`NOTIFY`, session-scoped `SET`, temporary tables that
  survive statements, and `SET LOCAL` outside a transaction do not
  work reliably. WildLive currently uses none of these.
- Advisory locks scoped to a session (`pg_advisory_lock`) must be
  transaction-scoped (`pg_advisory_xact_lock`) instead.

If a future feature needs any of the above, either move it to a
dedicated non-pooled connection, or switch that connection to session
pooling — do not silently break the pool contract.

## 7. First-time DB bring-up, migrations, seeding

The initial bring-up on `api1` was, and future rebuilds should be:

```bash
cd /var/apps/wildlive

# 1. Ensure release metadata is loaded — required for every compose call.
export COMPOSE_ENV=--env-file=/opt/wildlive/deploy.env

# 2. Bring the app container up (does not require the DB yet if only
#    building; the DB itself is a separate service, not part of the
#    WildLive compose project).
docker compose $COMPOSE_ENV up -d

# 3. Create the database and role. Done once, by a PostgreSQL superuser,
#    OUTSIDE the WildLive compose project:
#      CREATE ROLE wildlive_app LOGIN PASSWORD '<REDACTED>';
#      CREATE DATABASE wildlive OWNER wildlive_app;
#    Then export the SCRAM verifier from pg_shadow into PgBouncer's
#    userlist.txt and register the `wildlive` database in pgbouncer.ini.
#    Reload PgBouncer.

# 4. Run Laravel migrations. On a brand new database `migrate:status`
#    will report "Migration table not found." — that is expected;
#    `migrate --force` creates the table before applying migrations.
docker compose $COMPOSE_ENV exec app php artisan migrate --force

# 5. Seed Game Master data. Without this there are no maps, hunters,
#    or animals, and no gameplay is possible.
docker compose $COMPOSE_ENV exec app php artisan db:seed --force
```

Migration count and seeder as of this document:

- 9 migrations under
  [`database/migrations/`](../../database/migrations/) — the 3 Laravel
  framework migrations (users / cache / jobs) plus 6 WildLive
  migrations (`players`, `zoos`, `create_game_master_tables`,
  `add_g_balance_to_players`, `expeditions`, `zoo_animals`).
- 1 seeder: [`GameMasterSeeder`](../../database/seeders/GameMasterSeeder.php),
  invoked from [`DatabaseSeeder`](../../database/seeders/DatabaseSeeder.php).
  It upserts by Game Master id, so re-running after a master-data
  refresh updates rows in place and leaves player state intact
  ([details](../DEVELOPMENT.md#migrations-and-game-master-data)).

Everything above was performed on api1 during the initial bring-up.

## 8. Standard deploy

The current process is a git-pull + image-swap on the host. All steps
run as the deploy user on `api1`.

```bash
cd /var/apps/wildlive
git fetch --tags origin
git checkout <release-sha-or-tag>

# Build the production image locally (or pull, if a registry is used).
docker build -t wildlive-app:<release-sha> -f docker/php/Dockerfile .
#   ^ or the production-specific Dockerfile that lives on the host if
#     the FrankenPHP build is not yet in this repo.

# Update /opt/wildlive/deploy.env with the new GIT_REVISION and
# DOCKER_IMAGE. Copy the previous file aside first:
sudo cp /opt/wildlive/deploy.env /opt/wildlive/deploy.env.previous
sudo editor /opt/wildlive/deploy.env    # bump GIT_REVISION, DOCKER_IMAGE

# Apply.
sudo docker compose \
  --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml \
  up -d

# Run any new migrations. `migrate --force` is a no-op if the schema is
# already current, so this is safe to run on every deploy.
sudo docker compose \
  --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml \
  exec app php artisan migrate --force

# Re-seed only if the Game Master data changed (the seeder is
# idempotent; skipping it when nothing changed still costs one DB round
# trip per row).
sudo docker compose \
  --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml \
  exec app php artisan db:seed --force

# Verify.
curl -sf https://wlapi.misologic.com/up            # LB path
curl -sf https://wlapi.misologic.com/api/health    # DB path
```

Non-negotiables:

- Never run destructive Artisan commands on production: no
  `migrate:fresh`, no `migrate:reset`, no `db:wipe`. If a destructive
  change is genuinely required, treat it as an incident and get human
  approval before proceeding.
- Never edit files under `/etc/wildlive` from a deploy script that
  logs its arguments — expand secrets via the container's env, not on
  the shell command line.
- Never bypass CI. A release SHA that has not been through CI on
  `main` is not eligible for production. See
  [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml).

## 9. Health checks

Two endpoints, two audiences.

| Endpoint       | Status codes           | Depends on DB | Used by                                    |
|----------------|------------------------|---------------|--------------------------------------------|
| `GET /up`      | `200` (always if PHP is up) | No       | Enhanced LB, container livenessProbe.       |
| `GET /api/health` | `200` ok / `503` degraded | Yes    | Humans, on-call, deploy verification.       |

Rules of thumb:

- If `/up` is `200` and `/api/health` is `503`: the app is alive but
  cannot reach PostgreSQL (via PgBouncer). See §12.
- If `/up` is failing: the container itself is unhealthy. Check
  `docker compose logs app`.
- If both are `200` but the app misbehaves: the DB is reachable but
  the schema may be out of date, or a seeder may not have run. Compare
  `php artisan migrate:status` output against the number of migration
  files in the repository.

## 10. Rollback

Rollback is release-metadata driven, not filesystem-snapshot driven:

```bash
# 1. Restore the previous release metadata.
sudo cp /opt/wildlive/deploy.env /opt/wildlive/deploy.env.failed
sudo cp /opt/wildlive/deploy.env.previous /opt/wildlive/deploy.env

# 2. Bring the previous image back up.
sudo docker compose \
  --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml \
  up -d

# 3. Verify.
curl -sf https://wlapi.misologic.com/up
curl -sf https://wlapi.misologic.com/api/health
```

Migrations require judgement:

- WildLive migrations are expected to be **additive and reversible**
  ([`docs/GUARDRAILS.md`](../GUARDRAILS.md#database)). If the failed
  release added columns that the previous image does not read, no
  rollback of the schema is required — the old image simply ignores
  them.
- If the failed release ran a destructive migration, rolling back the
  image is not sufficient. Stop, escalate to a human, and restore from
  the latest PostgreSQL backup. Never attempt schema-recovery under
  time pressure.

## 11. Daily / weekly operational checks

Run against api1 (adjust for however you shell in):

```bash
# Release identity.
grep -E '^(GIT_REVISION|DOCKER_IMAGE)=' /opt/wildlive/deploy.env

# Containers and health.
sudo docker compose --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml ps
curl -sf http://127.0.0.1:8081/up
curl -sf http://127.0.0.1:8081/api/health | jq .

# Application log tail.
sudo docker compose --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml logs --tail=100 app

# Schema state.
sudo docker compose --env-file /opt/wildlive/deploy.env \
  -f /opt/wildlive/docker-compose.yml exec app php artisan migrate:status

# PgBouncer pool state (from the api1 host, as a PgBouncer admin user).
psql -h 127.0.0.1 -p 6432 -U pgbouncer_admin pgbouncer -c "SHOW POOLS;"

# Firewall posture.
sudo ufw status verbose
sudo iptables -n -L DOCKER-USER --line-numbers

# Confirm the app port is not exposed publicly.
sudo ss -ltnp | grep -E '(:8081|8081/tcp)'
```

## 12. Troubleshooting

Real failures we hit during the initial bring-up (or that we expect on
next bring-up), and what to do.

### `docker compose ... GIT_REVISION missing`

*Symptom.* Running any `docker compose` command on api1 exits with a
message about `GIT_REVISION` (and/or `DOCKER_IMAGE`) being unset.

*Cause.* The compose file interpolates these variables. They live in
`/opt/wildlive/deploy.env`, not in the shell environment.

*Fix.* Always pass `--env-file /opt/wildlive/deploy.env` (or set
`COMPOSE_ENV_FILES=/opt/wildlive/deploy.env` in the shell). Consider
adding a small wrapper script in `/opt/wildlive/` so operators do not
have to remember.

### `php artisan migrate:status` prints `Migration table not found.`

*Symptom.* On a brand-new database, `migrate:status` fails with
`Migration table not found. Run 'migrate' to create it.`

*Cause.* Laravel creates the `migrations` bookkeeping table the first
time `migrate` runs; `migrate:status` refuses to invent it.

*Fix.* Run `php artisan migrate --force` once. Subsequent
`migrate:status` calls will work. This is *expected* for a fresh
database — do not interpret it as data loss.

### PgBouncer rejects the `wildlive_app` login

*Symptom.* Laravel logs `SQLSTATE[08006] ... no such user` or
`no such database: wildlive`, even though the credentials work when
connecting directly to PostgreSQL on 5432.

*Cause.* PgBouncer maintains its own database and user registries.
Either the `wildlive` database is not listed in `[databases]`, or the
`wildlive_app` role is not in `userlist.txt` with the correct
SCRAM-SHA-256 verifier, or `auth_type` in `pgbouncer.ini` is not set
to `scram-sha-256`.

*Fix.* On the api1 host:

1. Confirm `pgbouncer.ini` contains a `[databases]` entry for
   `wildlive = host=127.0.0.1 port=5432 dbname=wildlive`.
2. Confirm `auth_type = scram-sha-256`.
3. Copy the current SCRAM verifier for `wildlive_app` from PostgreSQL:
   `SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'wildlive_app';`
   and paste it (surrounded by double-quotes as the second field) into
   PgBouncer's `userlist.txt`.
4. `pgbouncer -R` (reload) or restart the PgBouncer service.
5. Retry `curl http://127.0.0.1:8081/api/health` — the `database.ok`
   field should now be `true`.

### `/up` returns 200 but the app still misbehaves

*Symptom.* The LB is happy, but requests that touch the database
error out with 500s.

*Cause.* `/up` deliberately does not touch PostgreSQL. It only proves
that PHP is running.

*Fix.* Always cross-check with `/api/health`, which does hit the DB.
When investigating an incident, treat `/up=200 && /api/health=503` as
"PHP up, DB path broken" and jump straight to PgBouncer / PostgreSQL
logs.

### Container port unexpectedly reachable from off-host

*Symptom.* `curl http://<APP_HOST_IP>:8081/up` from a machine that is
not the Enhanced LB succeeds.

*Cause.* Docker's own `iptables` rules run before the `INPUT` chain
that UFW manages. A compose change to `0.0.0.0:8081` (or the absence
of the loopback prefix) will make the port reachable on every
interface, and UFW alone will not stop it.

*Fix.* Two things, both required:

1. Restore the loopback bind in the production compose file
   (`127.0.0.1:8081:8081`).
2. Confirm the `DOCKER-USER` chain rejects `-p tcp --dport 8081`
   traffic from anything outside `<ELB_EGRESS_CIDR>` and `127.0.0.1`.

This is the reason the deployment relies on `DOCKER-USER` and not on
UFW alone — see §5.

## 13. Isolation from HeyRasshai

WildLive shares api1 with HeyRasshai. Everything below is separate:

| Concern                | HeyRasshai            | WildLive               |
|------------------------|-----------------------|------------------------|
| Compose project        | HeyRasshai's project  | `wildlive`             |
| Published host port    | (HeyRasshai's port)   | `127.0.0.1:8081`       |
| Deployment path        | HeyRasshai's own path | `/opt/wildlive`        |
| Application source     | HeyRasshai's own path | `/var/apps/wildlive`   |
| Secrets root           | HeyRasshai's own path | `/etc/wildlive`        |
| PostgreSQL database    | HeyRasshai's DB       | `wildlive`             |
| PostgreSQL role        | HeyRasshai's role     | `wildlive_app`         |
| Public hostname        | (HeyRasshai's)        | `wlapi.misologic.com`  |

Do not "consolidate" any of these without a written decision. The
isolation is the reason a bad WildLive deploy cannot take HeyRasshai
down and vice versa.

## 14. Currently implemented vs. recommended

### Currently implemented on api1

- WildLive API running under Docker Compose on api1, FrankenPHP +
  Laravel 13, published on `127.0.0.1:8081`.
- Source at `/var/apps/wildlive`, deployment config at `/opt/wildlive`,
  secrets at `/etc/wildlive`.
- Public entry via Sakura Cloud Enhanced LB at
  `https://wlapi.misologic.com`.
- `/up` (LB / Docker health check, no DB) and `/api/health` (application
  health check with `SELECT 1`) both live.
- PostgreSQL 17 with pgvector, database `wildlive`, role
  `wildlive_app`, accessed via PgBouncer in transaction-pool mode with
  SCRAM-SHA-256.
- 9 migrations applied; `GameMasterSeeder` run.
- Host published port controlled by both a loopback bind *and* a
  `DOCKER-USER` rule that only accepts the Enhanced LB egress.
- Release identity (`GIT_REVISION`, `DOCKER_IMAGE`) tracked in
  `/opt/wildlive/deploy.env`, with the previous release preserved in
  `/opt/wildlive/deploy.env.previous` for rollback.
- WildLive and HeyRasshai isolated at every layer listed in §13.

### Recommended (not yet implemented)

Items below are not requirements today but are the natural next steps
for hardening. None is a blocker for the current pre-alpha vertical
slice.

- **Committed production Dockerfile.** The repository still ships only
  the development `docker/php/Dockerfile`. A `docker/php/Dockerfile.prod`
  (FrankenPHP-based, `composer install --no-dev`, opcache preload)
  belongs in this repo so the build is reproducible from a clean
  checkout without host-only files.
- **GitHub Actions deploy job.** CI currently only runs tests. A
  workflow that builds and pushes the production image on `main` (and
  optionally triggers a pull on api1) is the standard next step, in
  line with the future direction recorded in
  [`docs/DEPLOYMENT.md`](../DEPLOYMENT.md).
- **Off-host backups.** A verified nightly `pg_dump` of the `wildlive`
  database, shipped off `api1`, with a documented restore drill.
- **Migration reversibility CI check.** Extend
  [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) to run
  `php artisan migrate --force && php artisan migrate:rollback` on
  every PR so an accidentally destructive migration fails CI.
- **Structured request logs.** Ship application logs off-host to a
  central sink (STDOUT is captured by Docker today, but nothing rotates
  it off `api1`).
- **Container livenessProbe wired to `/up`.** Docker Compose supports
  `healthcheck:` — mirror the LB's `/up` check inside the compose file
  on api1 so an unhealthy container restarts itself.
- **Move toward the AppRun target.** Long-term, the deployment is
  intended to migrate to Sakura Cloud AppRun with a managed PostgreSQL
  appliance ([`docs/DEPLOYMENT.md`](../DEPLOYMENT.md)). Nothing in this
  api1 configuration blocks that migration; the same image, migrations,
  and health endpoints will work unchanged.

---

## See also

- [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md) — local Docker Compose
  stack; command reference for `docker compose`, `migrate`, `db:seed`,
  `phpunit`.
- [`docs/DEPLOYMENT.md`](../DEPLOYMENT.md) — the intended future target
  (Sakura Cloud AppRun + managed PostgreSQL) and the requirements that
  must be satisfied before production traffic moves there.
- [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — architectural
  principles (server-authoritative state, idempotent resolution,
  time-based idle actions).
- [`docs/GUARDRAILS.md`](../GUARDRAILS.md) — non-negotiable rules,
  including "no destructive production changes without human approval".
- [`docs/adr/0005-postgresql-17-restandardization.md`](../adr/0005-postgresql-17-restandardization.md)
  — why PostgreSQL 17 with pgvector, and what bumping the major version
  requires.
