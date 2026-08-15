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
    /// Which Hunter (if any) the current player currently has under contract.
    /// Basic hunters are always available in the Guild, but at most one
    /// contract-in-flight is exposed at a time to keep the flow simple.
    var contractedHunterId: String?

    // MARK: Services

    let gameService: MockGameService
    let storeService: MockGStoreService

    // MARK: Init

    init() {
        let sp = SampleData.species
        self.species = sp
        self.speciesById = Dictionary(uniqueKeysWithValues: sp.map { ($0.id, $0) })
        self.regions = SampleData.regions
        self.gBundles = SampleData.gBundles
        self.currentPlayer = SampleData.makeCurrentPlayer()
        self.otherPlayers = SampleData.makeOtherPlayers()
        self.hunters = SampleData.hunters

        // Services need references back to store state; wire them as
        // closures so we don't leak a strong retain cycle.
        let game = MockGameService()
        let store = MockGStoreService()
        self.gameService = game
        self.storeService = store
        game.bind(store: self)
        store.bind(store: self)
    }

    // MARK: Convenience derived state

    var myZooValue: Int {
        currentPlayer.zooValue(using: speciesById)
    }

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

    func push(_ route: Route) {
        navigationPath.append(route)
    }

    func popToHome() {
        navigationPath.removeAll()
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
