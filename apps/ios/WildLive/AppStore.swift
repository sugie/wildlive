// WildLive — Single shared state container for the UI prototype.
//
// Everything the UI needs lives on one @Observable object. This is
// deliberate: while the server is not built yet, we keep the client's
// mental model small and inspectable. When the real API arrives, screens
// still bind to the same store — only the service layer changes.

import Foundation
import Observation

@Observable
final class AppStore {

    // MARK: Session

    var hasStarted: Bool = false
    var navigationPath: [Route] = []
    /// Non-nil when the current player has been registered with the server
    /// (persisted via `PlayerSession`). Nil on first launch — the UI shows
    /// the registration screen after START in that case.
    var registeredSession: PersistedSession?

    // MARK: Master data (immutable during a session)

    let species: [Species]
    let speciesById: [String: Species]
    let regions: [Region]
    let gBundles: [GBundle]

    // MARK: Mutable game state (client-side dummy)

    var currentPlayer: Player
    var otherPlayers: [Player]
    var hunters: [Hunter]
    var expeditions: [Expedition] = []
    var contractedHunterId: String?

    // MARK: Services

    let gameService: MockGameService
    let storeService: MockGStoreService
    let session: PlayerSession
    let registrationService: PlayerRegistrationServiceProtocol

    // MARK: Init

    init(
        session: PlayerSession = PlayerSession(),
        registrationService: PlayerRegistrationServiceProtocol? = nil
    ) {
        let sp = SampleData.species
        self.species = sp
        self.speciesById = Dictionary(uniqueKeysWithValues: sp.map { ($0.id, $0) })
        self.regions = SampleData.regions
        self.gBundles = SampleData.gBundles
        self.otherPlayers = SampleData.makeOtherPlayers()
        self.hunters = SampleData.hunters

        self.session = session
        self.registrationService = registrationService ?? LivePlayerRegistrationService()

        let restored = session.restore()
        self.registeredSession = restored
        self.currentPlayer = Self.makeCurrentPlayer(from: restored)

        let game = MockGameService()
        let store = MockGStoreService()
        self.gameService = game
        self.storeService = store
        game.bind(store: self)
        store.bind(store: self)
    }

    /// Seed the in-memory current player. When a real registration exists we
    /// keep the id + display name from the server and layer the sample
    /// starter animals + starter G balance on top (those are still dummy
    /// until server-side domain endpoints land in a later milestone).
    private static func makeCurrentPlayer(from restored: PersistedSession?) -> Player {
        var seed = SampleData.makeCurrentPlayer()
        if let restored {
            seed = Player(
                id: restored.playerId,
                displayName: restored.displayName,
                gBalance: seed.gBalance,
                animals: [] // fresh registrations start with an empty Zoo
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

    // MARK: Session actions

    func start() {
        hasStarted = true
        navigationPath = []
    }

    func returnToTitle() {
        hasStarted = false
        navigationPath = []
    }

    func signOutAndForgetPlayer() {
        session.clear()
        registeredSession = nil
        currentPlayer = Self.makeCurrentPlayer(from: nil)
        expeditions = []
        contractedHunterId = nil
        hasStarted = false
        navigationPath = []
    }

    func push(_ route: Route) { navigationPath.append(route) }
    func popToHome() { navigationPath.removeAll() }

    // MARK: Registration

    /// First-time registration. Persists the returned identifier on success
    /// and transitions to Home; the caller (RegistrationView) surfaces
    /// errors.
    func register(displayName: String) async -> Result<RegisteredPlayer, APIError> {
        let result = await registrationService.register(displayName: displayName)
        if case .success(let registered) = result {
            await MainActor.run {
                session.persist(registered)
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
            }
        }
        return result
    }

    // MARK: Convenience lookups

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
