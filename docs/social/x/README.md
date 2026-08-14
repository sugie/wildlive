# WildLive X Development Live

This directory holds the AI-authored, human-reviewed social manifests
that drive WildLive's automated X posts. It is the source of truth
for the workflow at [`.github/workflows/x-development-live.yml`](../../../.github/workflows/x-development-live.yml)
and the publisher at [`scripts/social/post_x.py`](../../../scripts/social/post_x.py).

See [ADR-0003](../../adr/0003-x-development-live.md) for the reasoning
behind every decision here.

## What lives here

```text
docs/social/x/
├── README.md                                   (this file)
├── schema.json                                 (JSON Schema for manifests)
└── task-<NNN>-<slug>.json                      (one per posted milestone)
```

## When to add a manifest

When an AI agent is about to open a task- or milestone-scale Pull
Request, it should also add a manifest for that PR under this
directory. Trivial PRs (typo fix, one-line config change, dependency
patch only) do **not** need a manifest and will be silently skipped
by the workflow.

Rule of thumb: if it warrants a bilingual HTML report under
`docs/reports/`, it warrants a manifest here.

## Manifest schema

```json
{
  "schema_version": 1,
  "task": "Task 003",
  "slug": "x-development-live",
  "post_on_merge": true,
  "ja": "日本語の短い開発実況テキスト。",
  "en": "Short English development update."
}
```

- **`schema_version`** — integer. Only `1` is currently accepted.
- **`task`** — the display label used in the post
  (e.g. `Task 003`). Must be non-empty.
- **`slug`** — matches the filename slug and the bilingual report
  slug. Kebab-case ASCII.
- **`post_on_merge`** — boolean. If `false`, the manifest is
  reviewed but not posted. Useful for landing an AI-drafted post as
  documentation without publishing it.
- **`ja`** — Japanese body. Must not include the PR URL or the
  `#shipaton` hashtag — the publisher appends both.
- **`en`** — English body. Same rules as `ja`.

Both `ja` and `en` must be present and non-empty; the workflow rejects
a manifest that has only one language.

Full JSON Schema: [`schema.json`](schema.json).

## Rendered post format

The publisher builds the actual post from the manifest like this:

```text
{ja}

{en}

PR #{N}
{pr_url}

#shipaton
```

The PR number and URL are resolved by the workflow at post time from
the merge commit SHA. The AI never guesses a future PR number.

## Length rule

X's `POST /2/tweets` currently caps a post at 280 weighted characters
(twitter-text weight algorithm; a Japanese character weighs 2, an
ASCII character weighs 1, a URL is counted as 23 regardless of length).

The publisher runs a conservative approximation of this algorithm
against the rendered post **before** touching the network. Over-length
manifests are rejected in the PR-review-time dry run, not at post
time.

Aim for roughly:

- Japanese body: ≤ 60 CJK characters,
- English body: ≤ 130 ASCII characters,

which comfortably fits the URL + hashtag + `Task N` line + the two
bodies inside the 280-weight cap.

## Truthfulness

Only claim what a reader could verify by opening the PR:

- The PR title / topic in one line each language.
- Whether it was code, docs, tests, infrastructure, etc.
- One why-it-matters clause.

**Do not** claim player counts, launch dates, or future promises. Do
not claim tests were run unless they were. Do not attribute human
work to the AI (or vice-versa).

See [`docs/GUARDRAILS.md`](../../GUARDRAILS.md#public-reporting) for
the full list.

## Trigger

See [`.github/workflows/x-development-live.yml`](../../../.github/workflows/x-development-live.yml).

Automatic:

```text
CI workflow completes on push to main with conclusion=success
    → find the merged PR for that SHA
    → find its docs/social/x/task-*.json manifest
    → require exactly one match
    → check kill switch
    → check audit ledger for the SHA
    → post via OAuth 1.0a
    → record audit marker
```

Manual (`workflow_dispatch`):

- `pr_number` — optional, defaults to auto-detect.
- `dry_run` — defaults to `true`. Runs the full pipeline except the
  final `POST /2/tweets`. Use this for setup verification and
  backfill previewing.

## Kill switch

Repository **Variable** (not Secret):

```text
X_AUTOPOST_ENABLED
```

- `true` → live posting permitted.
- anything else (including unset) → workflow logs
  `disabled — no post` and exits cleanly.

This variable is intentionally not a secret so a human can flip it
without touching credentials. To disable posting in an emergency, set
it to `false`; credentials do not need to be rotated or removed.

## Required GitHub Secrets

Set these in the repository (or environment) secret store before
enabling live posting. **Never commit them.**

- `X_API_KEY`
- `X_API_KEY_SECRET`
- `X_ACCESS_TOKEN`
- `X_ACCESS_TOKEN_SECRET`

If any of the four is missing, the publisher fails closed and no HTTP
request is built.

## Required GitHub Variable — audit ledger

Optional but recommended:

```text
X_AUTOPOST_AUDIT_ISSUE   (integer, the issue number of the audit ledger)
```

If unset, the workflow searches for an issue with the exact title
`[automation] WildLive X Development Live Audit`. If neither is
resolvable, the workflow fails closed rather than posting without
audit.

Create the audit issue once, manually:

```bash
gh issue create \
  --title "[automation] WildLive X Development Live Audit" \
  --body "Automated audit log for X development-live posts. Do not close. Do not edit body freely — each successful post appends a comment with a machine-readable marker of the form: <!-- x-autopost:<merge-sha> -->."
```

## Duplicate suppression

Every successful post appends one comment to the audit issue,
containing an HTML-comment marker:

```html
<!-- x-autopost:{merge_sha} -->
```

Before posting, the publisher scans the audit issue (body + comments)
for a marker matching the current merge SHA. If found, it exits with
`already posted — skip`. This holds across workflow re-runs, runner
restarts, and manual `workflow_dispatch` invocations for the same
SHA.

Additionally, the workflow's `concurrency` group is keyed on the
merge SHA, so simultaneous invocations for the same SHA serialise.

## Emergency disable

1. Open the GitHub repository settings.
2. Under *Secrets and variables* → *Actions* → *Variables*, set
   `X_AUTOPOST_ENABLED` to `false` (or delete the variable).
3. Any subsequent workflow run will log `disabled — no post` and
   exit cleanly. Credentials do not need to be touched.

## First-time activation procedure (human-run)

The AI does **not** perform any of these steps.

1. Read the current [X Automation Rules](https://help.x.com/) and
   confirm the account intended for WildLive dev-live posts meets
   any current requirements (automated-account label, linked human
   account, etc.).
2. Create an X Developer app, generate the four OAuth 1.0a
   credentials, and register them as GitHub Secrets on this
   repository (never commit them).
3. Create the audit issue with the `gh issue create` command shown
   above.
4. Confirm `X_AUTOPOST_ENABLED` is unset (or `false`).
5. Merge the implementation PR. The workflow ships with the switch
   defaulted to disabled — merging alone will not post.
6. Run the workflow manually:
   `Actions → X Development Live → Run workflow`, leaving
   `dry_run = true`. Confirm the rendered preview looks correct.
7. Repeat with `dry_run = false` on a specific known-good PR
   (`pr_number = <N>`) to validate real posting once. Verify the
   post shows up on X, then verify the audit marker was written.
8. Only after those manual live tests succeed, set
   `X_AUTOPOST_ENABLED = true`. From that point, task-scale merges
   post automatically.

## AI account transparency

X's Automation Rules may require an automated account to identify
itself (in bio, label, or linked-to-human account). Verify current
requirements before enabling live posting. The AI does not manage
the X profile.

## Costs

X API pricing changes over time. Confirm the current per-post cost
and monthly cap on the X Developer Console before flipping
`X_AUTOPOST_ENABLED` to `true`. This directory does not hard-code
any price into logic.
