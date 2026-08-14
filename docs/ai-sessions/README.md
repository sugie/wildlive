# WildLive Public AI Development Archive

WildLive is more than a game built by AI. This repository is also
meant to be an **open reference** for AI-assisted software
development: anyone can trace exactly what prompt a human gave the
AI, what the AI actually replied with in the visible interaction,
what commands were run, and what Pull Request and merge came out of
it.

This directory holds that archive.

## Language policy

- Development frequently happens in Japanese (prompts and visible AI
  responses).
- WildLive is built in public for an international, primarily
  English-speaking audience.
- **Archived records are published in English only.**
- Each record is a **faithful English translation** of the original
  interaction. No summary, no beautification, no added
  requirements, no meaning changes.
- Code, commands, file paths, URLs, identifiers, and error messages
  are kept in their original form where translating them would
  change their meaning.
- Japanese originals are not stored in the public repository.
- The bilingual (Japanese + English) HTML development reports under
  [`docs/reports/`](../reports/) are a separate deliverable and
  continue to be produced in both languages.

## What is (and is not) archived

Archived:

- The human prompt that started a milestone.
- Human follow-ups and corrections.
- The AI's **visible** responses.
- Important commands the AI ran.
- Concise, important command/test output.
- The final AI report.
- Pull Request URL, merge commit, CI conclusion.
- Related bilingual development report links.

**Not** archived:

- Private chain-of-thought.
- Any private / hidden internal reasoning that the human did not see.
- Secrets, credentials, tokens, passwords, API keys, private keys,
  Authorization headers, cookies, `.env` values, or any GitHub
  Secret value.
- Personally identifying information or local-environment details
  that are not needed to understand the development action.

Anything the archiver cannot honestly reconstruct is written as
`Not captured` or `Not available in the public session record`
— never invented.

## Directory layout

```
docs/ai-sessions/
├── README.md           this file
├── index.md            chronological index of every archived task
├── schema.json         JSON Schema for each task's metadata.json
└── task-<NNN>-<slug>/
    ├── README.md       per-task navigation hub
    ├── prompt.en.md    faithful English translation of the human prompt
    ├── transcript.en.md timeline of visible human/AI interaction
    └── metadata.json   machine-readable metadata (schema v1)
```

`<NNN>` matches the milestone / report number, **not** the PR
number.

## When to add a record

A milestone-level AI development task should leave a public English
session record. Trivial fixes (typos, one-line config changes,
dependency patches) do not need one — they are covered by the PR
description alone.

The bar is the same as for
[`docs/reports/`](../reports/): if the change is worth its own PR
title in `git log`, it is worth an archive record.

## How to add a new task record

1. Create the task directory `docs/ai-sessions/task-<NNN>-<slug>/`.
2. Copy the original human prompt into `prompt.en.md`, translating
   faithfully into English. Keep the source structure (headings,
   numbered items, code blocks, constraints). Do not add or drop
   requirements. Add a short header identifying source language
   and stating that the file is a faithful English translation.
3. Write `transcript.en.md` as a timeline of the **visible**
   interaction (human, AI, commands, results). Keep code, paths,
   identifiers, and error messages verbatim. Redact any secret.
4. Fill in `metadata.json` (see `schema.json`). Post-merge fields
   (`pr_number`, `pr_url`, `merge_commit`, `ci_status`,
   `post_merge_ci_status`) may be `null` at author time and can be
   backfilled in a follow-up commit or a small subsequent PR.
5. Write a short `README.md` in the task directory with the
   navigation links required by
   [§7 of the archive rules in AGENTS.md / AUTONOMY.md](#navigation-links).
6. Add a line for the task to [`index.md`](index.md).
7. Run the validator (see below) before opening the PR.

<a id="navigation-links"></a>

### Required per-task navigation links

Every task `README.md` must link to:

- `prompt.en.md` (`View Prompt`)
- `transcript.en.md` (`View AI Conversation`)
- The Pull Request (`View Pull Request`)
- The English development report (`View Development Report (EN)`)
- The Japanese development report (`View Development Report (JA)`)

Use plain relative links so they resolve on `github.com`.

## Validator

A small stdlib-only Python linter lives at
[`scripts/ai/validate_session.py`](../../scripts/ai/validate_session.py).
It checks:

- `metadata.json` parses and matches `schema.json`.
- `prompt.en.md` and `transcript.en.md` exist at the paths declared
  in `metadata.json`.
- No file in the task directory contains obvious credential
  patterns (bearer tokens, `ghp_…`, `gho_…`, `sk-…`, `AKIA…`,
  PEM private-key headers, common `password=` patterns).
- No file uses the banned phrase "verbatim original prompt" (which
  would misrepresent a translation as an original).
- Relative links in the task `README.md` resolve.

Run it:

```bash
python3 scripts/ai/validate_session.py docs/ai-sessions/task-<NNN>-<slug>/
```

## Security

Publishing prompts / transcripts is easy to get wrong. The
following are **absolutely never** allowed in this directory (or in
any file this repository ships):

- API keys, access tokens, passwords, private keys, cookies,
  Authorization headers, `.env` values, GitHub Secret values.
- Personal information (real names, email addresses, phone
  numbers, IP addresses, mailing addresses) that is not already
  public in the repository.
- Local machine paths that reveal a user's home directory contents
  beyond what is necessary to understand the action.

Where a secret would otherwise appear in a command or transcript,
replace it with `[REDACTED]`. The validator's secret scanner will
fail the PR if a real-looking secret slips through.

## Automation status

Capture is currently **human-driven**. The AI writes the prompt
translation and the transcript from the interaction it actually
witnessed, then runs the validator. See the amendment note in
[`docs/AUTONOMY.md`](../AUTONOMY.md) for future automation work.
