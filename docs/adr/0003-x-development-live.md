# ADR-0003: X Development Live Auto-Posting

- Status: Accepted
- Date: 2026-08-14

## Context

WildLive treats its own development history as public content
(`docs/VISION.md`, `docs/AUTONOMY.md`). Every completed task is
already recorded as a bilingual HTML report under `docs/reports/`.
The next step is to broadcast those milestones on X so the
autonomous-development experiment is visible without requiring anyone
to poll the repository.

Two hard problems drive the design below:

1. Public posts must remain **truthful and reviewable**. A hallucinated
   fact broadcast under the WildLive name would poison the
   autonomous-development experiment worse than never posting at all.
2. Public posts must not **spam** followers, and must not be
   re-published simply because a workflow was re-run or a runner
   restarted.

## Decision

### 1. Purpose

Post about WildLive development milestones on X, using post text that
has already been reviewed inside a Pull Request, only after that PR
has been merged into `main` and the resulting `main` CI has passed.

This ADR is **not** a game-facing X integration and does not create a
character called WildLive; it is a channel for showing that the game
is being built.

### 2. Source of truth

Every post is derived exclusively from:

- verified repository state (files on `main`),
- verified Pull Request metadata (via GitHub API),
- verified CI result on `main` (via `workflow_run` context), and
- a **committed social manifest** (`docs/social/x/task-*.json`) that
  was written by an AI agent at PR-authoring time and reviewed
  during PR review.

Nothing else. The publisher does not call an LLM at run time. It does
not synthesise wording. It concatenates the manifest, appends the PR
URL and a fixed hashtag, and sends the result.

The manifest is the audit surface. If a post is wrong, the PR that
introduced the manifest is where the fault is traceable.

### 3. Trigger

- A `workflow_run` completion of the existing `CI` workflow, where:
  - `workflow_run.conclusion == "success"`
  - `workflow_run.event == "push"`
  - `workflow_run.head_branch == "main"`
- A manual `workflow_dispatch` with `dry_run` defaulting to `true`,
  used for backfill and troubleshooting.

Consequences:

- PR opens **never** trigger a post.
- PR CI going green **never** triggers a post.
- Direct pushes to `main` that skip PR merges would technically match
  the trigger, but the workflow additionally requires an associated
  merged PR (see §6) and fails closed otherwise.
- A CI failure on `main` never triggers a post.

### 4. Posting rate

At most **one bilingual post per merged, milestone-scale PR** — never
one per language, never one per commit. Trivial fixes (typos,
one-line config edits) are exempt from having a manifest at all; no
manifest ⇒ no post (a documented no-op, not an error).

### 5. Format

Each post is bilingual, in a fixed template:

```text
{ja}

{en}

PR #{N}
{pr_url}

#shipaton
```

- `{ja}` and `{en}` come from the manifest.
- `PR #{N}` and `{pr_url}` are added by the workflow / publisher,
  never by the AI at authoring time — the AI does not know a future
  PR number.
- `#shipaton` is appended by the publisher and is **not** included in
  the manifest body, to prevent accidental duplication.
- Total length is length-checked against a conservative approximation
  of X's twitter-text weighted length (max 280, weight-2 for CJK,
  URLs count as 23). The publisher rejects over-length input before
  reaching the network.

### 6. Manifest discovery

Given a merge commit SHA:

1. The workflow queries GitHub for the PR that merged with that SHA.
2. It confirms the PR is `merged`, `base=main`, `head` was a
   short-lived branch (not `main` itself).
3. It lists files changed in that PR and matches
   `docs/social/x/task-*.json`.
4. Zero matches → no-op. One match → post. Two or more → fail closed.

If no associated PR is found (unusual — e.g. a force-push to `main`
that skipped the PR flow), the workflow **fails closed**: no post.

### 7. Authentication and API

- Endpoint: `POST https://api.x.com/2/tweets` (X API v2, "Create
  Post").
- Auth: **OAuth 1.0a User Context**, chosen over OAuth 2.0 because
  the credentials are long-lived and unattended GitHub Actions jobs
  cannot easily perform the OAuth 2.0 refresh dance. The four
  credentials are stored as GitHub Secrets, not repository files:
  - `X_API_KEY`
  - `X_API_KEY_SECRET`
  - `X_ACCESS_TOKEN`
  - `X_ACCESS_TOKEN_SECRET`
- No browser automation. No third-party X client. No dependency on
  any non-stdlib package to construct the signature.

### 8. AI disclosure (`made_with_ai`)

X's public API documentation has, at various points, discussed a
`made_with_ai` flag on the Create Post payload. As of the writing of
this ADR, we cannot confirm the flag is currently accepted by the
production `POST /2/tweets` endpoint from within this repository, so
the publisher **does not send it**. Sending an unknown field is a
common source of `400 Bad Request` responses.

If, after human verification against the current X API documentation,
the flag is confirmed to be supported for this posting mode, the
publisher can be updated in a small follow-up PR to include it. The
transparency intent (labelling posts as AI-generated) is currently
satisfied through:

- the fixed `#shipaton` hashtag,
- the `AI development live` framing on the associated X account
  (configured by the human at account-setup time — see §12), and
- the WildLive `docs/reports/` HTML that this ADR points at.

### 9. Kill switch (fail-closed default)

A **Repository Variable** (not a Secret) named `X_AUTOPOST_ENABLED`
gates every live call:

- `X_AUTOPOST_ENABLED == "true"` — live posting is permitted.
- Anything else, including unset — the workflow logs
  `disabled — no post` and exits cleanly.

Storing the switch as a Repository Variable, not a Secret, lets a
human toggle it without touching credentials. Rotating credentials
does not require touching the switch, and disabling posting does not
require destroying credentials.

Merging this PR does **not** enable posting. Live posts require an
explicit human action to flip the variable to `true`.

### 10. Duplicate suppression / idempotency

Every successful post appends a marker to a designated audit issue,
using the merge commit SHA as an idempotency key. Before posting, the
publisher checks the issue for the same marker:

- marker present ⇒ `already posted — skip` (exit 0).
- marker absent ⇒ post, then append.

Audit-marker format (HTML comment so it renders invisibly):

```html
<!-- x-autopost:{merge_sha} -->
```

The audit issue is identified by title:

```text
[automation] WildLive X Development Live Audit
```

Rationale for using a GitHub Issue:

- Persistent across workflow runs and repository re-clones.
- Human-visible.
- Requires only `issues: write`, which is far narrower than
  `contents: write`.
- No new external dependency (no KV store, no S3, no dedicated DB).

Additionally, the workflow uses a `concurrency` group keyed on the
merge SHA so simultaneous `workflow_run` and `workflow_dispatch`
invocations for the same SHA serialise.

### 11. Retry and error handling

- Bounded retry on `429` and `5xx` (max 3 attempts, exponential
  backoff bounded at a few seconds). Never unbounded.
- No retry on `4xx` other than `429` — a `400`/`401`/`403` almost
  always means the manifest, signature, or credentials are wrong;
  retrying just burns budget.
- A posting failure never modifies application, PR, or repository
  state. It surfaces as a red workflow run, nothing more.

### 12. X account transparency (human responsibility)

X currently has published rules for automated accounts, including
requirements around labelling and (in some setups) linking to a
managing human account. **The AI does not touch X profile settings.**
The human running WildLive is responsible for:

- reading the current X Automation Rules,
- configuring the posting X account with any required automated-label
  metadata,
- linking the automation account to a managing human account if X's
  current rules require it.

### 13. API cost awareness

X's API is currently pay-per-use with tier-based limits. This ADR
does not hard-code prices. Human sign-off on cost is required before
`X_AUTOPOST_ENABLED` is flipped to `true`, and posting is deliberately
limited to task/milestone PRs (§4) so per-day volume is small.

### 14. Deferred

- Game-world posting (World First, Seasonal Event announcements,
  weekly world statistics) is deferred until the game is playable.
- Threaded replies, media, polls, quote-posts, and Community-target
  posts are out of scope.
- Localisation beyond `ja` + `en` is out of scope.
- OAuth 2.0 migration is a future option; OAuth 1.0a is the current
  choice for the reasons in §7.

## Consequences

### Positive

- Every WildLive post is reviewable in a PR before it is ever sent.
- Truthfulness is enforced by the PR review, not by trusting the
  runtime.
- No LLM cost at post time.
- The runtime path is small enough to unit-test with Python stdlib.
- The kill switch is a one-click revert without touching credentials.

### Trade-offs

- The AI cannot react to unexpected reactions (replies, viral
  moments); this is a broadcast channel, not a conversation.
- If the AI drafts a wording that becomes stale between PR-author
  time and merge time, a new commit is required to update it.
- If X changes its API surface (new required fields, deprecated
  endpoints), a code change is required — the publisher will not
  silently adapt.

### Human intervention

The **human** (repository owner) decided that WildLive's own
development should be publicly visible on X and defined the goal of
an AI-authored bilingual live-development feed. The AI (Claude Code)
designed the automation, wrote this ADR, implemented the publisher,
wrote the workflow, wrote the tests, and drafted the first manifest.
The AI must **not**:

- create the X Developer app,
- generate or install X credentials,
- flip `X_AUTOPOST_ENABLED` to `true`,
- change the X account's profile, display name, bio, avatar, or
  automated-label metadata.

Those actions require an explicit human step described in
`docs/social/x/README.md`.
