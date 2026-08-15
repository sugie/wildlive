# WildLive iOS client

Native iOS client for WildLive.

- **Milestone 001 (Task 008, Version 0):** SwiftUI title screen only.
- **Milestone 002 (Task 009):** UI-only clickable prototype of the WildLive core loop — home dashboard, own Zoo, other players' Zoos, Guild, Hunter contract, Region dispatch, expedition resolution, capture/name/release, and G store — all backed by in-memory dummy data.
  - **Iteration 2 (Apple SwiftUI defaults):** rendered against stock SwiftUI — system background, `List` / `Form` / `Section` / `LabeledContent` / `NavigationLink(value:)`, `.buttonStyle(.borderedProminent)`, system SF Symbols on `Label`, system blue tint. No forced colour scheme, no custom gradients, no custom card modifier. Colour is used only where it carries information (rarity tier, region difficulty).
- **Milestone 002 (Task 010): first real vertical slice — player registration.** START on a fresh install now leads to a `RegistrationView` that calls `POST /api/players` on the local Laravel (see `docs/DEVELOPMENT.md`) and persists the returned player identifier in `UserDefaults`. Every other screen still runs against in-memory dummy data — only registration is real.
- **Milestone 002 (Task B — Task 016): iOS layered architecture refactor.** The Player-registration slice is reorganised into `App/` + `Presentation/` + `Application/` + `Domain/` + `Data/` folders with an explicit dependency direction (see [`ARCHITECTURE.md`](ARCHITECTURE.md)). Adds a `WildLiveTests` Unit Test target with 33 tests (Application use case, ViewModel, Data-layer HTTP via `URLProtocol` stubs, `UserDefaults` session repository, and machine-verified architecture-boundary rules). External API contract of `POST /api/players`, on-screen UI, and existing UI tests are all unchanged.
- **Milestone 003 (Task 018): the expedition loop is real.** Home, Maps, Hunters, dispatch, resolution, KEEP/RELEASE and My Zoo all read and write server state through the Laravel API and PostgreSQL. Nothing about the game is decided on the client: rarity, cost, duration, encounter and capture all come from Game Master v0.3 by way of the server. The prototype gameplay types (`MockGameService`, client-side `Hunter`/`Region`/`Expedition`) were deleted rather than kept alongside the real ones. Other Zoos, Visit Zoo and the G Store are still sample-data prototypes.

## Runtime dependencies (Task 010)

- The registration screen needs the local Laravel API up on `http://localhost:8000`. Start it with `docker compose up -d && docker compose exec app php artisan migrate` at the repository root. Without the API the app shows a "Network error" alert and stays on the form.
- The API base URL is read from `Info.plist → WildLiveAPIBaseURL` (default `http://localhost:8000/api`). Point at a different host by editing that key.
- ATS: `NSAppTransportSecurity → NSAllowsLocalNetworking` is `true` in `apps/ios/WildLive/Info.plist` so the app can call `http://localhost` from the Simulator without switching to HTTPS.
- Persistence: `PlayerSession` stores `playerId`, `displayName`, and `zooId` in `UserDefaults`. Reset with `xcrun simctl uninstall booted dev.wildlive.WildLive`.

## Play the expedition loop by hand

Canonical expedition durations are 10 minutes to 6 hours, so a human needs
the development shortcut to see the whole loop in one sitting.

```bash
# 1. Backend up, with schema and Game Master data.
docker compose up -d
docker compose exec app php artisan migrate --force
docker compose exec app php artisan db:seed --force

# 2. Build and install on a booted Simulator, wiping any old session.
cd apps/ios
xcodebuild -project WildLive.xcodeproj -scheme WildLive \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -derivedDataPath build build
xcrun simctl boot 'iPhone 17' ; open -a Simulator
xcrun simctl uninstall booted dev.wildlive.WildLive
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/WildLive.app
xcrun simctl launch booted dev.wildlive.WildLive
```

Then, in the Simulator:

1. **Start** → register a display name → **Home** shows 1000 G from the
   server.
2. **Send an Expedition** → **Kenyan Savanna** (the only map open at Zoo
   value 0; the rest show what they unlock at).
3. **Choose a Hunter** — the animal list above shows exactly what can be
   encountered there, rarest first.
4. Pick a Hunter. Each is priced and timed for this map; a "Biome match"
   badge marks the ones with an affinity bonus.
5. On **Dispatch**, scroll to **Developer → Resolve instantly** and turn it
   on. Without it the Hunter really is away for ten minutes.
6. **Start Expedition** → the expedition screen opens and resolves.
7. On a capture: **Keep — add to My Zoo**, give it a name, **Add to My
   Zoo**. Or **Release**, which returns nothing.
8. **My Zoo** lists the animal with its name, species and rarity — read
   back from PostgreSQL, not from screen state. Go Home and back to prove
   it.

Reset a player: `xcrun simctl uninstall booted dev.wildlive.WildLive`
clears the stored session, and the next launch registers a new one.

## Scope of Milestone 002

(Superseded for the expedition loop by Milestone 003; still accurate for
Other Zoos, Visit Zoo and the G Store.)

- The prototype screens run against `SampleData` — no network, no persistence, no API, no backend, no auth, no database.
- One `@Observable` `AppStore` holds the entire client-side state; it is destroyed on app termination (state does not persist across launches — that is intentional for the prototype).
- `MockGameService` mirrors the *shape* of the future server-authoritative service (contract, dispatch, resolve, keep/release) so real API code can slot in without touching any View.
- `MockGStoreService` mirrors the shape of a RevenueCat-backed IAP layer. **No real RevenueCat SDK is bundled.** All prices are placeholders for design review.
- ~~Expeditions use a prototype-scaled duration (8–60 seconds)~~ — superseded: expeditions now use the canonical Game Master durations, and a human plays the loop with the explicit development shortcut described above.

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

## Project layout (Task 016 — layered)

```
apps/ios/
├── README.md                       (this file)
├── ARCHITECTURE.md                 (layer rules + reference implementation)
├── WildLive.xcodeproj/             (three targets: WildLive, WildLiveTests, WildLiveUITests)
├── WildLive/
│   ├── Info.plist / Assets.xcassets
│   ├── App/                        (composition root + shared UI state)
│   │   ├── WildLiveApp.swift       (@main App — builds the DI graph)
│   │   ├── AppStore.swift          (@Observable UI/game-state container)
│   │   └── Route.swift             (NavigationStack destinations)
│   ├── Presentation/               (SwiftUI Views + ViewModels)
│   │   ├── RootView.swift, TitleView.swift, HomeView.swift, …
│   │   ├── RegistrationView.swift
│   │   ├── RegistrationViewModel.swift  (@Observable)
│   │   └── Theme.swift
│   ├── Application/                (use cases — framework-free)
│   │   ├── RegisterPlayer.swift
│   │   └── RegisterPlayerInput.swift
│   ├── Domain/                     (protocols + value types — framework-free)
│   │   ├── Game.swift              (Species / Animal / Hunter / Region / Player / …)
│   │   ├── RegisteredPlayer.swift
│   │   ├── PersistedSession.swift
│   │   ├── PlayerRepository.swift
│   │   └── PlayerSessionRepository.swift
│   └── Data/                       (HTTP / persistence — the only outward-facing layer)
│       ├── APIClient.swift
│       ├── PlayerAPIDTO.swift
│       ├── LivePlayerRepository.swift
│       ├── MockPlayerRepository.swift
│       ├── UserDefaultsPlayerSessionRepository.swift
│       ├── SampleData.swift, MockGameService.swift, MockGStoreService.swift
├── WildLiveTests/                  (Unit Test target — no Simulator UI)
│   ├── RegisterPlayerTests.swift
│   ├── RegistrationViewModelTests.swift
│   ├── LivePlayerRepositoryTests.swift        (URLProtocol stub)
│   ├── UserDefaultsPlayerSessionRepositoryTests.swift  (UserDefaults suite)
│   └── ArchitectureBoundaryTests.swift
└── WildLiveUITests/                (UI Test target — Simulator-based)
    └── WildLiveUITests.swift
```

## Adding a new feature — recommended order

See [`ARCHITECTURE.md`](ARCHITECTURE.md) §"Adding a new feature". Short version:

1. `Domain/`: add value type + repository protocol.
2. `Data/`: add `Mock*Repository`.
3. `Presentation/`: build `View` + `ViewModel` against the mock (works in SwiftUI Preview).
4. `Application/`: add a use case only when the flow encodes a rule.
5. `Data/`: add `Live*Repository` when the endpoint exists.
6. `App/WildLiveApp.swift`: wire the live impl behind the launch-arg guard.
7. UI test: gate real-API E2E on `/api/health` self-ping.
