// WildLive — Domain contract for player-registration persistence.
//
// This is the only seam the Application Layer knows about for creating a
// player. The Data Layer provides the concrete implementation
// (LivePlayerRepository against the Laravel API, MockPlayerRepository for
// tests and previews).
//
// Framework-free: no SwiftUI, no URLSession, no UserDefaults.

import Foundation

protocol PlayerRepository: AnyObject {
    /// Register a new player with the given display name.
    ///
    /// Throws an error on any failure (transport, non-2xx, decoding). The
    /// specific error type is a Data-layer detail; the Application Layer
    /// only cares that "an error happened".
    func register(displayName: String) async throws -> RegisteredPlayer
}
