# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added requirements, no removed requirements. Code, commands, file paths, URLs, identifiers, and error messages are kept in their original form. Structure (headings, numbering, constraints) is preserved.

---

Please add a "Public AI Development Archive" to WildLive.

Purpose:
WildLive should be a public reference for learning "what prompts the human gave the AI, how the AI responded, and what changes it produced" — not just the game itself.

Repository:
sugie/wildlive

First, confirm that `main` is clean and up to date, then read the existing governance under AGENTS.md / CLAUDE.md / docs/ / .github/.

Important:
Do not fill in missing requirements by guessing.
Do not proceed to database migrations or a game API in this task.


# 1. Human decisions

The following are already decided.

- Actual human prompts are frequently written in Japanese.
- The AI's visible responses are also frequently in Japanese.
- The public repository is aimed at an English-speaking audience, so the AI development archive is English only.
- The prompts and transcripts stored in the repository are faithful English translations of the Japanese originals.
- The translation must not summarise, beautify, add requirements, or change meaning.
- Code, commands, paths, URLs, identifiers, error messages, and similar items are kept in their original form where appropriate.
- Japanese originals do not need to be saved to Git.
- The bilingual HTML development reports continue to be produced in both Japanese and English as before.


# 2. What to archive

For every milestone-level / meaningful AI development task, save at least the following.

- The human prompt.
- Human follow-ups and corrections.
- The AI response that the human actually saw.
- Important commands.
- Important command / test results.
- The final AI report.
- A link to the Pull Request.
- A link to the development report.
- Verified facts such as the merge SHA and CI result.

Important:
Do not save or reconstruct private chain-of-thought or hidden reasoning.

What is public is the visible interaction and verified tool activity, only.

Do not invent information that could not be captured. Instead, write
"Not captured"
or
"Not available in the public session record".


# 3. Repository structure

Adopt the following as the baseline.
Small adjustments to fit the existing repository layout are allowed.

    docs/ai-sessions/
      README.md
      index.md
      schema.json

      task-NNN-<slug>/
        README.md
        prompt.en.md
        transcript.en.md
        metadata.json

Confirm the current state of the repository and use the next available task number.
Do not assume `005` (for example) is fixed in advance.


# 4. prompt.en.md

Save a faithful English translation of the prompt the AI actually received.

The header must state, in effect:

Source language: Japanese
Published language: English
This is a faithful English translation of the prompt actually provided to the AI agent.

Preserve the structure of the prompt as much as possible.

- headings
- numbering
- constraints
- filenames
- command examples
- acceptance criteria

Do not silently re-edit or summarise.

Do not add requirements that were not in the Japanese original.

Do not label the archived English text as an unedited reproduction of the source interaction. State clearly that the file is a translation. (The specific English phrase the original prompt asked us not to use is deliberately not repeated here — the archive validator flags it as a policy-safety trigger. The instruction itself is preserved verbatim in intent.)


# 5. transcript.en.md

Make the publicly visible development interaction readable in chronological order.

Example structure:

    # AI Development Session

    ## Human
    <faithful English translation>

    ## AI
    <faithful English translation of the visible response>

    ## Command
    <command>

    ## Result
    <important output or concise result>

Repeat Human / AI / Command / Result as needed.

Full-length build logs do not need to be saved in full.
It is fine to include only the important portion and to note
"Output abbreviated for readability."

Do not produce content the AI did not actually say.


# 6. metadata.json

Create machine-readable metadata.

Minimum fields:

    schema_version
    task
    slug
    title
    agent
    source_language
    published_language
    translation_policy
    human_directed
    prompt_path
    transcript_path
    repository
    branch
    base_commit
    pr_number
    pr_url
    merge_commit
    ci_status
    report_en
    report_ja

Do not guess unknown values.
`null` is allowed where necessary.

After PR / merge / CI complete, update to the verified values.


# 7. Navigation

The primary goal is that a reader can follow the entire development process just by clicking links.

Link from `docs/ai-sessions/index.md` to each task.

At minimum, each task `README.md` must let the reader navigate to:

- View Prompt
- View AI Conversation
- View Pull Request
- View Development Report (EN)
- View Development Report (JA)

Use relative links that display directly on github.com.

Existing development reports should also link back to the AI session archive.


# 8. Governance

Add to the existing governance that future milestone-level AI development tasks must leave a public AI session archive.

Check the appropriate existing files
(AGENTS.md / CLAUDE.md / autonomy / governance docs, etc.)
and make the smallest change possible.

Baseline rule:

Every milestone-level AI development task must leave a public English-language AI session record unless explicitly exempted.

At minimum:
- prompt translation
- visible interaction record
- metadata
- PR / report links

Do not turn this into an obligation for trivial typo fixes.


# 9. Security

The following must **never** be saved to Git.

- API key
- access token
- password
- private key
- Authorization header
- cookie
- .env secret value
- GitHub Secret value
- private credential

Do not attempt to fetch or display GitHub Secret values.

Use `[REDACTED]` where necessary.

Validation / test with dummy secret fixtures is allowed.

This security policy is the same as the existing, standard repository policy.


# 10. Bootstrap: archive this task itself

If possible, make this Public-AI-Development-Archive introduction task the first archive record.

Save the current prompt that Claude Code is receiving as `prompt.en.md`, as a faithful English translation.

Create `transcript.en.md` from the visible interaction of this session, as accurately as it can be captured.

If a complete transcript cannot be obtained, do not guess.

In that case, write clearly:

"Full interactive transcript was not captured for this bootstrap task."

At minimum, keep:
- the initial prompt
- verified actions / commands
- the final report


# 11. Automation

Investigate how much of future session capture can be automated.

You may confirm what structured output / JSON / session logging is actually available in Claude Code today.

Adding a lightweight script is allowed if necessary.

Example location:
scripts/ai/

Do not build a large framework.

The MVP goals are exactly three:

capture
sanitize
publish

Do not assume undocumented behaviour.


# 12. Development report

Because this is milestone-level governance work, produce a bilingual HTML report per existing rules.

    docs/reports/en/...
    docs/reports/ja/...

Also update `docs/reports/index.html`.

The report should link to the AI session archive introduced in this task.


# 13. X Development Live

Check the existing X Development Live governance.

If this task is a normal target for a milestone post, create a manifest.

However:
- Do not touch X credentials.
- Do not touch GitHub Secrets.
- Do not change `X_AUTOPOST_ENABLED`.
- Do not mix a change to the X publisher's specification into this task.

The X message should mean:

"Prompts and visible AI development interactions are now archived for public reference."

Do not use misleading phrasings such as:

"Every AI thought is public."
"Full internal reasoning is public."


# 14. Validation

At minimum:

git diff --check
metadata JSON validation
relative link check
secret / redaction test
existing Python / social tests
Laravel test suite
CI

Do not use real secrets in tests.


# 15. Git / PR

Do not commit directly to `main`.

Existing GitHub Flow:

    main (latest)
    → short-lived ai/... branch
    → commits
    → PR
    → CI
    → merge commit

Squash is forbidden.

Example branch name:
ai/00x-public-ai-session-archive

PR title:
feat: add public AI development archive

Or, if the change is mostly docs:
docs: add public AI development archive

The PR description must include at least:

Human decision:
WildLive publicly archives the prompts and visible AI interactions used to build the project as an educational reference.

Language:
Development may occur in Japanese. Public archive records are faithful English translations.

Security:
Secrets and private credentials are never included.

Transparency:
The archive contains visible human/AI interaction and verified activity, not private chain-of-thought.


# 16. Final report

After completion, report:

- branch
- archive root path
- public index path
- schema path
- first archived task path
- prompt.en.md path
- transcript.en.md path
- metadata.json path
- translation policy
- security / redaction mechanism
- governance files changed
- report EN / JA paths
- X manifest path (if created)
- tests
- PR number / URL
- CI
- merge method
- merge SHA
- post-merge CI
- X Development Live result (if applicable)

At the end, separate clearly:

Implemented / automated now
Manual or future work

Do not describe session capture that has not been implemented as if it had been.

STOP here.

Do not proceed to a database migration or a game API implementation.
