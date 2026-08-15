// WildLive — Resolve-an-expedition use case.
//
// Thin by design: the outcome is entirely the server's to decide, and the
// server is idempotent, so this use case exists to give the Presentation
// Layer one named thing to call rather than a repository method that looks
// like a getter but changes the world.

import Foundation

final class ResolveExpedition {
    private let expeditions: ExpeditionRepository

    init(expeditions: ExpeditionRepository) {
        self.expeditions = expeditions
    }

    /// Safe to call more than once, and safe to retry after a failure —
    /// the first resolution is the one that counts.
    func callAsFunction(playerID: String, expeditionID: String) async throws -> Expedition {
        try await expeditions.resolve(playerID: playerID, expeditionID: expeditionID)
    }
}
