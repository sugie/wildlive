// WildLive — Central @Observable state container.
//
// AppStore holds only what genuinely spans screens:
//
//   - navigation and session state (has the player started, where are they,
//     who are they);
//   - the latest server snapshot of the player (`overview`), so Home, the
//     dispatch screen and My Zoo agree on the G balance without each
//     re-fetching it;
//   - the sample data the still-mocked prototype screens need.
//
// It does NOT hold game state. Maps, hunters, expeditions and zoo animals
// live on the server and are loaded by the ViewModel of the screen that
// needs them. When the expedition loop went live, the in-memory game state
// that used to live here (hunters, regions, expeditions, contracted hunter,
// MockGameService) was deleted rather than kept in parallel — two sources of
// truth for the same thing is exactly the bug this architecture exists to
// prevent.

import Foundation
import Observation

@Observable
final class AppStore {

    // MARK: UI / navigation state

    var hasStarted: Bool = false
    var navigationPath: [Route] = []
    var registeredSession: PersistedSession?

    /// The most recent server snapshot of the signed-in player. Written by
    /// whichever ViewModel last talked to the server; read by every screen
    /// that shows the G balance or Zoo totals.
    var overview: PlayerOverview?

    // MARK: Sample data for the remaining prototype screens

    let species: [Species]
    let speciesById: [String: Species]
    let gBundles: [GBundle]
    var otherPlayers: [Player]

    /// The mock player record behind Other Zoos and the G Store. Distinct
    /// from `overview`, which is the real one — Home, My Zoo and the
    /// expedition flow all use `overview`.
    var currentPlayer: Player

    let storeService: MockGStoreService

    // MARK: Init

    /// The composition root (WildLiveApp) loads any persisted session ahead
    /// of time and passes it here. AppStore does not know a
    /// PlayerSessionRepository exists.
    init(restoredSession: PersistedSession? = nil) {
        let sp = SampleData.species
        self.species = sp
        self.speciesById = Dictionary(uniqueKeysWithValues: sp.map { ($0.id, $0) })
        self.gBundles = SampleData.gBundles
        self.otherPlayers = SampleData.makeOtherPlayers()

        self.registeredSession = restoredSession
        self.currentPlayer = Self.makeCurrentPlayer(from: restoredSession)

        let store = MockGStoreService()
        self.storeService = store
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

    /// The id every gameplay call needs. Nil before registration.
    var playerID: String? { registeredSession?.playerId }

    var displayName: String {
        overview?.displayName ?? registeredSession?.displayName ?? currentPlayer.displayName
    }

    // MARK: Session helpers (thin — called after use cases succeed)

    /// Adopt the outcome of the RegisterPlayer use case. Called by the
    /// RegistrationViewModel after the use case returns successfully;
    /// AppStore does not perform the registration itself.
    func adoptRegistration(_ registered: RegisteredPlayer) {
        registeredSession = PersistedSession(
            playerId: registered.playerId,
            displayName: registered.displayName,
            zooId: registered.zooId
        )
        currentPlayer = Player(
            id: registered.playerId,
            displayName: registered.displayName,
            gBalance: currentPlayer.gBalance,
            animals: []
        )
        overview = nil
    }

    /// Adopt a fresh server snapshot. Every gameplay ViewModel calls this
    /// after an action that could have changed the balance or the Zoo.
    func apply(_ snapshot: PlayerOverview) {
        overview = snapshot
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
        overview = nil
        currentPlayer = Self.makeCurrentPlayer(from: nil)
        hasStarted = false
        navigationPath = []
    }

    func push(_ route: Route) { navigationPath.append(route) }
    func popToHome() { navigationPath.removeAll() }

    /// Replace the whole stack — used after a capture decision, so Back
    /// from My Zoo goes Home rather than into a settled expedition.
    func resetPath(to routes: [Route]) { navigationPath = routes }

    // MARK: Lookups (prototype screens only)

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
