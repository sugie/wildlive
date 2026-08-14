# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added requirements, no removed requirements. Code, commands, file paths, URLs, identifiers, and error messages are kept in their original form. Structure (headings, numbering, constraints) is preserved.

---

# Please standardise the WildLive development environment on PostgreSQL 15

Please update the WildLive repository so that the local development environment uses **PostgreSQL 15**.

## Background and confirmed decision

The production environment will use the Sakura Cloud PostgreSQL Appliance.

The major version of PostgreSQL adopted by the Sakura Cloud PostgreSQL Appliance is **15**, so we align the development environment on PostgreSQL 15 as well.

This is not open for discussion — it is a confirmed architecture decision.

* Production DB: Sakura Cloud PostgreSQL Appliance
* Production PostgreSQL: 15
* Development DB: Docker
* Development PostgreSQL: 15
* CI, wherever it uses PostgreSQL, also PostgreSQL 15 in principle
* Do not use `postgres:latest`.
* Do not upgrade to PostgreSQL 16, 17, 18, and so on.

Configuration changes to the production API server are a separate task.

For this task, focus on the **PostgreSQL version alignment inside the WildLive repository, and the minimum changes required for it**.

# 1. Start by auditing the current state

Before making any changes, audit the whole repository.

At minimum, confirm the following.

* Dockerfile
* docker-compose.yml
* docker-compose.yaml
* compose.yml
* compose.yaml
* .env
* .env.example
* GitHub Actions
* CI configuration
* DB initialisation scripts
* migrations
* raw SQL
* test configuration
* README
* docs
* ADR
* CLAUDE.md
* AGENTS.md
* AUTONOMY.md
* other AI-agent instruction files

Search the entire repository for the following strings and related references.

* postgres
* postgresql
* pgvector
* POSTGRES_VERSION
* postgres:15
* postgres:16
* postgres:17
* postgres:18
* postgres:latest

Do not decide from the start that "changing one line in Docker Compose is enough".

First, understand where in the repository which version is currently specified.

# 2. Change the Docker development environment to PostgreSQL 15

If the environment currently uses PostgreSQL 16, 17, 18, `latest`, etc., change it to PostgreSQL 15.

The PostgreSQL Docker image must specify an explicit version to guarantee reproducibility.

`postgres:latest` is forbidden.

If the existing project convention pins to a specific minor version, follow that convention.

Otherwise, arrange the configuration so that it is clearly on the PostgreSQL 15 line.

# 3. Check pgvector

If WildLive uses pgvector, make sure it continues to work under PostgreSQL 15.

Confirm the following.

* Whether pgvector is currently used
* Which Docker image or package provides it
* Whether it is compatible with PostgreSQL 15
* Whether the migrations or the initialisation process create a vector extension

If necessary, switch to a PostgreSQL-15-compatible pgvector image or package.

If pgvector is required by an existing feature, do not delete it merely for simplification.

Also confirm that the following runs successfully.

```
CREATE EXTENSION IF NOT EXISTS vector;
```

# 4. Audit PostgreSQL 15 compatibility

Inspect the migrations, schema, raw SQL, initialisation SQL, and application code, and check whether any feature that is only available on a PostgreSQL version newer than 15 is used.

In particular, check the following.

* SQL syntax added in PostgreSQL 16 or later
* Functions added in PostgreSQL 16 or later
* JSON / JSONB related
* generated columns
* indexes
* vector indexes
* extensions
* authentication configuration
* DB initialisation process

If there are no compatibility issues, do not modify the application code unnecessarily.

If a compatibility issue is found, make the minimum change that preserves the same meaning under PostgreSQL 15.

# 5. Align CI on PostgreSQL 15 as well

If GitHub Actions or similar starts PostgreSQL, check that version too.

Standardise the normal CI test environment on PostgreSQL 15 as well.

For example, do not accidentally leave a state such as

* local dev = PostgreSQL 15
* CI = PostgreSQL 17

If a matrix test is intentionally exercising multiple versions for compatibility, confirm that intent before touching it.

WildLive's standard DB version is PostgreSQL 15.

# 6. Beware of existing data volumes

You cannot generally use an existing Docker volume for one PostgreSQL major version with a different PostgreSQL major version.

Check the state of the current development DB volume.

If it is clearly disposable development data, rebuild the DB using the project's usual method.

However, if the nature of the data is not clear, do not delete it on your own.

Never delete data that is, or might be, production data.

# 7. Actually start PostgreSQL 15 and verify

Rewriting configuration files is not enough to consider this task done.

Actually start the Docker environment and connect to PostgreSQL.

Then confirm the actual server version.

For example, run the following.

```
SELECT version();
```

and

```
SHOW server_version;
```

Confirm that the result is **PostgreSQL 15.x**.

Do not decide that "it is now on PostgreSQL 15" merely from the Docker image name.

# 8. Verify migrations and pgvector

Confirm that the existing migrations run successfully under the PostgreSQL 15 environment.

If pgvector is used, also confirm that the extension can be created.

If necessary, also check:

```
SELECT extname, extversion
FROM pg_extension
WHERE extname = 'vector';
```

If any table or migration uses the `vector` type, confirm that it can be created.

# 9. Run the tests

Run the usual verification defined for this repository.

Where applicable, perform the following.

* Docker Compose configuration validation
* Docker build
* Docker startup
* DB health check
* migrations
* PostgreSQL connectivity test
* pgvector test
* unit test
* integration test
* API test
* lint
* static analysis
* any other verification that the repository requires as CI-equivalent

Do not weaken the tests themselves to make them pass.

If there is an existing failure that is unrelated to this change, report that fact clearly.

# 10. Update documentation

Record in the appropriate documentation that WildLive's standard PostgreSQL version is 15.

The intent is:

"WildLive uses PostgreSQL 15 as its standard DB version in order to ensure compatibility with the Sakura Cloud PostgreSQL Appliance used as its production environment. The local development environment and the normal CI environment also use PostgreSQL 15."

Record it in the location that best fits the current repository structure — README, development documentation, ADR, etc.

The same explanation does not need to be duplicated across many files.

If an ADR practice already exists, prefer recording this decision as an ADR.

# 11. Respect the AI development history rule

WildLive's policy is to publish how the AI was instructed to build it, so that the repository can be used as a reference for AI development.

Therefore, before starting work, always confirm the following files or their equivalents.

* AGENTS.md
* CLAUDE.md
* AUTONOMY.md
* .ai/
* docs/ai-sessions/
* AI session-saving rule
* prompt-saving rule
* transcript-saving rule
* report-saving rule
* branch / commit / PR / merge rule

If existing rules exist, always follow them.

If the instructions given to Claude Code this time are themselves within the scope of the existing AI-session-saving rule, save them.

Do not invent new governance rules by guessing.

# 12. Do not make unnecessary changes

The goal of this task is standardisation on PostgreSQL 15.

The following are forbidden.

* Upgrade to PostgreSQL 16 or later
* Use of `postgres:latest`
* Change to a different DB such as MySQL
* Unauthorised deletion of pgvector
* Large-scale refactoring
* Feature additions unrelated to the PostgreSQL change
* Unnecessary changes to business logic
* Weakening tests
* Committing secrets
* Deleting production data
* Unmotivated updates of dependency packages

Keep the change footprint as small as possible.

# Completion conditions

Consider this task complete only when the following hold.

* [ ] The WildLive Docker development environment runs on PostgreSQL 15
* [ ] The PostgreSQL version is pinned explicitly
* [ ] `postgres:latest` is not used in the standard environment
* [ ] No unintended PostgreSQL 16 / 17 / 18 pin remains
* [ ] The CI's standard DB is also on PostgreSQL 15
* [ ] The PostgreSQL 15 container starts normally
* [ ] `SELECT version()` was checked and returned PostgreSQL 15.x
* [ ] Migrations succeed
* [ ] If pgvector is used, it works correctly on PostgreSQL 15
* [ ] The existing tests pass, or unrelated pre-existing failures are clearly reported
* [ ] The rationale for standardising on PostgreSQL 15 is documented
* [ ] If AI development history rules exist, they are followed
* [ ] No secret is committed
* [ ] No large-scale change unrelated to PostgreSQL is included

# Final report

When work is finished, report the following.

## 1. State before the change

* PostgreSQL version used before the change
* Files where the PostgreSQL version was defined
* Status of pgvector use

## 2. Changes made

* List of changed files
* Reason for each file change
* PostgreSQL Docker image adopted
* pgvector handling

## 3. PostgreSQL 15 compatibility

* Whether any PostgreSQL-16-or-later-only feature was present
* Whether a compatibility fix was required
* If so, what was changed

## 4. Verification results in the real environment

* Result of `SELECT version()`
* Result of `SHOW server_version`
* Migration result
* pgvector verification result
* Health check result

## 5. Test results

Summarise, briefly, the commands you ran and the results.

Make PASS / FAIL explicit.

If there is a FAIL, distinguish whether this change caused it or whether it was a pre-existing problem.

## 6. Git / AI development history

If you worked according to the repository's existing rules, also report the following.

* branch name
* commit hash
* commit message
* PR number
* PR URL
* CI result
* Location where the AI prompt / transcript / report was saved
* Merge result, if merged

Important:

**Rewriting configuration files alone does not count as completion. Actually start PostgreSQL 15, verify with `SELECT version()` etc. that it is on 15.x, and only then treat this task as complete.**
