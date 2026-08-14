# WildLive Autonomous Development Reports

This directory is the public, human-readable log of every AI-authored task
in WildLive. Anyone should be able to read it top-to-bottom and cross-check
each claim against the actual Git history, Pull Request, and CI results.

## Directory layout

```text
docs/reports/
├── README.md                                    (this file)
├── index.html                                   (list of all reports)
├── styles.css                                   (shared stylesheet)
├── template/
│   ├── report.en.html                           (skeleton for English reports)
│   └── report.ja.html                           (skeleton for Japanese reports)
├── en/
│   └── task-<NNN>-<slug>.html                   (English report per task)
└── ja/
    └── task-<NNN>-<slug>.html                   (Japanese report per task)
```

## When to write a report

Write a bilingual pair (`en/` + `ja/`) when a task-level or milestone-level
piece of work is about to be opened as a Pull Request. Do **not** write a
new report for trivial typo fixes, one-line config bumps, or dependency
patches — those can live entirely in the PR description.

Rule of thumb: if the change is worth its own PR title in `git log`, it is
worth a report.

## Companion: X development live manifest

For any task or milestone that warrants a public announcement, also add
a matching X post manifest at `docs/social/x/task-<NNN>-<slug>.json`. The
manifest is committed in the same PR as the report, reviewed there, and
published to X automatically by the `X Development Live` workflow after
merge and successful `main` CI. See
[`docs/social/x/README.md`](../social/x/README.md) and
[`docs/adr/0003-x-development-live.md`](../adr/0003-x-development-live.md)
for the full policy.

## Companion: public AI development archive

Milestone-scale reports should also link to their session record under
[`docs/ai-sessions/`](../ai-sessions/) — an English-only, faithful
translation of the human prompt and the visible AI interaction that
produced the change. Add the session record in the same PR, run
`python3 scripts/ai/validate_session.py <task_dir>` before pushing,
and include the link from the report body. See
[`docs/ai-sessions/README.md`](../ai-sessions/README.md).

## How to add a new report

1. Copy `template/report.en.html` to `en/task-<NNN>-<slug>.html`.
2. Copy `template/report.ja.html` to `ja/task-<NNN>-<slug>.html`.
3. Fill in every section using **verifiable** data:
   - Commit SHAs from `git log`.
   - PR number, title, merge commit, and merged-at timestamp from
     `gh pr view <N> --json ...`.
   - CI run IDs and conclusions from `gh run list --workflow ci.yml`.
   - Test counts from the actual `phpunit` output (do not estimate).
4. Add a new `<li>` to the reports list in `index.html`, linking both
   languages plus the PR.
5. Update the Japanese and English versions in lockstep. If a fact appears
   in one language it must appear in the other.

## Truthfulness rule

The reports double as an audit log for autonomous development. The
following are forbidden:

- Claiming a test was run without actually running it.
- Guessing a test count, assertion count, or CI conclusion.
- Referencing a commit SHA, PR number, or CI run that does not exist.
- Describing a feature that was not implemented.
- Attributing to the AI work that was actually done by a human, or hiding
  human intervention.
- Publishing invented game metrics (player counts, uptime, etc.).

If a fact cannot be verified, mark it explicitly as `Unknown`,
`Not verified`, or `Not applicable`.

See `AGENTS.md` and `docs/GUARDRAILS.md` for the underlying governance.

## Design constraints

- Plain HTML + a single shared `styles.css`. No JavaScript. No external
  CDN, no analytics, no tracking, no fonts.
- UTF-8 in every file.
- The Japanese and English versions share the same headings, table
  structure, and factual claims — natural translation, not literal.
- Everything must be readable directly in a browser opened against the
  file on disk or against `raw.githubusercontent.com`.
