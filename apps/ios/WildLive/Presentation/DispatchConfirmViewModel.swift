// WildLive — Presentation state for DispatchConfirmView.
//
// The last screen before G is spent. It loads the map and the chosen
// Hunter so the quote shown is the server's own arithmetic, then calls the
// StartExpedition use case.
//
// `devInstantResolve` is the client's request for the development-only
// shortcut. The server decides whether to grant it and refuses outright in
// any environment that does not allow it, so this flag can never turn into
// a production shortcut by accident.

import Foundation
import Observation

@Observable
final class DispatchConfirmViewModel {
    var map: GameMap?
    var hunter: Hunter?
    var isLoading = false
    var isDispatching = false
    var errorMessage: String?

    /// Developer switch, DEBUG-only in the UI. Default off: a normal run
    /// uses the canonical Game Master duration.
    var devInstantResolve: Bool

    private let playerID: String
    private let mapID: String
    private let hunterID: String
    private let catalog: GameCatalogRepository
    private let startExpedition: StartExpedition
    private let onDispatched: (Expedition, PlayerOverview) -> Void

    init(
        playerID: String,
        mapID: String,
        hunterID: String,
        catalog: GameCatalogRepository,
        startExpedition: StartExpedition,
        devInstantResolveDefault: Bool = false,
        onDispatched: @escaping (Expedition, PlayerOverview) -> Void
    ) {
        self.playerID = playerID
        self.mapID = mapID
        self.hunterID = hunterID
        self.catalog = catalog
        self.startExpedition = startExpedition
        self.devInstantResolve = devInstantResolveDefault
        self.onDispatched = onDispatched
    }

    var totalCostG: Int? {
        guard let map, let hunter else { return nil }
        return hunter.costing?.totalCostG ?? (map.baseCostG + hunter.contractCostG)
    }

    var durationMinutes: Int? {
        guard let map, let hunter else { return nil }
        return hunter.costing?.durationMinutes ?? map.expeditionMinutes
    }

    var hasBiomeAffinity: Bool { hunter?.costing?.biomeAffinity ?? false }

    func canAfford(balance: Int?) -> Bool {
        guard let balance, let cost = totalCostG else { return true }
        return balance >= cost
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let mapTask = catalog.mapDetail(playerID: playerID, mapID: mapID)
            async let huntersTask = catalog.hunters(forMapID: mapID)
            map = try await mapTask
            hunter = try await huntersTask.first { $0.id == hunterID }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dispatch() async {
        guard !isDispatching else { return }
        isDispatching = true
        defer { isDispatching = false }
        do {
            let started = try await startExpedition(
                playerID: playerID,
                mapID: mapID,
                hunterID: hunterID,
                devInstantResolve: devInstantResolve
            )
            errorMessage = nil
            onDispatched(started.expedition, started.overview)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
