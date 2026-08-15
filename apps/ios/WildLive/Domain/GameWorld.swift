// WildLive — Domain types for the live, server-authoritative game.
//
// These mirror what the Laravel API returns, which in turn comes from Game
// Master v0.3. Nothing here is computed on the client: rarity, cost,
// duration, capture chance and outcome are all decided on the server and
// arrive as values. The client's job is to show them.
//
// Framework-free: no SwiftUI, no URLSession, no UserDefaults. Wire-format
// decoding lives in the Data layer (GameAPIDTO.swift); these types are what
// the rest of the app sees.
//
// Distinct from the prototype types in Game.swift, which still back the
// remaining mocked screens (Other Zoos, G Store).

import Foundation

// MARK: - Rarity

/// One of the five Game Master rarity tiers.
///
/// Modelled as a struct rather than an enum because the tier list is master
/// data: a sixth tier would be a spreadsheet edit, and an enum would turn
/// that into a decoding failure on an old client.
struct Rarity: Identifiable, Hashable, Sendable {
    let id: String          // "rarity_common" … "rarity_legendary"
    let nameEN: String
    let nameJA: String
    let sortOrder: Int      // 1 Common … 5 Legendary
}

// MARK: - Species

struct AnimalSpecies: Identifiable, Hashable, Sendable {
    let id: String          // "animal_impala_001"
    let nameEN: String
    let nameJA: String
    let rarity: Rarity
    let baseZooValue: Int
    let captureDifficulty: Int
    let descriptionEN: String
}

// MARK: - Map

/// A species' placement on a map: how likely it is to be met there.
struct MapSpawn: Identifiable, Hashable, Sendable {
    var id: String { species.id }
    let species: AnimalSpecies
    let spawnWeight: Int
    let captureModifier: Int
}

struct GameMap: Identifiable, Hashable, Sendable {
    let id: String          // "map_kenyan_savanna_001"
    let nameEN: String
    let nameJA: String
    let region: String
    let biomeID: String
    let mapRole: String     // starter / general / specialist / long_expedition
    let difficulty: Int     // 1..5
    let riskLevel: Int
    /// Canonical Game Master duration. Never shortened by the client.
    let expeditionMinutes: Int
    let baseCostG: Int
    let recommendedHunterRank: Int
    let unlockRule: String  // "always" | "zoo_value"
    let unlockValue: Int
    let unlocked: Bool
    let descriptionEN: String
    /// Populated only by the map-detail endpoint.
    let spawns: [MapSpawn]

    /// What a player still has to do to open this map.
    var unlockRequirement: String? {
        guard !unlocked else { return nil }
        switch unlockRule {
        case "zoo_value": return "Unlocks at Zoo value \(unlockValue)"
        default:          return "Locked"
        }
    }
}

// MARK: - Hunter

/// What a specific Hunter would cost and take on a specific Map.
///
/// Present only when the client asked about a map — the server does this
/// arithmetic so the quote a player sees is the one they will be charged.
struct HunterCosting: Hashable, Sendable {
    let biomeAffinity: Bool
    let totalCostG: Int
    let durationMinutes: Int
}

/// A Hunter in the Guild pool.
///
/// There is deliberately no `owned` or `available` flag: a Hunter is
/// contracted for one expedition and belongs to no player (Game Master v0.3).
struct Hunter: Identifiable, Hashable, Sendable {
    let id: String          // "hunter_susumu_019"
    let name: String
    let nameJA: String
    let rank: String        // Bronze / Silver / Gold / Platinum / Diamond / Master
    let level: Int
    let specialty: String
    let preferredBiomeID: String    // a biome id, or "any"
    let captureBonus: Int
    let rareFindBonus: Int
    let speedBonus: Int
    let contractCostG: Int
    let personality: String
    let hunterDescription: String
    let costing: HunterCosting?

    var prefersAnyBiome: Bool { preferredBiomeID == "any" }
}

// MARK: - Expedition

enum ExpeditionStatus: String, Hashable, Sendable {
    case inProgress = "in_progress"
    case resolved
}

enum ExpeditionOutcome: String, Hashable, Sendable {
    case captured
    case noCapture = "no_capture"
}

enum ExpeditionDecision: String, Hashable, Sendable {
    case kept
    case released
}

/// How an expedition turned out, including the arithmetic behind it.
///
/// The chance and roll are shown to the player: "70% and you rolled 84" is
/// a better story than "no capture", and it also makes the server's maths
/// checkable from the client.
struct ExpeditionResolution: Hashable, Sendable {
    let encounteredSpecies: AnimalSpecies?
    let captureChancePercent: Int
    let captureRoll: Int
}

struct Expedition: Identifiable, Hashable, Sendable {
    let id: String
    let status: ExpeditionStatus
    let outcome: ExpeditionOutcome?
    let decision: ExpeditionDecision?

    let mapID: String
    let mapNameEN: String
    let mapExpeditionMinutes: Int

    let hunterID: String
    let hunterName: String
    let hunterRank: String

    let mapCostG: Int
    let contractCostG: Int
    let totalCostG: Int

    /// The duration the canonical map minutes and the hunter's speed bonus
    /// imply — reported even when the development shortcut collapsed the
    /// timer, so the real timing is always visible.
    let plannedDurationMinutes: Int
    /// True only for expeditions created through the explicit development
    /// shortcut. Surfaced in the UI so a shortened run is never mistaken
    /// for a real one.
    let devInstantResolve: Bool

    let startedAt: Date
    let endsAt: Date
    let resolvedAt: Date?
    let decidedAt: Date?

    let isDue: Bool
    let awaitsDecision: Bool
    let resolution: ExpeditionResolution?
    let zooAnimal: ZooAnimal?

    var isResolved: Bool { resolvedAt != nil }
    var captured: Bool { outcome == .captured }
}

// MARK: - Zoo

struct ZooAnimal: Identifiable, Hashable, Sendable {
    let id: String
    /// The name the player gave it.
    let name: String
    let species: AnimalSpecies
    let capturedAt: Date?
    let capturedFromMapID: String?
    let capturedByHunterID: String?
}

struct ZooSummary: Hashable, Sendable {
    let id: String?
    let zooValue: Int
    let animalCount: Int
}

/// Everything Home shows about the signed-in player, straight from the server.
struct PlayerOverview: Hashable, Sendable {
    let playerID: String
    let displayName: String
    let gBalance: Int
    let zoo: ZooSummary
    let activeExpeditions: Int
    let pendingDecisions: Int
}

struct ZooContents: Hashable, Sendable {
    let summary: ZooSummary
    let animals: [ZooAnimal]
}
