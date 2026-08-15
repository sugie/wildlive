// WildLive — Client-side stand-in for the future game service.
//
// This class deliberately mirrors the *shape* of a server-authoritative
// service: contracts, dispatches, and captures all go through methods that
// return a Result and mutate AppStore state atomically. When the real API
// arrives, only this file changes; screens keep calling the same methods.
//
// This is NOT a game engine. It exists to make the UI clickable.

import Foundation

final class MockGameService {

    // MARK: Errors

    enum GameError: Error, LocalizedError {
        case insufficientFunds(required: Int, have: Int)
        case hunterUnavailable
        case alreadyContracted
        case unknownHunter
        case unknownRegion
        case unknownExpedition
        case notReadyToResolve
        case wrongExpeditionState

        var errorDescription: String? {
            switch self {
            case .insufficientFunds(let required, let have):
                return "Not enough G. Need \(required), have \(have)."
            case .hunterUnavailable:      return "That Hunter is not available right now."
            case .alreadyContracted:      return "You already have a Hunter under contract."
            case .unknownHunter:          return "Hunter not found."
            case .unknownRegion:          return "Region not found."
            case .unknownExpedition:      return "Expedition not found."
            case .notReadyToResolve:      return "This expedition has not finished yet."
            case .wrongExpeditionState:   return "That expedition can't be handled here."
            }
        }
    }

    // MARK: Store binding

    private weak var store: AppStore?
    func bind(store: AppStore) { self.store = store }

    // MARK: Contract a Hunter

    func contract(hunterId: String) -> Result<Void, GameError> {
        guard let store else { return .failure(.unknownHunter) }
        guard store.contractedHunterId == nil else { return .failure(.alreadyContracted) }
        guard let idx = store.hunters.firstIndex(where: { $0.id == hunterId }) else {
            return .failure(.unknownHunter)
        }
        let hunter = store.hunters[idx]
        guard hunter.available else { return .failure(.hunterUnavailable) }
        guard store.currentPlayer.gBalance >= hunter.contractCostG else {
            return .failure(.insufficientFunds(required: hunter.contractCostG, have: store.currentPlayer.gBalance))
        }

        store.currentPlayer.gBalance -= hunter.contractCostG
        // Non-basic hunters block re-contract by others while under contract.
        if hunter.tier != .basic {
            store.hunters[idx].available = false
        }
        store.contractedHunterId = hunter.id
        return .success(())
    }

    func releaseContract() {
        guard let store else { return }
        if let id = store.contractedHunterId,
           let idx = store.hunters.firstIndex(where: { $0.id == id }) {
            // Only non-basic hunters were marked unavailable at contract time.
            if store.hunters[idx].tier != .basic {
                store.hunters[idx].available = true
            }
        }
        store.contractedHunterId = nil
    }

    // MARK: Dispatch

    func dispatch(hunterId: String, regionId: String) -> Result<Expedition, GameError> {
        guard let store else { return .failure(.unknownHunter) }
        guard let hunter = store.hunter(hunterId) else { return .failure(.unknownHunter) }
        guard let region = store.region(regionId) else { return .failure(.unknownRegion) }
        guard store.contractedHunterId == hunter.id else { return .failure(.hunterUnavailable) }

        let now = Date()
        let expedition = Expedition(
            id: UUID(),
            hunterId: hunter.id,
            regionId: region.id,
            startedAt: now,
            endsAt: now.addingTimeInterval(region.simulatedDurationSeconds),
            resolvedAt: nil,
            state: .inProgress,
            resultingAnimalId: nil,
            handledDecision: nil
        )
        store.expeditions.insert(expedition, at: 0)
        return .success(expedition)
    }

    // MARK: Resolve (idempotent)

    /// Resolve an expedition whose end time has passed. Safe to call more
    /// than once — the second call is a no-op that returns the already-set
    /// state. Real server enforces this with a DB transition; the mock does
    /// it in-memory.
    @discardableResult
    func resolve(expeditionId: UUID) -> Result<Expedition, GameError> {
        guard let store else { return .failure(.unknownExpedition) }
        guard let idx = store.expeditions.firstIndex(where: { $0.id == expeditionId }) else {
            return .failure(.unknownExpedition)
        }
        var exp = store.expeditions[idx]
        if exp.state == .captured || exp.state == .noCapture || exp.state == .handled {
            return .success(exp) // idempotent
        }
        guard Date() >= exp.endsAt else { return .failure(.notReadyToResolve) }

        // Server-authoritative in real life. Here: deterministic-ish outcome
        // driven by hunter skill vs region difficulty, plus a small random.
        guard let hunter = store.hunter(exp.hunterId),
              let region = store.region(exp.regionId) else {
            return .failure(.unknownRegion)
        }

        let captured = rollCapture(skill: hunter.skill, difficulty: region.difficulty)
        exp.resolvedAt = Date()

        if captured {
            // Pick a species from the region's pool, weighted by inverse rarity.
            let species = pickSpecies(from: region.speciesPool, hunter: hunter, store: store)
            let trait = rollTrait(hunterTier: hunter.tier)
            let animal = Animal(
                id: UUID(),
                speciesId: species.id,
                nickname: nil,
                trait: trait,
                capturedAt: Date(),
                capturedFromRegionId: region.id,
                capturedByHunterId: hunter.id
            )
            exp.resultingAnimalId = animal.id
            exp.state = .captured
            // Animals are *pending* until the player names or releases them.
            // We stash them on the current player only after they choose "keep".
            // Store as a side-cache so the capture screen can look them up.
            pendingAnimals[animal.id] = animal
        } else {
            exp.state = .noCapture
        }

        store.expeditions[idx] = exp
        return .success(exp)
    }

    // MARK: Handle a capture (keep + name, or release)

    private var pendingAnimals: [UUID: Animal] = [:]

    func pendingAnimal(for expeditionId: UUID) -> Animal? {
        guard let store,
              let exp = store.expedition(expeditionId),
              let animalId = exp.resultingAnimalId else { return nil }
        return pendingAnimals[animalId]
    }

    func keepInZoo(expeditionId: UUID, nickname: String?) -> Result<Void, GameError> {
        guard let store else { return .failure(.unknownExpedition) }
        guard let idx = store.expeditions.firstIndex(where: { $0.id == expeditionId }) else {
            return .failure(.unknownExpedition)
        }
        var exp = store.expeditions[idx]
        guard exp.state == .captured, let animalId = exp.resultingAnimalId,
              var animal = pendingAnimals[animalId] else {
            return .failure(.wrongExpeditionState)
        }

        let trimmed = nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
        animal.nickname = (trimmed?.isEmpty == false) ? trimmed : nil
        store.currentPlayer.animals.insert(animal, at: 0)
        pendingAnimals.removeValue(forKey: animalId)
        exp.handledDecision = .keptInZoo
        exp.state = .handled
        store.expeditions[idx] = exp
        return .success(())
    }

    func release(expeditionId: UUID) -> Result<Void, GameError> {
        guard let store else { return .failure(.unknownExpedition) }
        guard let idx = store.expeditions.firstIndex(where: { $0.id == expeditionId }) else {
            return .failure(.unknownExpedition)
        }
        var exp = store.expeditions[idx]
        guard exp.state == .captured, let animalId = exp.resultingAnimalId else {
            return .failure(.wrongExpeditionState)
        }
        pendingAnimals.removeValue(forKey: animalId)
        exp.handledDecision = .released
        exp.state = .handled
        store.expeditions[idx] = exp
        return .success(())
    }

    // MARK: Resolution helpers (mock RNG, hidden inside the service)

    private func rollCapture(skill: Int, difficulty: Region.Difficulty) -> Bool {
        let target: Double
        switch difficulty {
        case .easy:    target = 90
        case .medium:  target = 70
        case .high:    target = 45
        case .extreme: target = 25
        }
        let successChance = min(0.95, max(0.05, Double(skill) / target))
        return Double.random(in: 0...1) < successChance
    }

    private func pickSpecies(from pool: [String], hunter: Hunter, store: AppStore) -> Species {
        // Higher-tier hunters bias toward rarer species from the pool.
        let candidates = pool.compactMap { store.speciesById[$0] }
        guard !candidates.isEmpty else { return SampleData.species[0] }
        let weights = candidates.map { sp -> Double in
            switch sp.rarity {
            case .common:    return hunter.tier == .basic ? 4.0 : 2.0
            case .uncommon:  return 3.0
            case .rare:      return hunter.tier == .basic ? 0.5 : 2.0
            case .epic:      return hunter.tier == .basic ? 0.1 : 1.2
            case .legendary: return hunter.tier == .legendary ? 0.8 : 0.2
            }
        }
        let total = weights.reduce(0, +)
        var draw = Double.random(in: 0..<total)
        for (i, w) in weights.enumerated() {
            if draw < w { return candidates[i] }
            draw -= w
        }
        return candidates.last!
    }

    private func rollTrait(hunterTier: HunterTier) -> IndividualTrait {
        // Very small chance of a rare individual trait; legendary hunters
        // bias upward slightly.
        let base: Double = hunterTier == .legendary ? 0.20 :
                           hunterTier == .elite     ? 0.12 :
                           hunterTier == .advanced  ? 0.06 : 0.03
        guard Double.random(in: 0...1) < base else { return .none }
        let traits: [IndividualTrait] = [.exceptionalSize, .exceptionalHorns, .melanistic, .leucistic, .albino]
        return traits.randomElement() ?? .none
    }
}
