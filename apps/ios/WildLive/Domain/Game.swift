// WildLive — Domain types for the UI prototype.
//
// Client-side dummy models. The real game is server-authoritative (see
// docs/GAME_DESIGN.md and docs/adr/0002-game-system-foundation.md); nothing
// here is authoritative. These types mirror the server's *shape* just enough
// to build screens against.

import Foundation

// MARK: - Rarity

enum SpeciesRarity: String, CaseIterable, Codable, Hashable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var label: String {
        switch self {
        case .common:    return "Common"
        case .uncommon:  return "Uncommon"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var baseZooValue: Int {
        switch self {
        case .common:    return 10
        case .uncommon:  return 25
        case .rare:      return 80
        case .epic:      return 220
        case .legendary: return 600
        }
    }
}

enum IndividualTrait: String, CaseIterable, Codable, Hashable {
    case none
    case leucistic
    case albino
    case melanistic
    case exceptionalSize
    case exceptionalHorns

    var label: String {
        switch self {
        case .none:              return "Ordinary"
        case .leucistic:         return "Leucistic"
        case .albino:            return "Albino"
        case .melanistic:        return "Melanistic"
        case .exceptionalSize:   return "Exceptional size"
        case .exceptionalHorns:  return "Exceptional horns"
        }
    }

    var valueMultiplier: Double {
        switch self {
        case .none:              return 1.0
        case .exceptionalSize:   return 1.5
        case .exceptionalHorns:  return 1.6
        case .melanistic:        return 2.2
        case .leucistic:         return 3.0
        case .albino:            return 4.0
        }
    }
}

// MARK: - Species

struct Species: Identifiable, Hashable, Codable {
    let id: String              // stable slug, e.g. "asian_elephant"
    let commonName: String
    let scientificName: String
    let rarity: SpeciesRarity
    let habitatSummary: String
}

// MARK: - Animal (an individual captured Animal)

struct Animal: Identifiable, Hashable, Codable {
    let id: UUID
    let speciesId: String
    var nickname: String?           // set on capture; nil = unnamed
    let trait: IndividualTrait
    let capturedAt: Date
    let capturedFromRegionId: String?
    let capturedByHunterId: String?

    func zooValue(species: Species) -> Int {
        let base = Double(species.rarity.baseZooValue)
        return Int((base * trait.valueMultiplier).rounded())
    }
}

// MARK: - Hunter

enum HunterTier: String, CaseIterable, Codable, Hashable {
    case basic
    case advanced
    case elite
    case legendary

    var label: String {
        switch self {
        case .basic:     return "Basic"
        case .advanced:  return "Advanced"
        case .elite:     return "Elite"
        case .legendary: return "Legendary"
        }
    }
}

struct Hunter: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let tier: HunterTier
    let skill: Int              // 1..100
    let contractCostG: Int
    let bio: String
    var available: Bool         // false when someone else has contracted them
}

// MARK: - Region

struct Region: Identifiable, Hashable, Codable {
    enum Difficulty: String, CaseIterable, Codable, Hashable {
        case easy, medium, high, extreme

        var label: String {
            switch self {
            case .easy:    return "Easy"
            case .medium:  return "Medium"
            case .high:    return "High"
            case .extreme: return "Extreme"
            }
        }
    }

    let id: String
    let name: String
    let subtitle: String
    let difficulty: Difficulty
    // Real duration on the server would be ~10 min .. 24 h. This client-side
    // value is the *prototype-scaled* duration so a human can play the whole
    // loop inside the Simulator in a few seconds. Real timing lives on the
    // server.
    let simulatedDurationSeconds: TimeInterval
    let speciesPool: [String]   // Species.id candidates
    let flavor: String
}

// MARK: - Expedition

enum ExpeditionState: String, Codable, Hashable {
    case inProgress          // started_at set, ends_at in the future
    case awaitingResolution  // ends_at passed, not yet resolved
    case captured            // resolved, animal captured (see resultingAnimalId)
    case noCapture           // resolved, no capture
    case handled             // captured → user chose to keep or release
}

struct Expedition: Identifiable, Hashable, Codable {
    let id: UUID
    let hunterId: String
    let regionId: String
    let startedAt: Date
    let endsAt: Date
    var resolvedAt: Date?
    var state: ExpeditionState
    var resultingAnimalId: UUID?    // set only if captured
    var handledDecision: CaptureDecision?

    enum CaptureDecision: String, Codable, Hashable {
        case keptInZoo
        case released
    }

    var isReadyToResolve: Bool {
        Date() >= endsAt && (state == .inProgress || state == .awaitingResolution)
    }
}

// MARK: - Player + Zoo

struct Player: Identifiable, Hashable, Codable {
    let id: String
    var displayName: String
    var gBalance: Int
    var animals: [Animal]

    func zooValue(using speciesById: [String: Species]) -> Int {
        animals.reduce(0) { total, animal in
            guard let sp = speciesById[animal.speciesId] else { return total }
            return total + animal.zooValue(species: sp)
        }
    }

    var visitorsPerDay: Int {
        // Loosely: 1 visitor per 25 Zoo Value. Purely cosmetic in the prototype.
        let base = animals.count * 15
        return base
    }
}

// MARK: - G Store (RevenueCat-shaped, mock only)

struct GBundle: Identifiable, Hashable, Codable {
    let id: String              // product identifier (RC-shaped)
    let title: String
    let gAmount: Int
    let priceDisplay: String    // e.g. "¥160", "¥1,200"
    let bonusLabel: String?
}
