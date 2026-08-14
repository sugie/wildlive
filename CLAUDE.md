# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository state

Pre-alpha. The repository currently contains **only documentation and planning** — no application code, no `composer.json`, no Docker files, no tests. There is nothing to build, lint, or run yet.

The first implementation task (`.ai/tasks/001-docker-foundation.md`) is to bootstrap a Laravel 13 / PHP 8.5 / PostgreSQL environment via Docker Compose. Do not implement game features (hunters, expeditions, zoo, multiplayer) in that task — those are separate follow-ups.

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

- **Backend:** Laravel 13, PHP 8.5, REST/JSON API
- **DB:** PostgreSQL (Sakura Cloud PostgreSQL appliance in production)
- **Local dev:** Docker Compose
- **Deploy target:** Sakura Cloud AppRun via GitHub Actions

Long-running expeditions are modeled as timestamps (`started_at` / `ends_at` / `resolved_at`), not as continuously running workers. An expired-but-unresolved expedition is resolved lazily — on player request, scheduled scan, or when another process needs the result.

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
