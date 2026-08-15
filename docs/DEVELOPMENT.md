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

## Migrations and game master data

```bash
docker compose exec app php artisan migrate
docker compose exec app php artisan migrate:fresh
docker compose exec app php artisan migrate:rollback
```

The game needs its master data to function at all — with no maps, hunters
or animals there is nothing to play — so seed after migrating:

```bash
docker compose exec app php artisan db:seed --force
# → Game Master v0.3 seeded: 6 biomes, 5 rarities, 54 animals,
#   18 hunters, 15 maps, 72 spawn rows.
```

The seeder upserts by Game Master id, so re-running it after a master-data
change updates rows in place and leaves players' expeditions and zoo
animals intact. See
[`docs/game-design/RUNTIME_MASTER_DATA.md`](game-design/RUNTIME_MASTER_DATA.md)
for how a value gets from the design workbook to the screen.

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

`phpunit.xml` points the suite at `wildlive_test` using **both** `<server>`
and `<env>` entries with `force="true"`. That is not redundancy: PHP's CLI
copies the container's environment into `$_SERVER`, and Laravel's `env()`
reads `$_SERVER` first — so an `<env>`-only override loses, the suite runs
against the development database, and `RefreshDatabase` wipes it. If you
ever see your seeded game master data disappear after running tests, that
is what happened.

## First-time player registration (end-to-end)

Milestone 002 (Task 010) added the first real vertical slice: the iOS
Simulator hits the local Laravel API which writes a row to the local
PostgreSQL. To reproduce the flow from a fresh checkout:

```bash
# 1. Start the local stack and run migrations.
docker compose up -d
docker compose exec app php artisan migrate

# 2. Confirm the API is healthy and the table exists.
curl -s http://localhost:8000/api/health
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "\dt players; \dt zoos;"

# 3. Smoke-test the endpoint from your Mac (bypassing the app).
curl -sSi -X POST http://localhost:8000/api/players \
  -H 'Content-Type: application/json' \
  -d '{"display_name":"CurlTest"}'
# → HTTP/1.1 201 Created + {"player": {...}, "zoo": {...}}

# 4. Confirm the row landed.
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "SELECT id, display_name, created_at FROM players ORDER BY created_at DESC LIMIT 5;"

# 5. Run the Laravel Feature suite (12 tests / 46 assertions).
docker compose exec app vendor/bin/phpunit --testdox

# 6. Reset before driving the app so the DB starts clean.
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "TRUNCATE zoos, players CASCADE;"

# 7. Build + install the iOS app (see apps/ios/README.md for the full
#    xcodebuild command). Then launch on a fresh install:
xcrun simctl boot 'iPhone 17' ; open -a Simulator
xcrun simctl uninstall booted dev.wildlive.WildLive   # wipe UserDefaults
xcrun simctl install booted \
  apps/ios/build/Build/Products/Debug-iphonesimulator/WildLive.app
xcrun simctl launch booted dev.wildlive.WildLive

# 8. In the Simulator: tap Start → type a display name → tap Register.
#    The app shows the Home dashboard.

# 9. Confirm the row the Simulator just created.
docker compose exec postgres psql -U wildlive -d wildlive \
  -c "SELECT id, display_name, created_at FROM players ORDER BY created_at DESC LIMIT 1;"
```

To automate step 8+9 with the shipped UI test:

```bash
cd apps/ios
xcodebuild -project WildLive.xcodeproj -scheme WildLive \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath build \
  -only-testing:'WildLiveUITests/WildLiveUITests/test_realAPI_endToEndRegistration' \
  test
# Skips unless WILDLIVE_E2E=1 is set, so it never fails a fresh checkout
# with no backend — and fails, rather than skips, once it is.
```

## Playing the expedition loop (end-to-end)

The full vertical slice: iPhone Simulator → SwiftUI → Laravel → PostgreSQL
→ persisted animal → back on screen.

```bash
# 1. Stack up, schema and master data in place.
docker compose up -d
docker compose exec app php artisan migrate --force
docker compose exec app php artisan db:seed --force
curl -s http://localhost:8000/api/health

# 2. Drive the whole loop automatically (registration → Kenyan Savanna →
#    Amara Koné → dispatch → resolve → keep → name → My Zoo).
cd apps/ios
TEST_RUNNER_WILDLIVE_E2E=1 xcodebuild \
  -project WildLive.xcodeproj -scheme WildLive \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath build \
  -only-testing:'WildLiveUITests/ExpeditionFlowUITests/test_realEndToEnd_registerDispatchResolveKeepAndSeeItInMyZoo' \
  test

# 3. Confirm what the Simulator actually persisted.
docker compose exec postgres psql -U wildlive -d wildlive -c "
  SELECT p.display_name, p.g_balance, za.name, a.name_en AS species, r.name_en AS rarity
  FROM zoo_animals za
  JOIN zoos z ON z.id = za.zoo_id
  JOIN players p ON p.id = z.player_id
  JOIN animals a ON a.id = za.animal_id
  JOIN rarities r ON r.id = a.rarity_id
  ORDER BY za.created_at DESC LIMIT 5;"
```

`TEST_RUNNER_` is not a typo: `xcodebuild` only forwards environment
variables with that prefix into the test runner process, stripping it on
the way.

Add `-parallel-testing-enabled NO` when running more than one end-to-end
test at a time. `php artisan serve` is single-threaded, and three
simultaneous Simulator clones queue behind each other until the app's
requests time out.

To play it by hand instead, see
[`apps/ios/README.md`](../apps/ios/README.md#play-the-expedition-loop-by-hand).

### Expeditions take real time

Canonical `Map.expedition_minutes` runs from 10 minutes (Kenyan Savanna) to
6 hours (Congo Rainforest), which is unplayable by hand and untestable. The
development shortcut makes an expedition immediately resolvable, and needs
all three of:

1. `APP_ENV` in `local` or `testing` — production refuses regardless;
2. `WILDLIVE_DEV_INSTANT_EXPEDITIONS=true` (the default in
   `config/wildlive.php`);
3. the client sending `dev_instant_resolve: true` on that one request —
   in the app, the DEBUG-only "Resolve instantly" toggle on the dispatch
   screen.

An expedition created this way is permanently flagged `dev_instant_resolve`
in PostgreSQL and in every API response, and shows an orange "Development
run — the wait was skipped" banner in the app. The canonical
`expedition_minutes` is never modified; the real duration is recorded in
`planned_duration_minutes`.

```bash
# Verify the guard: a shortened expedition is always marked as such.
docker compose exec postgres psql -U wildlive -d wildlive -c \
  "SELECT id, dev_instant_resolve, planned_duration_minutes, ends_at - started_at AS actual_wait
   FROM expeditions ORDER BY created_at DESC LIMIT 3;"
```

## Networking notes

`http://localhost` from the Simulator works because the iOS app's
`Info.plist` sets `NSAppTransportSecurity.NSAllowsLocalNetworking = true`.
The API base URL is read from the Info.plist key `WildLiveAPIBaseURL`
(default `http://localhost:8000/api`), so a tester can point the app at
a different host without a rebuild.

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
| PostgreSQL    | 17 (`pgvector/pgvector:pg17`) | Matches WildLive's production PostgreSQL cluster (PostgreSQL 17 with pgvector). Standardisation is fixed by [`docs/adr/0005-postgresql-17-restandardization.md`](adr/0005-postgresql-17-restandardization.md), which supersedes [`ADR-0004`](adr/0004-postgresql-15-standardization.md); bumping the major version requires a new ADR. |
| Composer      | 2.x                | Standard modern Composer, pulled from `composer:2` image at build time.           |

Bumping any of these is a governance change — open a PR with a short
justification and update `docker/php/Dockerfile`, `docker-compose.yml`,
`composer.json`, and `.github/workflows/ci.yml` together.
