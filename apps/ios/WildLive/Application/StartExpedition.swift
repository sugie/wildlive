// WildLive — Dispatch-an-expedition use case.
//
// Sits between the Presentation Layer (DispatchConfirmViewModel) and the
// Domain contracts. It owns one application-flow rule: after a successful
// dispatch the player's G has changed, so the caller is handed a refreshed
// overview along with the new expedition rather than having to know that
// dispatching costs money.
//
// Framework-free: no SwiftUI, no URLSession, no AppStore.

import Foundation

struct StartedExpedition: Equatable {
    let expedition: Expedition
    let overview: PlayerOverview
}

final class StartExpedition {
    private let expeditions: ExpeditionRepository
    private let profiles: PlayerProfileRepository

    init(expeditions: ExpeditionRepository, profiles: PlayerProfileRepository) {
        self.expeditions = expeditions
        self.profiles = profiles
    }

    /// - Parameter devInstantResolve: request the development-only
    ///   immediately-resolvable expedition. The server is the authority on
    ///   whether that is allowed and refuses in any environment that does
    ///   not permit it.
    func callAsFunction(
        playerID: String,
        mapID: String,
        hunterID: String,
        devInstantResolve: Bool = false
    ) async throws -> StartedExpedition {
        let expedition = try await expeditions.start(
            playerID: playerID,
            mapID: mapID,
            hunterID: hunterID,
            devInstantResolve: devInstantResolve
        )
        let overview = try await profiles.overview(playerID: playerID)

        return StartedExpedition(expedition: expedition, overview: overview)
    }
}
