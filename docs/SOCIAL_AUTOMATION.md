# Social Automation

## Goal

WildLive publishes selected development and game-world events to
external channels automatically. The primary channel is **X**.

## Two event sources

### Development events (implemented)

Derived from verifiable GitHub data. Examples currently in scope:

- task/milestone PR merged and post-merge `main` CI succeeded
- future: release published, autonomous-development metrics

Implementation:

- Design record: [`docs/adr/0003-x-development-live.md`](adr/0003-x-development-live.md)
- Manifest directory (AI-authored, human-reviewed): [`docs/social/x/`](social/x/)
- Publisher (Python stdlib): [`scripts/social/post_x.py`](../scripts/social/post_x.py)
- Workflow: [`.github/workflows/x-development-live.yml`](../.github/workflows/x-development-live.yml)

### Game-world events (deferred)

Derived from authoritative game data. Not implemented until game code
exists. Examples once relevant:

- World First
- new globally discovered species
- major cooperative expedition
- world event
- weekly world statistics

## Publication rule

Public posts must be generated from verifiable source data:

- **The AI may write the wording** — but must commit it to the
  repository as a manifest that reviewers can inspect in the Pull
  Request that introduces it.
- **The AI may not invent the underlying event** at runtime, and the
  runtime path must not call an LLM.
- **The AI may not enable live posting.** Activation is a human step
  (`X_AUTOPOST_ENABLED = true`).

See [`docs/GUARDRAILS.md`](GUARDRAILS.md#public-reporting) and
[`docs/AUTONOMY.md`](AUTONOMY.md#public-social-broadcasting-x-development-live).

## Status of the initial-policy checklist

The checklist that used to live here has been implemented as follows.
See [ADR-0003](adr/0003-x-development-live.md) for details.

| Concern             | Status | Where                                                           |
|---------------------|--------|-----------------------------------------------------------------|
| Credential storage  | Done   | GitHub Secrets (`X_API_KEY`, `X_API_KEY_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_TOKEN_SECRET`). Never committed. |
| Posting rate        | Done   | One post per task/milestone PR merge. No auto-repeat.           |
| Duplicate suppression | Done | Merge-SHA idempotency key recorded on a GitHub audit issue.     |
| Moderation / safety | Done   | AI-authored text is committed and PR-reviewed before merge.     |
| Retry behavior      | Done   | Bounded retry (max 3) on 429/5xx only; 4xx fails fast.          |
| Audit log           | Done   | GitHub audit issue `[automation] WildLive X Development Live Audit`. |
| Kill switch         | Done   | Repository Variable `X_AUTOPOST_ENABLED`; fail-closed default.  |

## Not addressed here

- X account setup, automated-account labelling, and any X Automation
  Rules compliance are **human** responsibilities and are described in
  [`docs/social/x/README.md`](social/x/README.md).
- No other social channel (Bluesky, Mastodon, Threads, etc.) is
  implemented. If added, each will get its own subdirectory under
  `docs/social/` and its own ADR.
- Game-world posting is deferred until game code exists.
