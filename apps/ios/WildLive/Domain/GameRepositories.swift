// WildLive — Domain contracts for the live game.
//
// These are the only seams the Application and Presentation layers know
// about. The Data layer supplies two implementations of each: a Live one
// that talks to the Laravel API, and a Mock one for SwiftUI previews, unit
// tests, and UI tests that must not depend on a running backend. The
// composition root picks.
//
// Framework-free: no SwiftUI, no URLSession, no UserDefaults.

import Foundation

/// Read access to the Game Master catalogue.
///
/// Maps are player-scoped because unlock state depends on the player's Zoo
/// value. Hunters are not: the Guild pool is shared and no player owns a
/// Hunter, so `hunters(forMapID:)` takes a map only to have the server
/// quote a cost and duration for it.
protocol GameCatalogRepository: AnyObject, Sendable {
    func maps(playerID: String) async throws -> [GameMap]
    func mapDetail(playerID: String, mapID: String) async throws -> GameMap
    func hunters(forMapID mapID: String?) async throws -> [Hunter]
}

/// The expedition lifecycle.
///
/// `resolve`, `keep` and `release` are idempotent on the server, so a
/// retry after a dropped connection is safe from here.
protocol ExpeditionRepository: AnyObject, Sendable {
    /// - Parameter devInstantResolve: ask the server for the
    ///   development-only immediately-resolvable expedition. The server
    ///   refuses unless its environment and config both allow it, so this
    ///   is a request, never a guarantee.
    func start(
        playerID: String,
        mapID: String,
        hunterID: String,
        devInstantResolve: Bool
    ) async throws -> Expedition

    func list(playerID: String) async throws -> [Expedition]

    /// Fetches one expedition. The server resolves it on the way out if it
    /// is due, so this doubles as "settle this if it is ready".
    func get(playerID: String, expeditionID: String) async throws -> Expedition

    func resolve(playerID: String, expeditionID: String) async throws -> Expedition
    func keep(playerID: String, expeditionID: String, name: String) async throws -> Expedition
    func release(playerID: String, expeditionID: String) async throws -> Expedition
}

/// The player's own snapshot and Zoo.
protocol PlayerProfileRepository: AnyObject, Sendable {
    func overview(playerID: String) async throws -> PlayerOverview
    func zoo(playerID: String) async throws -> ZooContents
}
