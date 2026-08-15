# Task 008 — iOS title screen (Milestone 001, UI-first)

The first WildLive milestone under the UI-first development order (`UI → Interaction → Game Experience → Domain/API → Infrastructure`). Ships a minimal SwiftUI title screen that runs on the iOS Simulator, so the human can look at "WildLive on an iPhone" before we build any of the game loop, API, or persistence around it.

## Navigate

- [View Prompt](prompt.en.md) — faithful English translation of the Japanese prompt.
- [View AI Conversation](transcript.en.md) — visible human/AI interaction and tool activity for this session.
- [View Pull Request](https://github.com/sugie/wildlive/pull/12) — PR #12.
- [View Development Report (EN)](../../reports/en/task-008-ios-title-screen.html)
- [View Development Report (JA)](../../reports/ja/task-008-ios-title-screen.html)
- [View app source](../../../apps/ios/) — `apps/ios/`

## Pull Request

**PR:** [#12 — feat(ios): add SwiftUI title screen (Milestone 001, UI-first)](https://github.com/sugie/wildlive/pull/12). The human's `OK Make PR` reply after reviewing the Simulator screenshot authorised push and PR creation; merge is not yet authorised.

## Metadata

Machine-readable metadata for this session is at
[`metadata.json`](metadata.json) and validates against
[`../schema.json`](../schema.json).

## Language and truthfulness

- Original interaction: primarily Japanese.
- Archive record: English only, faithful translation. No summary, beautification, or added requirements. Code, commands, paths, identifiers, and error messages are kept in their original form.
- Nothing that could not be honestly captured has been fabricated. Where the transcript was unavailable it is marked `Not captured` or `Not available in the public session record`.
- No private chain-of-thought or hidden reasoning is included.

## X Development Live

Deliberately no X manifest was authored for this task (see Milestone 001 brief §27 — Version-0 UI-only work is not itself an auto-post-on-merge target). The `X Development Live` workflow will find zero manifests in this PR's diff and exit cleanly as a documented no-op.

## Security

No secret, credential, token, cookie, or `.env` value appears in
this record. The bundle identifier `dev.wildlive.WildLive` is a
public placeholder, not a signing certificate or provisioning
profile. See [`../README.md#security`](../README.md#security) for
the policy the archive enforces.
