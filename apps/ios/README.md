# WildLive iOS client

Native iOS client for WildLive.

- **Milestone 001 (Task 008, Version 0):** SwiftUI title screen only.
- **Milestone 002 (Task 009, this branch):** UI-only clickable prototype of the WildLive core loop — home dashboard, own Zoo, other players' Zoos, Guild, Hunter contract, Region dispatch, expedition resolution, capture/name/release, and G store — all backed by in-memory dummy data.
  - **Iteration 2 (Apple SwiftUI defaults):** rendered against stock SwiftUI — system background, `List` / `Form` / `Section` / `LabeledContent` / `NavigationLink(value:)`, `.buttonStyle(.borderedProminent)`, system SF Symbols on `Label`, system blue tint. No forced colour scheme, no custom gradients, no custom card modifier. Colour is used only where it carries information (rarity tier, region difficulty).

## Scope of Milestone 002

- Whole app runs against `SampleData` — no network, no persistence, no API, no backend, no auth, no database.
- One `@Observable` `AppStore` holds the entire client-side state; it is destroyed on app termination (state does not persist across launches — that is intentional for the prototype).
- `MockGameService` mirrors the *shape* of the future server-authoritative service (contract, dispatch, resolve, keep/release) so real API code can slot in without touching any View.
- `MockGStoreService` mirrors the shape of a RevenueCat-backed IAP layer. **No real RevenueCat SDK is bundled.** All prices are placeholders for design review.
- Expeditions use a prototype-scaled duration (8–60 seconds) instead of the real 10-minute-to-24-hour timings so a human can play the whole loop inside the Simulator in under a minute.

## Deliberate non-goals (still in force)

- No REST/HTTP/GraphQL/WebSocket client
- No PostgreSQL connection
- No authentication or user model
- No SwiftData / Core Data persistence
- No production infrastructure access
- No RevenueCat SDK
- No third-party UI framework
- No MVVM / Redux / dependency-injection framework
- No game engine, SpriteKit, or SceneKit
- No push notifications / analytics / crash reporting

Human UI review still gates the next iteration.

## Local requirements

- Xcode 26.6 (or newer with iOS 17.0 SDK)
- An iOS 17.0+ Simulator runtime (verified on iOS 26.5)

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

Successful output ends with `** BUILD SUCCEEDED **`.

## Test (CLI)

```bash
cd apps/ios
xcodebuild \
  -project WildLive.xcodeproj \
  -scheme WildLive \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath build \
  test
```

Successful output ends with `** TEST SUCCEEDED **`.

## Run on Simulator

```bash
xcrun simctl boot 'iPhone 17'
open -a Simulator
xcrun simctl install booted \
  build/Build/Products/Debug-iphonesimulator/WildLive.app
xcrun simctl launch booted dev.wildlive.WildLive
```

Or open `WildLive.xcodeproj` in Xcode and press ⌘R.

## Manual playthrough (Milestone 002)

1. Tap **START** on the title screen.
2. On the Home dashboard note the initial `G` balance (1,200) and Zoo Value.
3. Tap **Guild → Contract Ash the Apprentice → Choose Region → Village Outskirts → Dispatch**.
4. Tap **Go to Expeditions**. Watch the countdown (~8 s for Village Outskirts).
5. When it hits zero, tap the row to open the result. If captured, tap **Add to Zoo → name → Add to Zoo**. Or tap **Release**.
6. Return to Home. Zoo Value / Animals updated.
7. Tap **Other Zoos** to visit another player's Zoo (read-only).
8. Tap **Store → tap any bundle**. A mock 0.8 s purchase credits the `G` balance.

## Project layout

```
apps/ios/
├── README.md                       (this file)
├── WildLive.xcodeproj/
│   └── project.pbxproj             (hand-authored — no XcodeGen/Tuist)
├── WildLive/
│   ├── WildLiveApp.swift           (@main App; injects AppStore)
│   ├── RootView.swift              (Title vs. NavigationStack)
│   ├── TitleView.swift             (Milestone 001 title screen; START now navigates)
│   ├── AppStore.swift              (@Observable — the only mutable state)
│   ├── Route.swift                 (NavigationStack destinations)
│   ├── Theme.swift                 (colors, .card() modifier)
│   ├── Domain.swift                (Species, Animal, Hunter, Region, Expedition, Player, GBundle)
│   ├── SampleData.swift            (dummy species / hunters / regions / players / G bundles)
│   ├── MockGameService.swift       (contract / dispatch / resolve / keep / release — idempotent)
│   ├── MockGStoreService.swift     (mock RevenueCat-shaped store)
│   ├── HomeView.swift              (dashboard)
│   ├── MyZooView.swift             (own Zoo grid)
│   ├── OtherZoosView.swift         (ranking of players)
│   ├── VisitZooView.swift          (read-only other-player Zoo)
│   ├── AnimalDetailView.swift      (single-animal detail)
│   ├── GuildView.swift             (hunter list + contract)
│   ├── RegionPickerView.swift      (region choice for a contracted hunter)
│   ├── DispatchConfirmView.swift   (final confirmation before dispatch)
│   ├── ExpeditionsView.swift       (ongoing + resolved list)
│   ├── ExpeditionResultView.swift  (single expedition — resolves idempotently on view)
│   ├── CaptureNameView.swift       (name a captured animal)
│   ├── GStoreView.swift            (G bundles — mock IAP)
│   └── Assets.xcassets/            (AppIcon, AccentColor placeholders)
└── WildLiveUITests/
    └── WildLiveUITests.swift       (title / start / navigation smoke tests)
```
