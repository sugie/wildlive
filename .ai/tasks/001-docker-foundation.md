# Task 001 — Docker Foundation

## Objective

Create the minimal reproducible development environment for WildLive.

Do **not** implement game features in this task.

## Target stack

- Laravel 13
- PHP 8.5
- PostgreSQL
- Docker Compose
- PHPUnit

## Requirements

The repository must be startable from a clean clone using documented commands.

Provide:

- Laravel application
- PHP runtime container
- PostgreSQL container
- Docker Compose configuration
- `.env.example`
- database connection configuration
- application health endpoint
- database health verification
- automated tests
- concise startup instructions

## Constraints

Do not add unless a demonstrated requirement exists:

- Redis
- queue infrastructure
- WebSockets
- Elasticsearch
- Kafka
- additional databases
- frontend frameworks

Do not implement:

- hunters
- animals
- expeditions
- zoo logic
- multiplayer logic
- X posting
- cloud deployment

Those are separate tasks.

## Quality requirements

- no secrets committed
- `docker compose up` behavior documented
- migrations can run in the container environment
- PHPUnit can run in the container environment
- health behavior is tested
- failure of PostgreSQL should be detectable
- all generated code follows the repository guardrails

## Git workflow

Create a branch:

```text
ai/001-docker-foundation
```

Do not commit directly to `main`.

At completion:

1. Run all relevant tests.
2. Review the diff.
3. Commit.
4. Push the branch.
5. Open a Pull Request against `main`.
6. Do not merge it automatically.
7. Complete the PR metadata.
