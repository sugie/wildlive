# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository state

Pre-alpha. Task 001 (Docker foundation) is complete: Laravel 13 / PHP 8.5 / PostgreSQL 15 running under Docker Compose, with a `/api/health` endpoint, PHPUnit against PostgreSQL, and a GitHub Actions CI workflow. No game features are implemented yet — hunters, zoos, expeditions, discoveries, and multiplayer are all separate follow-up tasks.

## Common commands

```bash
docker compose up -d                                # start stack
docker compose exec app php artisan migrate          # run migrations
docker compose exec app vendor/bin/phpunit           # run test suite
docker compose exec app php artisan tinker           # REPL
docker compose logs -f app                           # tail logs
```

See [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for the full command list and one-time test-database setup.

## Non-negotiable rules

These are enforced by `AGENTS.md` and `docs/GUARDRAILS.md`. Read those before making changes.

- **Never commit directly to `main`.** `main` must remain deployable. Use short-lived branches:
  - `ai/<issue-number>-<description>` for AI-authored work
  - `human/<issue-number>-<description>` for human-authored work
  - `hotfix/<issue-number>-<description>` for hotfixes
- **Do not add infrastructure not currently needed** (Redis, queues, WebSockets, Kafka, extra databases, frontend frameworks). Justify each new dependency.
- **Server-authoritative game state.** Clients never determine rewards, currency, ownership, rarity, World First status, timers, or contract completion.
- **Idempotent resolution.** Expedition/discovery resolution must be safe to invoke more than once — enforce with DB constraints, transactions, state transitions, or idempotency keys.
- **Transactions guard scarcity semantics**: World First, ownership transfer, contract acceptance, reward creation, expedition finalization.
- **Prefer additive, reversible migrations.** Destructive schema changes require explicit review.
- **Do not fabricate** test results, benchmarks, deployment status, or claim features exist that are not present.
- Security-sensitive changes and anything touching credentials, auth, billing, or production data require human approval — do not auto-merge.

## Architectural direction

- **Backend:** Laravel 13 (currently 13.25), PHP 8.5, REST/JSON API
- **DB:** PostgreSQL 15 (`postgres:15-alpine`) locally and in CI; Sakura Cloud PostgreSQL Appliance (PostgreSQL 15) in production. Standardisation fixed by [`docs/adr/0004-postgresql-15-standardization.md`](docs/adr/0004-postgresql-15-standardization.md). Bumping the major version requires a new ADR.
- **Local dev:** Docker Compose (`app` + `postgres` services only)
- **Deploy target:** Sakura Cloud AppRun via GitHub Actions

Long-running expeditions are modeled as timestamps (`started_at` / `ends_at` / `resolved_at`), not as continuously running workers. An expired-but-unresolved expedition is resolved lazily — on player request, scheduled scan, or when another process needs the result.

### Tests must use PostgreSQL

`phpunit.xml` points tests at a `wildlive_test` database on the same PostgreSQL engine — not SQLite. This is intentional: WildLive's concurrency and constraint semantics (World First, ownership transfer, expedition finalization) must be verified against the real engine.

## Documentation hierarchy

If docs conflict, **stop and flag it** — do not guess.

- **Product intent:** `docs/VISION.md`, `docs/GAME_DESIGN.md`
- **Technical intent:** `docs/ARCHITECTURE.md`, `docs/adr/`
- **Autonomous-development constraints:** `docs/AUTONOMY.md`, `docs/GUARDRAILS.md`
- **Domain (design workspace, not spec):** `docs/DOMAIN_MODEL.md`
- **Open questions to resolve before implementing:** `docs/DECISIONS_PENDING.md`

`docs/DOMAIN_MODEL.md` and `docs/API.md` are working notes, not specifications. Do not treat candidate entity/endpoint lists as permission to build them all — implement only what the current task needs.

## Pull Request expectations

Every PR uses `.github/pull_request_template.md` and must fill in the autonomous-development metadata block: **AI Agent**, **Reviewer**, **Human intervention**, **Tests**, **Risk level**, plus risk notes and rollback plan.

## Public development log

Task-scale or milestone-scale work must ship with a bilingual HTML report in `docs/reports/` (`ja/task-<NNN>-<slug>.html` + `en/task-<NNN>-<slug>.html`) and a new entry in `docs/reports/index.html`. Trivial typo or one-line fixes are exempt. All commit SHAs, PR numbers, CI run IDs, and test counts cited in a report must be **verified** against `git log`, `gh`, and actual command output — never estimated. See `docs/reports/README.md`.

## X development live (public posting)

Task/milestone PRs that warrant a public announcement also ship a bilingual X manifest at `docs/social/x/task-<NNN>-<slug>.json`. Write the post text at PR-authoring time so reviewers can read it in the PR. The workflow at `.github/workflows/x-development-live.yml` publishes it only after merge + `main` CI success. Live posting is fail-closed until a human sets the repository variable `X_AUTOPOST_ENABLED = true`. Never call an LLM from the workflow, never create the X app or credentials, never flip the kill switch. See `docs/adr/0003-x-development-live.md` and `docs/social/x/README.md`.

## Public AI development archive

Milestone-scale tasks also add a session record under `docs/ai-sessions/task-<NNN>-<slug>/` (English-only). Contents: `prompt.en.md` (faithful English translation of the human prompt, no summary / no added requirements), `transcript.en.md` (visible human/AI interaction and verified tool activity — no private reasoning, no fabrication), `metadata.json` (see `docs/ai-sessions/schema.json`), and a per-task `README.md`. Also append to `docs/ai-sessions/index.md`. Run `python3 scripts/ai/validate_session.py <task_dir>` before pushing. Never include a secret / credential / token / cookie / `.env` value / GitHub Secret value; use `[REDACTED]` if the source text mentioned one. Never invent interaction — use `Not captured` when necessary. See `docs/ai-sessions/README.md`.
