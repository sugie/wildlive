# AI Development Session — Task 007: Restandardize on PostgreSQL 17

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the visible human/AI interaction during this session. No summary, no beautification. Code, commands, file paths, identifiers, and error messages are kept in their original form. No private chain-of-thought is included.

## Scope of this transcript

This file records what the human could see in the Claude Code chat plus the tool activity the AI actually performed. Anything that could not be honestly captured is marked `Not captured` or `Not available in the public session record`.

The human's prompt is preserved as a faithful English translation in [`prompt.en.md`](prompt.en.md).

---

## Turn — Human

The human sent a Japanese message announcing that the Sakura Cloud PostgreSQL Appliance is not viable for WildLive's network topology and that the production database will instead be an existing PostgreSQL Cluster 1 running PostgreSQL 17 with pgvector. The prompt required:

- reversal of the PostgreSQL-15 spec change that had shipped in PR #10 (Task 006);
- careful preservation of the parts of PR #10 that were **not** strictly the PG-15 spec change (i.e. the historical audit records in `docs/reports/`, `docs/social/x/`, and `docs/ai-sessions/`);
- adoption of PostgreSQL 17 with pgvector as the new baseline;
- live verification via `SELECT version()` and by creating the `vector` extension;
- no push, no PR, no merge, unless the human explicitly authorises them later;
- no touching the production database in any way;
- no deletion of any data volume without confirmation, except when the volume is obviously disposable test data.

Full received text is preserved in [`prompt.en.md`](prompt.en.md).

## Turn — AI

The AI acknowledged the specification and announced the plan:

- Handle the work as **Task 007** on branch **`ai/010-postgres-17-restandardization`** (the next milestone number after Task 006 and the next branch number after `ai/009`).
- Do NOT `git revert` PR #10 wholesale — it contained historical audit deliverables (the Task 006 bilingual report, X manifest, and AI session archive record) that must remain intact regardless of the technical reversal.
- Classify each file PR #10 touched into (a) current-spec files that must revert to PG17, (b) ADR to mark as superseded but preserve, (c) historical audit records to leave untouched, or (d) index files needing a new Task 007 row appended.
- Use `pgvector/pgvector:pg17` — the official pgvector image on PostgreSQL 17 — so the `CREATE EXTENSION vector` check the prompt requires can actually succeed in dev. Production is pgvector 0.8.5; the dev image ships whichever pgvector its upstream tag currently points at (the API is stable within the 0.8.x line).
- Give the human an explicit pre-wipe report about the `postgres-data` volume before running `docker compose down -v`, because the prompt asks for that.

Detailed step-by-step tool activity follows.

---

## Command

    git status
    git branch --show-current
    git pull --ff-only origin main
    git log --oneline --decorate -8

### Result

Clean `main` at commit `9927754` — the merge commit of PR #10 ("chore(db): standardize development and CI on PostgreSQL 15"). No local uncommitted changes.

## Command

    git show --stat e56fae6 3377822
    git diff --name-only 8d113ec..9927754

### Result

PR #10 introduced 14 changed files across:

- **CURRENT-SPEC (must revert to 17):** `docker-compose.yml`, `.github/workflows/ci.yml`, `CLAUDE.md`, `docs/DEVELOPMENT.md`.
- **ADR (mark superseded, keep body):** `docs/adr/0004-postgresql-15-standardization.md`.
- **HISTORICAL AUDIT (keep intact):** all files under `docs/ai-sessions/task-006-postgres-15-standardization/` (four files), `docs/reports/{ja,en}/task-006-postgres-15-standardization.html` (two files), and `docs/social/x/task-006-postgres-15-standardization.json` (one file).
- **INDEX (append Task 007 row):** `docs/reports/index.html`, `docs/ai-sessions/index.md`.

The AI decided not to modify any of the seven "historical audit" files. The Task 006 X post is already publicly posted at `https://x.com/i/status/2088205139912044809`; it cannot be un-posted, and the archive record of that decision is exactly the kind of thing WildLive's public archive is designed to preserve.

## Command

    git switch -c ai/010-postgres-17-restandardization

### Result

New branch created from clean `main`. Working tree still clean.

## Files edited — image pin

- `docker-compose.yml` — `image: postgres:15-alpine` → `image: pgvector/pgvector:pg17`, with an inline comment pointing at ADR-0005 (which supersedes ADR-0004).
- `.github/workflows/ci.yml` — same image change; job name updated to `PHPUnit (PHP 8.5 / PostgreSQL 17 + pgvector)` so the version and extension are visible in the Actions UI.

## Files edited — current-spec docs

- `CLAUDE.md` — Repository state / Architectural direction bullets updated from "PostgreSQL 15 (`postgres:15-alpine`)" to "PostgreSQL 17 (via `pgvector/pgvector:pg17`)", with an ADR-0005 pointer.
- `docs/DEVELOPMENT.md` — version-choices table row updated from "15-alpine" to "17 (`pgvector/pgvector:pg17`)"; rationale replaced with the correct production-parity statement.

## Files edited — ADR supersession

- `docs/adr/0004-postgresql-15-standardization.md` — **status line only** changed from `Status: Accepted` to `Status: Superseded by ADR-0005`, with a one-sentence explanation. Body preserved unchanged, as an accurate record of what was believed at the time.

## Files added — new ADR

- `docs/adr/0005-postgresql-17-restandardization.md` — accepted ADR that documents the reversal, cites the network-topology reason without leaking production hostnames / ports / PgBouncer configuration / credentials, and records the live verification result.

## Files added — Task 007 governance

- `docs/ai-sessions/task-007-postgres-17-restandardization/prompt.en.md`
- `docs/ai-sessions/task-007-postgres-17-restandardization/transcript.en.md` (this file)
- `docs/ai-sessions/task-007-postgres-17-restandardization/metadata.json`
- `docs/ai-sessions/task-007-postgres-17-restandardization/README.md`
- `docs/ai-sessions/index.md` — Task 007 row appended at the top.
- `docs/reports/en/task-007-postgres-17-restandardization.html`
- `docs/reports/ja/task-007-postgres-17-restandardization.html`
- `docs/reports/index.html` — Task 007 row appended at the top.
- `docs/social/x/task-007-postgres-17-restandardization.json` — schema v2 (English only), body: *"WildLive dev and CI now run PostgreSQL 17 with pgvector, matching the actual production cluster. Reverses the earlier PostgreSQL 15 plan."*

## Volume-wipe pre-notice

The AI explicitly reported to the human that:

- The local `wildlive_postgres-data` volume was initialised 30 minutes earlier by the Task 006 verification against `postgres:15-alpine`.
- It contains only Laravel's three framework migrations (users / cache / jobs — empty schema tables) and no WildLive-specific data.
- PostgreSQL 17 cannot open a PG15 data directory, so wiping the volume is required to bring up the new stack.
- The volume qualifies under the prompt's "test-only, obviously regenerable" carve-out.

The AI then proceeded with the wipe.

## Command

    docker compose down -v
    docker pull pgvector/pgvector:pg17
    docker compose up -d

### Result

Existing PG15-initialised `wildlive_postgres-data` volume removed. `pgvector/pgvector:pg17` pulled (Debian 12 base, aarch64). Both containers reached the `healthy` state.

## Command

    docker compose exec postgres psql -U wildlive -d wildlive -c 'SELECT version();'
    docker compose exec postgres psql -U wildlive -d wildlive -c 'SHOW server_version;'
    docker compose exec postgres psql -U wildlive -d wildlive -c 'CREATE EXTENSION IF NOT EXISTS vector;'
    docker compose exec postgres psql -U wildlive -d wildlive -c \
      "SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';"
    docker compose exec postgres psql -U wildlive -d wildlive -c \
      "SELECT '[1,2,3]'::vector AS demo, '[1,2,3]'::vector <-> '[1,2,4]'::vector AS l2_distance;"

### Result

```
PostgreSQL 17.11 (Debian 17.11-1.pgdg12+2) on aarch64-unknown-linux-gnu,
  compiled by gcc (Debian 12.2.0-14+deb12u1) 12.2.0, 64-bit

server_version = 17.11 (Debian 17.11-1.pgdg12+2)
server_version_num = 170011

CREATE EXTENSION → success
extname = 'vector', extversion = '0.8.6'

Quick vector-type smoke test:
  demo    = [1,2,3]
  l2_dist = 1
```

Live server is on the PostgreSQL 17 line, and pgvector is fully functional (extension installed, vector type recognised, L2 distance operator returns the expected value 1 for `[1,2,3]` vs `[1,2,4]`).

Production runs pgvector 0.8.5; the dev image shipped 0.8.6. Both are on the 0.8.x line and are API-compatible; no ADR pins pgvector to a specific patch because no application code currently depends on any pgvector-specific behaviour.

## Command

    curl -sf http://127.0.0.1:8000/api/health
    docker compose exec postgres psql -U wildlive -d wildlive
      -c "CREATE DATABASE wildlive_test OWNER wildlive;"
    docker compose exec app php artisan migrate --force
    docker compose exec app vendor/bin/phpunit

### Result

- Health endpoint: `{"status":"ok","checks":{"app":"ok","database":{"ok":true,"connection":"pgsql","error":null}}}`.
- Test database created.
- Three framework migrations applied under PostgreSQL 17.
- PHPUnit: `5 tests, 9 assertions, all pass` on PHP 8.5.9 + PostgreSQL 17.11 + pgvector 0.8.6.

## Command

    python3 -m unittest scripts.social.tests.test_post_x
    python3 -m unittest scripts.ai.tests.test_validate_session

### Result

- Publisher unit tests: `Ran 55 tests` `OK`.
- AI-session-archive validator tests: `Ran 35 tests` `OK`.

## Command

    docker compose down

### Result

Stack cleanly shut down. Working tree still clean at this point (before staging).

## Command (planned, not yet executed at write time)

    git add ...
    git commit -m "chore(db): restandardize development and CI on PostgreSQL 17 with pgvector"
    # NO git push, NO gh pr create, NO gh pr merge

### Result

Per the human's explicit constraint in this task, this session **does not** push, open a PR, or merge. It creates a local commit only, then stops and waits for the human's explicit authorisation to push. `pr_number` and `pr_url` in `metadata.json` for this task are left as `null` for the same reason.

---

## Report

The final human-facing AI report is a chat message written in Japanese at the end of this session. Because the archive language policy is English only, the equivalent English narrative is published as the bilingual development report:

- English: [`../../reports/en/task-007-postgres-17-restandardization.html`](../../reports/en/task-007-postgres-17-restandardization.html)
- Japanese: [`../../reports/ja/task-007-postgres-17-restandardization.html`](../../reports/ja/task-007-postgres-17-restandardization.html)

---

## Notes on what is deliberately not in this transcript

- Any private chain-of-thought.
- Production database credentials, PgBouncer configuration, host names, port numbers, or any operations-facing infrastructure detail — none were involved in this session, and none appear in ADR-0005 either.
- Real X posting activity — this transcript does not observe any post-merge workflow, because this session did not merge. The Task 007 X manifest is committed and reviewed, but not yet in the position to be picked up by any workflow run.
- Values of any secret, token, or credential.
