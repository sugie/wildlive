# WildLive iOS client

Native iOS client for WildLive. **Milestone 001 (Version 0)** — only the title screen.

## Scope of this milestone

- SwiftUI title screen with `WildLive` title, `AI Made Live MMO` subtitle, and a tappable `START` button.
- Portrait-only, dark theme, safe-area-respecting layout.
- **No** network, no persistence, no API, no auth, no database. See the top-level [`CLAUDE.md`](../../CLAUDE.md) — WildLive is now UI-first (`UI → Interaction → Game Experience → Domain/API → Infrastructure`).

## Local requirements

- Xcode 26.6 (or newer with iOS 17.0 SDK)
- An iOS 17.0+ Simulator runtime (the milestone was verified on iOS 26.5)

## Build (CLI)

```bash
cd apps/ios
xcodebuild \
  -project WildLive.xcodeproj \
  -scheme WildLive \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath build \
  build
```

The final line of successful output is `** BUILD SUCCEEDED **`.

## Run on Simulator

```bash
# Boot the simulator (name must match an installed device):
xcrun simctl boot 'iPhone 17'
open -a Simulator

# Install and launch the freshly-built app:
xcrun simctl install booted \
  apps/ios/build/Build/Products/Debug-iphonesimulator/WildLive.app
xcrun simctl launch booted dev.wildlive.WildLive
```

Or open `WildLive.xcodeproj` in Xcode and press ⌘R.

## Project layout

```
apps/ios/
├── README.md                                (this file)
├── WildLive.xcodeproj/
│   └── project.pbxproj                      (hand-authored — no XcodeGen/Tuist)
└── WildLive/
    ├── WildLiveApp.swift                    (@main App entry point)
    ├── TitleView.swift                      (SwiftUI title screen)
    └── Assets.xcassets/                     (AppIcon, AccentColor placeholders)
```

## Deliberate non-goals for Version 0

Do not add any of the following to this app in this milestone — they are for
later milestones once the human has approved the title screen:

- Network / API client
- Persistence / Core Data / SwiftData
- Authentication
- Navigation past the title screen
- Analytics / crash reporting / push notifications
- Third-party UI frameworks
- MVVM / Redux / dependency-injection frameworks
- Game engine or `SpriteKit` / `SceneKit`

The whole point is to let a human open the Simulator, look at the screen, and
tell us what to change.
