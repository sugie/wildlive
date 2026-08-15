// WildLive — iOS client composition root.
//
// This is the ONLY place that wires concrete Data-layer implementations
// to the Domain protocols the Application layer depends on. Every screen
// / ViewModel / use case downstream receives its dependencies via
// constructor injection from here.
//
// Launch arguments (UI tests only):
//   --ui-tests-mock-api         → use MockPlayerRepository (no HTTP)
//   --ui-tests-fresh            → clear any persisted session on launch
//   --ui-tests-preregistered    → seed a fake persisted session so Home
//                                  is reachable without going through the
//                                  form

import SwiftUI

@main
struct WildLiveApp: App {
    @State private var appStore: AppStore
    private let registerPlayer: RegisterPlayer
    private let sessionRepository: PlayerSessionRepository

    init() {
        // -- Parse UI-test launch arguments -----------------------------
        let args = ProcessInfo.processInfo.arguments
        let useMock = args.contains("--ui-tests-mock-api")
        let clearFirst = args.contains("--ui-tests-fresh")
        let preregister = args.contains("--ui-tests-preregistered")

        // -- Data layer -------------------------------------------------
        let sessionRepo: PlayerSessionRepository = UserDefaultsPlayerSessionRepository()
        if clearFirst { sessionRepo.clear() }
        if preregister {
            sessionRepo.save(
                RegisteredPlayer(
                    playerId: "00000000-0000-0000-0000-0000000000ff",
                    displayName: "UITest",
                    zooId: "00000000-0000-0000-0000-0000000000fe",
                    createdAt: Date()
                )
            )
        }
        let playerRepo: PlayerRepository = useMock
            ? MockPlayerRepository()
            : LivePlayerRepository()

        // -- Application layer ------------------------------------------
        let useCase = RegisterPlayer(players: playerRepo, sessions: sessionRepo)

        // -- Presentation state (seed AppStore from any persisted session)
        let restored = sessionRepo.load()

        // Assign
        self.sessionRepository = sessionRepo
        self.registerPlayer = useCase
        _appStore = State(initialValue: AppStore(restoredSession: restored))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                registerPlayer: registerPlayer,
                sessionRepository: sessionRepository
            )
            .environment(appStore)
        }
    }
}
