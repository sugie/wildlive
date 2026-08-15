// WildLive — Domain types for the remaining prototype screens.
//
// Client-side dummy models, kept for the screens that are still mocked:
// Other Zoos, Visit Zoo, Animal detail, and the G Store. Nothing here is
// authoritative.
//
// The gameplay types that used to live here — Hunter, Region, Expedition —
// were removed when the expedition loop went live. Their real, server-backed
// counterparts are in GameWorld.swift (Hunter, GameMap, Expedition,
// ZooAnimal), which is now the single definition of each of those concepts.

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
