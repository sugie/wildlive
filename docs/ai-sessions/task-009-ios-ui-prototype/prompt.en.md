# Human Prompt

- Source language: Japanese
- Published language: English
- Translation: Faithful English translation of the prompt actually provided to the AI agent. No summary, no beautification, no added or removed requirements. Structure (headings, numbering) is preserved.

---

The plan is fixed. First, this includes changes to the splash / title screen we made yesterday. As the mainstay of the UI I want to use SwiftUI, so first I want to build the whole WildLive screen set in SwiftUI with dummy values, and actually operate and verify it. On the top screen: the user's latest status. From there: my own Zoo, and a list of other players' Zoos. Then go to the Guild. In the Guild, find a Hunter. Once found, ask the Hunter to hunt — to go and fetch an Animal for me. Then the result list, and for the Animals that came through, either raise them or make them mine. When making them mine, name them. Or I want to be able to release them. And I also want a full sequence of screens for buying the in-game currency G properly with RevenueCat / IAP. Please build something with dummy values, no server communication, that can be verified with just this simulator.

---

## Follow-up

After the AI presented a plan (task splitting into Task 009 / Milestone 002, scope + non-scope, branch `ai/013-ios-ui-prototype`, staged commits, no real RevenueCat SDK, no persistence, prototype-scaled expedition timers, HTML report + session record at the end), the human replied:

> GO
