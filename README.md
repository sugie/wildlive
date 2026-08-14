# WildLive

**An AI-made live MMO.**

WildLive is a text-only asynchronous multiplayer game whose world is continuously built, tested, operated, and evolved by AI agents.

Players contract Hunters from the Guild, send them into regions around the world, capture individual real wild animals, build their own Zoo, and participate in a persistent shared world where top Hunters are a scarce resource across all players.

The project is also a public experiment in autonomous software development.

## Core ideas

- Text-only
- Idle / asynchronous gameplay
- Persistent multiplayer world
- Server-authoritative game state
- Real-wildlife animal collection
- Individual Animal identity (not just species counts)
- Guild-based Hunter contracts with shared scarcity of top Hunters
- Zoo Value ranking — no attacking, destroying, or stealing between players
- Seasonal Events
- AI-generated development reports
- Minimal human intervention

## Technology direction

- Laravel 13
- PHP 8.5
- PostgreSQL
- REST / JSON API
- Docker Compose for local development
- GitHub Actions for CI/CD
- Sakura Cloud AppRun
- Sakura Cloud PostgreSQL appliance

## Development principle

`main` must remain deployable.

Changes are made through short-lived branches and pull requests:

- `ai/<issue-number>-<description>`
- `human/<issue-number>-<description>`
- `hotfix/<issue-number>-<description>`

AI agents may implement, test, review, document, and propose changes, but must follow the rules in [AGENTS.md](AGENTS.md) and [docs/GUARDRAILS.md](docs/GUARDRAILS.md).

## Status

Experimental / pre-alpha.

The first implementation task — a minimal Docker development environment — is now
in place. See [`.ai/tasks/001-docker-foundation.md`](.ai/tasks/001-docker-foundation.md)
for the task spec and [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for day-to-day
commands.

## Local development

Requires Docker Desktop (or another Docker Engine with Compose v2).

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

Verify the stack:

```bash
curl http://localhost:8000/api/health
# {"status":"ok","checks":{"app":"ok","database":{"ok":true,"connection":"pgsql",...}}}
```

Common commands:

```bash
docker compose logs -f app                     # tail application logs
docker compose exec app php artisan migrate    # run migrations
docker compose exec app vendor/bin/phpunit     # run test suite
docker compose exec app bash                   # open a shell in the app container
docker compose down                            # stop stack (preserves volumes)
docker compose down -v                         # stop and wipe database volume
```

See [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for more.
