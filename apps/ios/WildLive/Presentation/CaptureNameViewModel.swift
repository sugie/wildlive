// WildLive — Presentation state for naming a captured animal.
//
// The name is optional here and stays optional all the way to the server,
// which substitutes the species name when it is blank. Doing the fallback
// in one place means the client and the server can never disagree about
// what an animal ended up called.

import Foundation
import Observation

@Observable
final class CaptureNameViewModel {
    var name: String = ""
    var expedition: Expedition?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?

    private let playerID: String
    private let expeditionID: String
    private let repository: ExpeditionRepository
    private let decideCapture: DecideCapturedAnimal
    private let onKept: (ZooAnimal?, PlayerOverview) -> Void

    init(
        playerID: String,
        expeditionID: String,
        repository: ExpeditionRepository,
        decideCapture: DecideCapturedAnimal,
        onKept: @escaping (ZooAnimal?, PlayerOverview) -> Void
    ) {
        self.playerID = playerID
        self.expeditionID = expeditionID
        self.repository = repository
        self.decideCapture = decideCapture
        self.onKept = onKept
    }

    var species: AnimalSpecies? { expedition?.resolution?.encounteredSpecies }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What the animal will actually be called, previewed live so a player
    /// who leaves the field blank is not surprised.
    var effectiveName: String {
        trimmedName.isEmpty ? (species?.nameEN ?? "Unnamed") : trimmedName
    }

    var canSave: Bool { !isSaving && expedition?.awaitsDecision == true }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            expedition = try await repository.get(playerID: playerID, expeditionID: expeditionID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func keep() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let decided = try await decideCapture.keep(
                playerID: playerID,
                expeditionID: expeditionID,
                name: trimmedName
            )
            expedition = decided.expedition
            errorMessage = nil
            onKept(decided.keptAnimal, decided.overview)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
