# Task 007 — Restandardize development and CI on PostgreSQL 17

Reverses the immediately-preceding Task 006 decision. WildLive's production PostgreSQL is the existing PostgreSQL Cluster 1 running PostgreSQL 17 with pgvector — **not** the Sakura Cloud PostgreSQL Appliance that Task 006 assumed. Development and CI are restandardised on PostgreSQL 17 to match.

## Navigate

- [View Prompt](prompt.en.md) — faithful English translation of the Japanese prompt the AI actually received.
- [View AI Conversation](transcript.en.md) — visible human/AI interaction and tool activity for this session.
- [View Pull Request](https://github.com/sugie/wildlive/pull/11) — PR #11.
- [View Development Report (EN)](../../reports/en/task-007-postgres-17-restandardization.html)
- [View Development Report (JA)](../../reports/ja/task-007-postgres-17-restandardization.html)
- [View ADR-0005](../../adr/0005-postgresql-17-restandardization.md)
- [View superseded ADR-0004](../../adr/0004-postgresql-15-standardization.md)

## Pull Request

**PR:** [#11 — chore(db): restandardize development and CI on PostgreSQL 17 with pgvector](https://github.com/sugie/wildlive/pull/11). The human's Task 007 prompt initially withheld push, PR-creation, and merge authorisation; a subsequent instruction authorised the push, PR, and merge, at which point the branch was published and `pr_number` / `pr_url` in [`metadata.json`](metadata.json) were backfilled by a small follow-up commit on this branch.

## Metadata

Machine-readable metadata for this session is at
[`metadata.json`](metadata.json) and validates against
[`../schema.json`](../schema.json).

## Language and truthfulness

- Original interaction: primarily Japanese.
- Archive record: English only, faithful translation. No summary, beautification, or added requirements. Code, commands, paths, URLs, identifiers, and error messages are kept in their original form.
- Nothing that could not be honestly captured has been fabricated. Where the transcript was unavailable it is marked `Not captured` or `Not available in the public session record`.
- No private chain-of-thought or hidden reasoning is included.

## Security

No secret, credential, token, cookie, or `.env` value appears in
this record. Production PostgreSQL cluster host names, ports,
PgBouncer configuration, credentials, and OS details are
deliberately absent from ADR-0005 and from this archive record —
they live in operations documentation outside this repository. See
[`../README.md#security`](../README.md#security) for the policy the
archive enforces.
