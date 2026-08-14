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

## Principle

Autonomy should reduce repeated manual work.

It must not remove observability, accountability, rollback capability, or explicit responsibility.
