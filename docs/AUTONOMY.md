# Autonomous Development

## Objective

WildLive should be developed with minimal ongoing human intervention while preserving correctness, security, and traceability.

Autonomy is earned incrementally.

## Suggested maturity levels

### Level 1 — AI proposes

AI creates:

- issues
- specifications
- implementation plans

Human approves execution.

### Level 2 — AI implements

AI:

- creates branches
- writes code
- writes tests
- opens PRs

Human reviews.

### Level 3 — AI reviews AI

One agent implements.

A separate agent reviews.

CI must pass.

Human reviews only selected changes.

### Level 4 — Low-risk auto-merge

Eligible low-risk changes may merge automatically when:

- tests pass
- independent review passes
- policy checks pass
- no protected file or security rule is triggered

### Level 5 — Automated deployment

Eligible merged changes deploy automatically to non-production or production according to explicit policy.

### Level 6 — Automated publication and operation

AI may generate:

- development reports
- world reports
- social posts
- operational summaries

Only after corresponding safety controls exist.

## Human approval remains required for

- credentials and secret-management changes
- authentication / authorization policy changes
- production infrastructure changes with irreversible impact
- destructive database changes
- payment or billing functionality
- security controls
- incident-response actions
- changes that expand autonomous permissions

## Public development log

Every task or milestone landed by an AI agent must ship with a bilingual
HTML report under `docs/reports/` (`ja/` and `en/`, plus an entry added
to `docs/reports/index.html`). See `docs/reports/README.md` for the
required sections, the layout, and the truthfulness rules.

Small typo or one-line config fixes are exempt. Anything worth its own
PR title in `git log` requires a report.

Reports are AI-generated but count as part of the audit trail: every
commit SHA, PR number, CI run, test count, and design decision cited in
a report must be independently verifiable in the repository. Reports may
not invent state.

## Public social broadcasting (X development live)

Task- or milestone-scale PRs that warrant a public announcement must
also ship with a bilingual X manifest at
`docs/social/x/task-<NNN>-<slug>.json`. The AI writes and commits the
post text at PR-authoring time; a GitHub Actions workflow publishes it
only after the PR is merged and the `main` CI passes. Trivial typo /
one-line config fixes are exempt.

Design and operator guarantees:

- The publisher is stdlib-only and never calls an LLM at runtime.
- Live posting is fail-closed until the repository variable
  `X_AUTOPOST_ENABLED == "true"` (a human step, not an AI step).
- Every successful post is recorded against its merge commit SHA in a
  dedicated GitHub audit issue, so workflow re-runs cannot double-post.
- The AI must not create the X Developer App, install X credentials,
  flip the kill switch, or modify the X account profile.

Truthfulness rules for reports apply verbatim to social posts. See
`docs/adr/0003-x-development-live.md` and `docs/social/x/README.md`.

## Principle

Autonomy should reduce repeated manual work.

It must not remove observability, accountability, rollback capability, or explicit responsibility.
