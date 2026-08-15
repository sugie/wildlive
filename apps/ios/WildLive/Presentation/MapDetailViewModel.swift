// WildLive — Presentation state for MapDetailView.
//
// The detail endpoint is what carries the spawn table, so this is the only
// place the client learns which animals a map can actually produce.

import Foundation
import Observation

@Observable
final class MapDetailViewModel {
    var map: GameMap?
    var isLoading = false
    var errorMessage: String?

    private let playerID: String
    private let mapID: String
    private let catalog: GameCatalogRepository

    init(playerID: String, mapID: String, catalog: GameCatalogRepository) {
        self.playerID = playerID
        self.mapID = mapID
        self.catalog = catalog
    }

    /// Rarest first: a player scanning this list wants to know what the
    /// prize is, not what the filler is.
    var spawnsByRarity: [MapSpawn] {
        (map?.spawns ?? []).sorted {
            if $0.species.rarity.sortOrder != $1.species.rarity.sortOrder {
                return $0.species.rarity.sortOrder > $1.species.rarity.sortOrder
            }
            return $0.spawnWeight > $1.spawnWeight
        }
    }

    /// The share of encounters each species represents, as the server's own
    /// spawn weights imply before any Hunter bias.
    func encounterShare(_ spawn: MapSpawn) -> Double {
        let total = (map?.spawns ?? []).reduce(0) { $0 + $1.spawnWeight }
        guard total > 0 else { return 0 }
        return Double(spawn.spawnWeight) / Double(total)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            map = try await catalog.mapDetail(playerID: playerID, mapID: mapID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
