# AGENTS.md

This repository is designed to be developed substantially by autonomous AI agents.

Every agent working in this repository must read this file before making changes.

## Mission

Build **WildLive**, a text-only asynchronous multiplayer game and a public experiment in autonomous AI software development.

## Required workflow

1. Read the relevant documentation under `docs/`.
2. Work on one clearly scoped task at a time.
3. Create a short-lived branch.
4. Never commit directly to `main`.
5. Add or update automated tests.
6. Run all relevant tests before proposing a merge.
7. Before opening the PR, add a bilingual (日本語 + English) HTML report
   under `docs/reports/` covering the task. This applies to any change at
   task or milestone scale; trivial typo or one-line config fixes are
   exempt. See `docs/reports/README.md`.
8. When the task warrants a public X post, also add a bilingual X manifest
   under `docs/social/x/task-<NNN>-<slug>.json`. The AI writes the post
   text at PR-authoring time so it can be reviewed in the PR; the workflow
   only publishes it after merge + successful main CI. Trivial fixes are
   exempt. See `docs/social/x/README.md`.
9. Open a Pull Request.
10. Record agent metadata in the PR template.
11. Do not merge security-sensitive or production-sensitive changes without human approval.

## Branch naming

- `ai/<issue-number>-<description>`
- `human/<issue-number>-<description>`
- `hotfix/<issue-number>-<description>`

Examples:

- `ai/12-add-exploration-result`
- `ai/21-world-first-discovery`
- `human/7-adjust-game-loop`

## Engineering principles

- Keep `main` deployable.
- Prefer small, reversible changes.
- Avoid speculative architecture.
- Use server-authoritative game state.
- Preserve deterministic and testable game rules.
- Prefer explicit domain rules over hidden magic.
- Do not add infrastructure unless it is currently needed.
- Write migrations that are safe and reversible whenever possible.
- Use transactions for operations involving scarcity, ownership, or first-winner semantics.

## AI agents must not

- Commit secrets, credentials, API keys, tokens, or production configuration.
- Push directly to `main`.
- Bypass or disable tests to make CI pass.
- Weaken authentication, authorization, validation, or security controls.
- Perform destructive production database operations.
- Modify production credentials.
- Enable billing, paid features, purchases, or payment processing without human approval.
- Automatically merge security-sensitive changes.
- Fabricate test results, benchmark results, deployment results, or operational status.
- Claim a feature exists unless it is present in the repository and verified.
- Publish a development report (`docs/reports/`) that references a commit,
  PR, CI run, test count, or feature that has not been verified against
  Git / GitHub / actual command output.
- Compose X post text (`docs/social/x/`) at runtime. Post text must be
  committed in a PR and reviewed there; the workflow does not call an LLM.
- Enable X auto-posting (`X_AUTOPOST_ENABLED = true`), create the X
  Developer App, install X credentials into GitHub Secrets, or change the
  X account profile. Those are human-only steps described in
  `docs/social/x/README.md`.

## Pull Request metadata

Every PR should record:

- AI Agent
- Reviewer
- Human intervention
- Tests
- Risk level

## Source of truth

For product intent, use:

- `docs/VISION.md`
- `docs/GAME_DESIGN.md`

For technical intent, use:

- `docs/ARCHITECTURE.md`
- `docs/adr/`

For autonomous-development constraints, use:

- `docs/AUTONOMY.md`
- `docs/GUARDRAILS.md`

For the public development log, use:

- `docs/reports/README.md`
- `docs/reports/`

For public social automation (X development live), use:

- `docs/SOCIAL_AUTOMATION.md`
- `docs/adr/0003-x-development-live.md`
- `docs/social/x/README.md`

If documentation conflicts, stop and flag the conflict rather than guessing.
