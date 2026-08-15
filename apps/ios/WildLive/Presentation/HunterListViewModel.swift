// WildLive — Presentation state for the Guild roster and the in-flow
// Hunter picker.
//
// One ViewModel serves both screens because they show the same list; the
// only difference is whether a Map was named. With a Map, the server
// quotes each Hunter's total cost and duration for it (`costing`), and the
// player can pick one. Without, it is a roster to browse.
//
// There is no "available" state to model: a Hunter is contracted per
// expedition and owned by no one (Game Master v0.3).

import Foundation
import Observation

@Observable
final class HunterListViewModel {
    var hunters: [Hunter] = []
    var isLoading = false
    var errorMessage: String?

    let mapID: String?
    private let catalog: GameCatalogRepository

    init(mapID: String?, catalog: GameCatalogRepository) {
        self.mapID = mapID
        self.catalog = catalog
    }

    var isPickingForExpedition: Bool { mapID != nil }

    /// Can the player afford this Hunter on this Map right now?
    func isAffordable(_ hunter: Hunter, balance: Int?) -> Bool {
        guard let balance, let cost = hunter.costing?.totalCostG else { return true }
        return balance >= cost
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            hunters = try await catalog.hunters(forMapID: mapID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
