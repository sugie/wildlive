// WildLive — iOS client composition root.
//
// This is the ONLY place that wires concrete Data-layer implementations to
// the Domain protocols the Application layer depends on. Every screen,
// ViewModel and use case downstream receives its dependencies by
// constructor injection from here.
//
// Launch arguments (UI tests only):
//   --ui-tests-mock-api             → in-memory repositories, no HTTP at all
//   --ui-tests-fresh                → clear any persisted session on launch
//   --ui-tests-preregistered        → seed a fake session so Home is
//                                     reachable without the form
//   --ui-tests-instant-expeditions  → start the dispatch screen's developer
//                                     toggle switched on, so an E2E test does
//                                     not have to wait out a real expedition
//
// The last one only pre-fills a request. The server independently decides
// whether instant resolution is allowed and refuses outside local/testing,
// so no launch argument can turn into a production shortcut.

import SwiftUI

@main
struct WildLiveApp: App {
    @State private var appStore: AppStore
    private let registerPlayer: RegisterPlayer
    private let sessionRepository: PlayerSessionRepository
    private let game: GameDependencies

    init() {
        // -- Parse UI-test launch arguments -----------------------------
        let args = ProcessInfo.processInfo.arguments
        let useMock = args.contains("--ui-tests-mock-api")
        let clearFirst = args.contains("--ui-tests-fresh")
        let preregister = args.contains("--ui-tests-preregistered")
        let instantExpeditions = args.contains("--ui-tests-instant-expeditions")

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

        let gameDependencies: GameDependencies = useMock
            ? .mocked(devInstantResolveDefault: instantExpeditions)
            : .live(devInstantResolveDefault: instantExpeditions)

        // -- Application layer ------------------------------------------
        let useCase = RegisterPlayer(players: playerRepo, sessions: sessionRepo)

        // -- Presentation state (seed AppStore from any persisted session)
        let restored = sessionRepo.load()

        // Assign
        self.sessionRepository = sessionRepo
        self.registerPlayer = useCase
        self.game = gameDependencies
        _appStore = State(initialValue: AppStore(restoredSession: restored))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                registerPlayer: registerPlayer,
                sessionRepository: sessionRepository,
                game: game
            )
            .environment(appStore)
        }
    }
}
