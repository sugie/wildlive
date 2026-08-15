# iOS Architecture

The WildLive iOS client is organised into four folders under
`apps/ios/WildLive/`, each mapping to one architectural layer plus a
composition-root folder. The Player registration slice is the reference
implementation; every subsequent feature is expected to follow the same
shape.

## Layers

```
apps/ios/WildLive/
├── App/            ← composition root + shared UI-state container
├── Presentation/   ← SwiftUI Views + per-screen ViewModels
├── Application/    ← use cases  (framework-free)
├── Domain/         ← protocols + value types  (framework-free)
├── Data/           ← APIClient, DTOs, repository implementations,
│                     UserDefaults, mocks
└── Info.plist / Assets.xcassets
```

## Rules by layer

### `App/` — Composition root

**Purpose.** Build the object graph on launch. Choose Live vs Mock
implementations (from UI-test launch args). Own the `AppStore`
`@Observable` state container that mocked screens still read from
during the UI-first phase.

- **May**: import `SwiftUI`; instantiate `Live*` and `Mock*`
  implementations; read Info.plist; call the Domain protocols; hold the
  `AppStore` `@State`.
- **Must NOT**: contain any business rule that could live in the
  Application layer.

### `Presentation/` — SwiftUI Views + ViewModels

**Purpose.** Render pixels, handle input, expose loading / error state.

- **May**: import `SwiftUI` and `Observation`; hold `@State`,
  `@Environment`, `NavigationPath`; talk to a use case via a ViewModel;
  format values for display.
- **Must NOT**: touch `URLSession`, `UserDefaults`, `APIClient`, or any
  Data-layer type; open a DB / HTTP connection; embed business rules;
  import Application-internal types beyond what a ViewModel receives
  through its constructor.
- **ViewModel policy**: introduce a ViewModel for a screen only when
  that screen has real state (loading, error, submission). All-mock
  screens can bind directly to `AppStore` — do not create ceremonial
  ViewModels that only forward.

### `Application/` — Use cases

**Purpose.** One class per user-intent operation. Owns
application-flow rules (order of repository calls, transaction
boundaries, post-success side effects).

- **May**: import `Foundation`; depend on Domain protocols; run
  `async` code; propagate errors.
- **Must NOT**: import `SwiftUI`; reference `URLSession`,
  `UserDefaults`, `APIClient`, `AppStore`, Views, ViewModels, or any
  Data-layer concrete type.
- **Do not create** a use case whose body is one line delegating to a
  single repository call — call the repository directly from the
  ViewModel in that case. Use cases justify their existence when they
  encode a rule (transactions, ordering, invariants).

### `Domain/` — Protocols + value types

**Purpose.** The seam between Application and Data. Small, stable,
framework-free.

- **May**: import `Foundation`; declare `struct` value types and
  `protocol` contracts.
- **Must NOT**: import `SwiftUI`; reference `URLSession`,
  `UserDefaults`, Eloquent-shaped types, DTOs, or any concrete Data
  implementation.
- **Do not create** entities / value objects / mappers speculatively.
  `RegisteredPlayer` and `PersistedSession` exist because the use case
  needs them; grow the folder only when a real caller needs a real
  type.

### `Data/` — Repository implementations + APIClient + DTOs + mocks

**Purpose.** The only place the outside world (HTTP, disk, cache)
touches this codebase.

- **May**: import `Foundation`; call `URLSession`, `UserDefaults`,
  `APIClient`; declare `Codable` DTOs; provide `Live*` and `Mock*`
  implementations of Domain protocols.
- **Must NOT**: import `SwiftUI`; refer to `AppStore`, Views,
  ViewModels, or use cases.
- **Naming**: `Live*Repository` for the real implementation, `Mock*` /
  `Fake*` for previews and UI tests. DTOs get an `APIDTO` or `*DTO`
  suffix so they never leak into Domain by mistake.

## Dependency direction

```
Presentation                     ── SwiftUI, Observation
     │
     ▼   (constructor injection from App/composition root)
Application  (use case)          ── Foundation only
     │
     ▼   (constructor injection)
Domain  (protocol + value)       ── Foundation only
     ▲
     │   (implements)
Data                              ── Foundation, URLSession, UserDefaults
     │
     ▼   (uses)
APIClient / UserDefaults / …
```

Compile-time enforced by `ArchitectureBoundaryTests` in
`WildLiveTests`: the test walks the source tree with `FileManager` and
asserts each layer folder is free of the forbidden tokens listed above.
Comments and doc strings are stripped before searching so
documentation is allowed to mention the forbidden names.

## Reference implementation — Player Registration

Real dependency chain, top to bottom:

```
RegistrationView
    │  binds to
    ▼
RegistrationViewModel  (Presentation)
    │  calls
    ▼
RegisterPlayer  (Application, __invoke)
    │            └────────────────────────────┐
    │                                         │
    ▼                                         ▼
PlayerRepository  (Domain protocol)   PlayerSessionRepository  (Domain protocol)
    ▲                                         ▲
    │  implements                             │  implements
    │                                         │
LivePlayerRepository  (Data)          UserDefaultsPlayerSessionRepository  (Data)
    │  uses
    ▼
APIClient  (Data)  ──►  Laravel  POST /api/players
```

On success, `RegistrationViewModel` invokes an `onSuccess` closure
supplied by `RootView` that calls `AppStore.adoptRegistration(_:)` to
update the UI-state container. The ViewModel therefore does not depend
on the concrete `AppStore` type — only on the closure.

## Mock flow (UI Preview / UI Test / Simulator without Laravel)

- `MockPlayerRepository` (Data) — instant success, configurable failure.
  Selected by `--ui-tests-mock-api` at composition root.
- `UserDefaultsPlayerSessionRepository(defaults: UserDefaults(suiteName:))`
  — used in `UserDefaultsPlayerSessionRepositoryTests` with an
  ephemeral suite so the real `UserDefaults.standard` is never touched.
- `--ui-tests-fresh` clears any persisted session on launch.
- `--ui-tests-preregistered` seeds a fake session so post-registration
  screens are directly reachable in UI tests.

## Adding a new feature (recommended order)

Follow the UI-first WildLive policy: pixels first, real backend last.

1. **Domain**: add the value type(s) + repository protocol(s).
2. **Data**: add a `Mock*` implementation of the protocol; unit-test the
   contract of the mock itself if useful.
3. **Presentation**: build the `View` + `ViewModel` against the mock;
   ship SwiftUI previews.
4. **Application**: introduce a use case when the flow encodes a rule
   (transaction, ordering, side effect). Otherwise wire the ViewModel
   directly to the repository.
5. **Data (Live)**: implement `Live*Repository` against `APIClient`
   once the Laravel endpoint exists; add DTOs; add
   `LivePlayerRepositoryTests`-style `URLProtocol`-stub tests.
6. **App composition root**: swap the mock for the live implementation
   behind the launch-arg guard.
7. **UI tests**: gate a real-API end-to-end test with a
   `/api/health` self-ping (so CI without Laravel skips it, not fails).

## Testing surfaces

| Layer         | Test target       | Kind                                     |
|---------------|-------------------|-------------------------------------------|
| Application   | `WildLiveTests`   | In-memory fake repositories               |
| Presentation  | `WildLiveTests`   | Fake repositories + fake use cases        |
| Data (HTTP)   | `WildLiveTests`   | `URLProtocol` stub, no real network       |
| Data (UDef.)  | `WildLiveTests`   | `UserDefaults(suiteName:)` per test       |
| Boundaries    | `WildLiveTests`   | `FileManager` walk of layer folders       |
| Live end-to-end | `WildLiveUITests` | Simulator → real Laravel → real PostgreSQL |

Third-party mocking / architecture libraries are not used.
