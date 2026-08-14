# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added requirements, no removed requirements. Code, commands, file paths, URLs, identifiers, and error messages are kept in their original form. Structure (headings, numbering, constraints) is preserved.
- **Redaction note.** The original prompt listed the production PostgreSQL cluster's internal hostnames and the production API server's internal hostname. Those identifiers appear as `[REDACTED — internal hostname]` in this published translation. The same original prompt instructed the AI *not* to record production secret information in the repository; the archive treats internal infrastructure hostnames as covered by that instruction. Version numbers (PostgreSQL 17.10, pgvector 0.8.5, PgBouncer 1.25.2, PgBouncer port 6432, OS: Ubuntu 22.04 family) are preserved because they are the reason the version standardisation decision was made and are needed to understand the task.

---

# Review of the WildLive PostgreSQL 15 change, and standardisation on PostgreSQL 17

Please review the change that was just made — "align the development environment on PostgreSQL 15" — for the WildLive repository.

## Background and change of direction

The initial plan was to use the "Sakura Cloud PostgreSQL Appliance" as the production database, and to align the Mac development environment on that appliance's PostgreSQL version — PostgreSQL 15.

However, after subsequently checking the infrastructure configuration, we have decided that this PostgreSQL Appliance will **not** be used in WildLive's current configuration.

The reason is that, given the planned network configuration, the API server cannot connect appropriately to the PostgreSQL Appliance.

Therefore, WildLive's production PostgreSQL will use an existing PostgreSQL Cluster 1.

The current production-candidate environment is as follows.

* Master: [REDACTED — internal hostname]
* Slave: [REDACTED — internal hostname]
* PostgreSQL: 17.10
* pgvector: 0.8.5
* PgBouncer: 1.25.2
* PgBouncer port: 6432
* OS: Ubuntu 22.04 family

Therefore, the reason for changing WildLive's development environment to PostgreSQL 15 no longer exists.

## Final decision for this task

Make WildLive's baseline PostgreSQL version **PostgreSQL 17**.

Standardise the PostgreSQL major version on PostgreSQL 17 as much as possible across development environments, production, CI, documentation, and so on.

Cancel the PostgreSQL 15 accommodation.

## Most important point

Do not immediately start changing files.

First, investigate the current Git state and the most recent changes, and identify

"the changes that were made in order to switch to PostgreSQL 15".

The existing changes may contain important work that is unrelated to the PostgreSQL version change.

For that reason, wholesale removal of the recent work via `git reset` or `checkout` is forbidden.

Selectively review only the changes that are directly related to the PostgreSQL-15 switch.

## Investigation targets

Confirm at least the following.

* git status
* git diff
* recent git log
* Dockerfile
* compose.yaml
* docker-compose.yml
* docker-compose.*.yml
* .env
* .env.example
* CI workflow
* GitHub Actions
* PostgreSQL client package
* PHP PostgreSQL extension
* pgvector
* Laravel database configuration
* README
* docs
* scripts
* Makefile
* test configuration
* development setup documentation

Further, search the whole repository and confirm entries such as the following.

* postgres:15
* postgres:15.x
* PostgreSQL 15
* PostgreSQL15
* PG15
* version 15
* other places where PostgreSQL 15 is pinned

As far as possible, use the Git history to judge whether each was added when switching to PostgreSQL 15, or existed earlier.

## Work to perform

After the investigation, fix the places that were changed in order to switch to PostgreSQL 15, changing them to PostgreSQL 17.

In particular, check the Docker development environment.

If the Docker PostgreSQL image has been changed to PostgreSQL 15, change it to PostgreSQL 17.

In principle, use major version 17.

However, if the existing project has an explicit patch-version-pinning operational rule, respect that rule.

Production is PostgreSQL 17.10, but there is no need to forcibly pin the Docker image to 17.10.

Decide based on the existing dependency-pinning policy.

## pgvector

pgvector 0.8.5 is available on the production PostgreSQL cluster master.

Because WildLive is designed to use pgvector, confirm that the vector extension can be used normally in the PostgreSQL 17 environment as well.

If processes like the following exist, confirm that they work correctly under PostgreSQL 17 as well.

CREATE EXTENSION vector

vector type inside migrations

vector indexes

embedding-storage processing

vector similarity search

## Laravel

On the Laravel side, there is no need to introduce implementation specific to PostgreSQL 15.

Treat PostgreSQL 17 as a normal PostgreSQL connection target.

Confirm the following.

* DB_CONNECTION=pgsql
* DB_HOST
* DB_PORT
* DB_DATABASE
* DB_USERNAME
* DB_PASSWORD
* PDO PostgreSQL
* Laravel migration
* transactions
* JSON / JSONB
* UUID
* timestamp
* index
* foreign key
* vector extension

If application code was changed solely for the purpose of aligning with PostgreSQL 15, re-evaluate whether that change was really necessary.

## Regarding production connection

In this task, do not directly connect to, or make changes to, the production PostgreSQL cluster master.

Use the production-environment information only as a criterion for selecting the PostgreSQL version.

The following are forbidden against the production DB.

* running migrations
* CREATE / ALTER / DROP
* data change
* user creation
* database creation
* PostgreSQL configuration change
* PgBouncer configuration change

The target of this task is the Mac development environment and the repository fixes.

## About data

Do not carelessly delete existing local PostgreSQL data.

If a Docker-volume compatibility issue occurs due to the PostgreSQL major-version 15 → 17 change, first report the situation.

Do not execute operations that could destroy data — such as

docker compose down -v

docker volume rm

rm -rf

— without confirmation.

Except in cases where the data is clearly disposable test-only data.

## Verification

After the fix, verify the following to the extent possible.

1. Docker configuration validation
2. Docker image build
3. PostgreSQL 17 container startup
4. PostgreSQL version
5. Laravel → PostgreSQL connection
6. migrations
7. pgvector extension
8. application test suite
9. PostgreSQL-related tests
10. health check
11. Match of PostgreSQL major version between CI and local environment

If it can be obtained from inside the PostgreSQL container, confirm that PostgreSQL 17 is in use with

SELECT version();

SHOW server_version;

or similar.

If pgvector can also be verified, confirm with, for example,

SELECT extversion
FROM pg_extension
WHERE extname = 'vector';

## Consistency of PostgreSQL version

Finally, search inside the repository to check whether

PostgreSQL 15

and

PostgreSQL 17

are unintentionally mixed together.

However, do not mechanically rewrite text in ADRs or historical documents that records the historical fact

"PostgreSQL 15 was considered earlier".

Judge whether each mention is the current specification or a historical record.

For the current specification, PostgreSQL 17 is authoritative.

## Documentation

If PostgreSQL 15 is written as a current requirement in the README or development-environment setup procedure, update it to PostgreSQL 17.

The infrastructure direction for this task is as follows.

API:

Plan to use the existing [REDACTED — internal hostname] server on IaaS.

Database:

PostgreSQL Cluster 1

* [REDACTED — internal hostname]
* [REDACTED — internal hostname]

PostgreSQL 17

Do not record the production environment's detailed credentials or secret information in the repository.

## Forbidden

In this task, do not perform refactoring unrelated to the PostgreSQL version change.

The following are forbidden.

* unrelated application code rewrites
* unrelated dependency upgrades
* framework upgrades
* large-scale changes by formatters
* unnecessary file moves
* unrelated Docker configuration changes
* changes to the production DB
* committing secrets
* destructive database operations
* rolling back work unrelated to the PostgreSQL 15 change

Keep the diff minimal.

## Git

First, check the current branch, status, and diff.

If the PostgreSQL-15 change is not yet committed, analyse the contents and fix only the PostgreSQL-15-related portion.

Even if it is already committed, do not casually revert the entire commit — check whether the commit also contains changes unrelated to PostgreSQL.

For this task, do not perform

* git push
* PR creation
* merge

unless we explicitly instruct you to.

If necessary, perform up to just before a local commit.

## Final report

At the end of the work, report the following.

### 1. Investigation results

What had been changed by the PostgreSQL-15 switch.

### 2. Fix contents

Which files were changed to PostgreSQL 17.

### 3. PostgreSQL version

Which PostgreSQL version is finally used in the development environment.

### 4. pgvector

Whether pgvector is available.

### 5. Test results

Commands executed and PASS / FAIL.

### 6. Git diff

Overview of the changes in this task.

### 7. Remaining tasks

Only if there are unresolved items.

### 8. Residual PostgreSQL 15 check

Whether any place still refers to PostgreSQL 15 as the current specification.

---

The purpose of this task is not merely a numerical replacement of "15 → 17".

The purpose is to cancel the immediately preceding direction change — "align on PostgreSQL 15 in order to use the PostgreSQL Appliance" — and to align the development environment with WildLive's actual production PostgreSQL environment, PostgreSQL 17.

Without breaking existing normal changes, carefully review only the diffs related to the PostgreSQL-15 switch.
