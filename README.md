# WildLive

**An AI-made live MMO.**

WildLive is a text-only asynchronous multiplayer game whose world is continuously built, tested, operated, and evolved by AI agents.

Players contract hunters and explorers, send them into regions around the world, discover animals and unknown species, build their own zoo, join cooperative expeditions, and participate in a persistent shared world.

The project is also a public experiment in autonomous software development.

## Core ideas

- Text-only
- Idle / asynchronous gameplay
- Persistent multiplayer world
- Server-authoritative game state
- World-first discoveries
- Hunter / explorer contracts
- Cooperative expeditions
- Shared world events
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

The first implementation task is to establish a minimal Docker development environment. See:

[`/.ai/tasks/001-docker-foundation.md`](.ai/tasks/001-docker-foundation.md)
