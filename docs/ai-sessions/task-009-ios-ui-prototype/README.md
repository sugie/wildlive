# Task 009 — iOS UI prototype of the core loop (Milestone 002, UI-first)

The second WildLive milestone under the UI-first development order (`UI → Interaction → Game Experience → Domain/API → Infrastructure`). Extends the Task 008 title screen into a clickable SwiftUI prototype of the entire core loop (home dashboard, own Zoo, other players' Zoos, Guild, contract a Hunter, dispatch to a Region, expedition result, keep-and-name or release, and a RevenueCat-shaped G store) — all against in-memory dummy data, verifiable inside the iOS Simulator with no backend involved.

## Navigate

- [View Prompt](prompt.en.md) — faithful English translation of the Japanese prompt.
- [View AI Conversation](transcript.en.md) — visible human/AI interaction and tool activity for this session.
- [View Development Report (EN)](../../reports/en/task-009-ios-ui-prototype.html)
- [View Development Report (JA)](../../reports/ja/task-009-ios-ui-prototype.html)
- [View app source](../../../apps/ios/) — `apps/ios/`

## Pull Request

**PR:** not yet opened. The human's next step is a manual playthrough of the Simulator build; push / PR / merge are not yet authorised. Once opened, the planned target is `ai/011-ios-title-screen` (stacked on Task 008's still-open PR #12) so the diff shows only Task 009's changes; the base will re-target to `main` automatically after PR #12 merges.

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

Deliberately no X manifest was authored for this task, following the Milestone 001 §27 precedent — pre-UI-review Version-0-ish iterations are not themselves auto-post-on-merge targets. The `X Development Live` workflow will find zero manifests in this PR's diff and exit cleanly as a documented no-op.

## Security

No secret, credential, token, cookie, or `.env` value appears in
this record. The bundle identifier `dev.wildlive.WildLive` is a
public placeholder, not a signing certificate or provisioning
profile. See [`../README.md#security`](../README.md#security) for
the policy the archive enforces.
