// WildLive — Central @Observable state container for the mocked screens.
//
// AppStore is deliberately narrow: it holds UI-facing state (navigation,
// current-player snapshot, mock game state) and knows nothing about how
// the real player was registered or where the session is persisted. Those
// live in the Application / Data layers and are wired in from the
// composition root (WildLiveApp).
//
// Kept as a single class because every mocked screen still reads from it
// and the alternative — per-screen @Observable stores plus a coordinator —
// would be excessive for the current mock-heavy phase. The moment more
// screens go real (Guild, Zoo, …), each real feature will grow its own
// use case + ViewModel and only push the resulting snapshot into
// AppStore via a narrow apply-method.

import Foundation
import Observation

@Observable
final class AppStore {

    // MARK: UI / navigation state

    var hasStarted: Bool = false
    var navigationPath: [Route] = []
    var registeredSession: PersistedSession?

    // MARK: Master data (immutable during a session)

    let species: [Species]
    let speciesById: [String: Species]
    let regions: [Region]
    let gBundles: [GBundle]

    // MARK: Mocked game state

    var currentPlayer: Player
    var otherPlayers: [Player]
    var hunters: [Hunter]
    var expeditions: [Expedition] = []
    var contractedHunterId: String?

    // MARK: Mock services (game loop stays UI-only in this milestone)

    let gameService: MockGameService
    let storeService: MockGStoreService

    // MARK: Init

    /// The composition root (WildLiveApp) is responsible for loading any
    /// persisted session ahead of time and passing it here. AppStore does
    /// not know a PlayerSessionRepository exists.
    init(restoredSession: PersistedSession? = nil) {
        let sp = SampleData.species
        self.species = sp
        self.speciesById = Dictionary(uniqueKeysWithValues: sp.map { ($0.id, $0) })
        self.regions = SampleData.regions
        self.gBundles = SampleData.gBundles
        self.otherPlayers = SampleData.makeOtherPlayers()
        self.hunters = SampleData.hunters

        self.registeredSession = restoredSession
        self.currentPlayer = Self.makeCurrentPlayer(from: restoredSession)

        let game = MockGameService()
        let store = MockGStoreService()
        self.gameService = game
        self.storeService = store
        game.bind(store: self)
        store.bind(store: self)
    }

    private static func makeCurrentPlayer(from restored: PersistedSession?) -> Player {
        var seed = SampleData.makeCurrentPlayer()
        if let restored {
            seed = Player(
                id: restored.playerId,
                displayName: restored.displayName,
                gBalance: seed.gBalance,
                animals: []
            )
        }
        return seed
    }

    // MARK: Derived state

    var isRegistered: Bool { registeredSession != nil }

    var myZooValue: Int { currentPlayer.zooValue(using: speciesById) }

    var contractedHunter: Hunter? {
        guard let id = contractedHunterId else { return nil }
        return hunters.first { $0.id == id }
    }

    var ongoingExpeditions: [Expedition] {
        expeditions.filter { $0.state == .inProgress || $0.state == .awaitingResolution }
    }

    var unhandledCapturedExpeditions: [Expedition] {
        expeditions.filter { $0.state == .captured }
    }

    // MARK: Session helpers (thin — called after use cases succeed)

    /// Adopt the outcome of the RegisterPlayer use case. Called by the
    /// RegistrationViewModel after the use case returns successfully;
    /// AppStore does not perform the registration itself.
    func adoptRegistration(_ registered: RegisteredPlayer) {
        let session = PersistedSession(
            playerId: registered.playerId,
            displayName: registered.displayName,
            zooId: registered.zooId
        )
        registeredSession = session
        currentPlayer = Player(
            id: registered.playerId,
            displayName: registered.displayName,
            gBalance: currentPlayer.gBalance,
            animals: []
        )
    }

    // MARK: Session actions

    func start() {
        hasStarted = true
        navigationPath = []
    }

    func returnToTitle() {
        hasStarted = false
        navigationPath = []
    }

    /// Wipes in-memory session state only. Removing the persisted session
    /// itself is the composition root / caller's job.
    func forgetRegistrationInMemory() {
        registeredSession = nil
        currentPlayer = Self.makeCurrentPlayer(from: nil)
        expeditions = []
        contractedHunterId = nil
        hasStarted = false
        navigationPath = []
    }

    func push(_ route: Route) { navigationPath.append(route) }
    func popToHome() { navigationPath.removeAll() }

    // MARK: Lookups

    func hunter(_ id: String) -> Hunter? { hunters.first { $0.id == id } }
    func region(_ id: String) -> Region? { regions.first { $0.id == id } }
    func expedition(_ id: UUID) -> Expedition? { expeditions.first { $0.id == id } }
    func animal(_ id: UUID) -> Animal? {
        if let a = currentPlayer.animals.first(where: { $0.id == id }) { return a }
        for p in otherPlayers {
            if let a = p.animals.first(where: { $0.id == id }) { return a }
        }
        return nil
    }
    func player(_ id: String) -> Player? {
        if id == currentPlayer.id { return currentPlayer }
        return otherPlayers.first { $0.id == id }
    }
}
