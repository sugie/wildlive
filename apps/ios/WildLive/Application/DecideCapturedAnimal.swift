// WildLive — KEEP / RELEASE use case.
//
// Owns the flow rule that both branches change what Home and My Zoo should
// show — KEEP adds an animal (and can unlock a map by raising Zoo value),
// RELEASE does not — so both return a refreshed overview alongside the
// decided expedition.
//
// It does NOT own the naming fallback: an empty name becomes the species
// name on the server, so the client and the server cannot disagree about
// what an animal ended up called.

import Foundation

struct DecidedCapture: Equatable {
    let expedition: Expedition
    let overview: PlayerOverview

    /// The animal now in the Zoo, or nil when it was released.
    var keptAnimal: ZooAnimal? { expedition.zooAnimal }
}

final class DecideCapturedAnimal {
    private let expeditions: ExpeditionRepository
    private let profiles: PlayerProfileRepository

    init(expeditions: ExpeditionRepository, profiles: PlayerProfileRepository) {
        self.expeditions = expeditions
        self.profiles = profiles
    }

    func keep(playerID: String, expeditionID: String, name: String) async throws -> DecidedCapture {
        let expedition = try await expeditions.keep(
            playerID: playerID,
            expeditionID: expeditionID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return DecidedCapture(
            expedition: expedition,
            overview: try await profiles.overview(playerID: playerID)
        )
    }

    func release(playerID: String, expeditionID: String) async throws -> DecidedCapture {
        let expedition = try await expeditions.release(playerID: playerID, expeditionID: expeditionID)
        return DecidedCapture(
            expedition: expedition,
            overview: try await profiles.overview(playerID: playerID)
        )
    }
}
