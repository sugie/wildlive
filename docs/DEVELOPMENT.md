# Development

Day-to-day commands for the WildLive local stack.

## Prerequisites

- Docker Engine with Compose v2 (Docker Desktop works)
- ~1 GB free disk for the PHP + PostgreSQL images
- No local PHP or PostgreSQL installation required

## First-run bootstrap

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

The `app` container runs `docker/php/entrypoint.sh`, which:

1. Copies `.env.example` → `.env` if `.env` is missing inside the container.
2. Runs `php artisan key:generate` if `APP_KEY` is empty.
3. Clears the cached config.
4. Starts `php artisan serve` on `0.0.0.0:8000`.

## Verify the stack

Application health (also checks PostgreSQL connectivity):

```bash
curl http://localhost:8000/api/health
```

Framework liveness probe (Laravel built-in):

```bash
curl http://localhost:8000/up
```

## Migrations

```bash
docker compose exec app php artisan migrate
docker compose exec app php artisan migrate:fresh
docker compose exec app php artisan migrate:rollback
```

## Tests

Tests run against a dedicated `wildlive_test` database on the same
PostgreSQL engine. Create it once:

```bash
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "CREATE DATABASE wildlive_test OWNER wildlive;"
```

Then:

```bash
docker compose exec app vendor/bin/phpunit
```

The suite intentionally avoids SQLite so that PostgreSQL-specific
behaviour (types, transactions, constraints used by World First
and expedition resolution) is exercised in tests.

## Common tasks

```bash
docker compose logs -f app          # follow app logs
docker compose logs -f postgres     # follow database logs
docker compose exec app bash        # shell into the app container
docker compose exec postgres psql -U wildlive wildlive
docker compose exec app php artisan tinker
docker compose restart app          # restart after modifying entrypoint or PHP config
```

Stop the stack (keeps the database volume):

```bash
docker compose down
```

Wipe the database volume (destroys all local data):

```bash
docker compose down -v
```

## Adding a PHP extension

Extensions are installed in `docker/php/Dockerfile`. Add the extension to
the `docker-php-ext-install` invocation, then:

```bash
docker compose build app
docker compose up -d
```

Do not add extensions speculatively. See
[`docs/GUARDRAILS.md`](GUARDRAILS.md#dependencies).

## Version choices

| Component     | Version           | Reason                                                                             |
|---------------|-------------------|------------------------------------------------------------------------------------|
| PHP           | 8.5 (cli, bookworm) | Explicit target in the project brief; 8.5 is the current stable line.            |
| Laravel       | ^13.17 (currently 13.25) | Latest 13.x, the target framework version.                                  |
| PostgreSQL    | 15-alpine          | Matches the Sakura Cloud PostgreSQL Appliance used in production. Standardisation is fixed by [`docs/adr/0004-postgresql-15-standardization.md`](adr/0004-postgresql-15-standardization.md); bumping the major version requires a new ADR. |
| Composer      | 2.x                | Standard modern Composer, pulled from `composer:2` image at build time.           |

Bumping any of these is a governance change — open a PR with a short
justification and update `docker/php/Dockerfile`, `docker-compose.yml`,
`composer.json`, and `.github/workflows/ci.yml` together.
