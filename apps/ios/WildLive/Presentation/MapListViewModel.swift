// WildLive — Presentation state for MapListView.
//
// Maps come from the server already carrying their unlock state, because
// whether a map is open depends on the player's Zoo value and that is not
// the client's to decide.

import Foundation
import Observation

@Observable
final class MapListViewModel {
    var maps: [GameMap] = []
    var isLoading = false
    var errorMessage: String?

    private let playerID: String
    private let catalog: GameCatalogRepository

    init(playerID: String, catalog: GameCatalogRepository) {
        self.playerID = playerID
        self.catalog = catalog
    }

    var unlockedMaps: [GameMap] { maps.filter(\.unlocked) }
    var lockedMaps: [GameMap] { maps.filter { !$0.unlocked } }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            maps = try await catalog.maps(playerID: playerID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
