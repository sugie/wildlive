// WildLive — In-memory implementations of the game Domain contracts.
//
// Used by SwiftUI previews, unit tests, and any UI test that must run
// without Laravel and PostgreSQL. They are swapped in at the composition
// root (WildLiveApp) — no screen knows which implementation it has.
//
// The data is a faithful subset of Game Master v0.3 (real ids, real costs,
// real durations) so a preview shows the same shapes the live app does.
// The outcome is deterministic on purpose: a UI test that sometimes
// returned "no capture" would be a flaky test.

import Foundation

/// The shared in-memory world the three mock repositories act on.
///
/// A single actor rather than three independent fakes, because the three
/// contracts are not independent: keeping an animal has to change the Zoo
/// that the profile repository reports.
actor MockGameWorld {
    static let shared = MockGameWorld()

    // MARK: Master data (a slice of Game Master v0.3)

    static let common = Rarity(id: "rarity_common", nameEN: "Common", nameJA: "コモン", sortOrder: 1)
    static let uncommon = Rarity(id: "rarity_uncommon", nameEN: "Uncommon", nameJA: "アンコモン", sortOrder: 2)
    static let rare = Rarity(id: "rarity_rare", nameEN: "Rare", nameJA: "レア", sortOrder: 3)

    static let impala = AnimalSpecies(
        id: "animal_impala_001", nameEN: "Impala", nameJA: "インパラ",
        rarity: common, baseZooValue: 10, captureDifficulty: 1,
        descriptionEN: "Graceful savanna antelope. Everywhere on the plains."
    )
    static let zebra = AnimalSpecies(
        id: "animal_common_zebra_002", nameEN: "Common Zebra", nameJA: "サバンナシマウマ",
        rarity: common, baseZooValue: 12, captureDifficulty: 1,
        descriptionEN: "Iconic striped equid of the East African plains."
    )
    static let leopard = AnimalSpecies(
        id: "animal_leopard_017", nameEN: "Leopard", nameJA: "ヒョウ",
        rarity: uncommon, baseZooValue: 25, captureDifficulty: 3,
        descriptionEN: "Solitary big cat that adapts to nearly every African biome."
    )
    static let lion = AnimalSpecies(
        id: "animal_lion_029", nameEN: "African Lion", nameJA: "ライオン",
        rarity: rare, baseZooValue: 45, captureDifficulty: 4,
        descriptionEN: "The savanna's apex social predator."
    )

    static let starterMap = GameMap(
        id: "map_kenyan_savanna_001", nameEN: "Kenyan Savanna", nameJA: "ケニアのサバンナ",
        region: "East Africa", biomeID: "biome_savanna", mapRole: "starter",
        difficulty: 1, riskLevel: 1, expeditionMinutes: 10, baseCostG: 50,
        recommendedHunterRank: 1, unlockRule: "always", unlockValue: 0, unlocked: true,
        descriptionEN: "Wide-open grassland teeming with iconic African wildlife.",
        spawns: [
            MapSpawn(species: impala, spawnWeight: 35, captureModifier: 0),
            MapSpawn(species: zebra, spawnWeight: 30, captureModifier: 0),
            MapSpawn(species: leopard, spawnWeight: 8, captureModifier: 0),
            MapSpawn(species: lion, spawnWeight: 6, captureModifier: 0),
        ]
    )

    static let lockedMap = GameMap(
        id: "map_serengeti_plains_002", nameEN: "Serengeti Plains", nameJA: "セレンゲティ平原",
        region: "East Africa", biomeID: "biome_savanna", mapRole: "general",
        difficulty: 2, riskLevel: 1, expeditionMinutes: 20, baseCostG: 90,
        recommendedHunterRank: 1, unlockRule: "zoo_value", unlockValue: 100, unlocked: false,
        descriptionEN: "Endless migration corridor.",
        spawns: []
    )

    static let cheapHunter = Hunter(
        id: "hunter_amara_kone_001", name: "Amara Koné", nameJA: "アマラ・コネ",
        rank: "Bronze", level: 1, specialty: "Beginner",
        preferredBiomeID: "biome_savanna", captureBonus: 0, rareFindBonus: -5, speedBonus: 0,
        contractCostG: 50,
        personality: "Cheerful new recruit from the coastal towns.",
        hunterDescription: "Reliable first Hunter for any player.",
        costing: HunterCosting(biomeAffinity: true, totalCostG: 100, durationMinutes: 10)
    )

    static let rareFindHunter = Hunter(
        id: "hunter_zara_okafor_004", name: "Zara Okafor", nameJA: "ザラ・オカフォー",
        rank: "Silver", level: 5, specialty: "Rare-Find",
        preferredBiomeID: "biome_savanna", captureBonus: 0, rareFindBonus: 15, speedBonus: -5,
        contractCostG: 280,
        personality: "Patient tracker.",
        hunterDescription: "Boosts the odds of returning with a Rare or better.",
        costing: HunterCosting(biomeAffinity: true, totalCostG: 330, durationMinutes: 11)
    )

    static let desertHunter = Hunter(
        id: "hunter_susumu_019", name: "Susumu", nameJA: "進",
        rank: "Gold", level: 7, specialty: "Desert-Specialist",
        preferredBiomeID: "biome_desert", captureBonus: 15, rareFindBonus: 3, speedBonus: 0,
        contractCostG: 560,
        personality: "Meticulous scout.",
        hunterDescription: "The Guild's only desert specialist.",
        costing: HunterCosting(biomeAffinity: false, totalCostG: 610, durationMinutes: 10)
    )

    // MARK: Mutable state

    private var gBalance = 1000
    private var animals: [ZooAnimal] = []
    private var expeditions: [String: Expedition] = [:]
    private var nextID = 1

    /// Every mock expedition captures. Determinism beats realism here: a
    /// UI test asserting the capture screen must not depend on a dice roll.
    private let capturedSpecies = MockGameWorld.impala

    func reset() {
        gBalance = 1000
        animals = []
        expeditions = [:]
        nextID = 1
    }

    // MARK: Reads

    func maps() -> [GameMap] {
        let zooValue = animals.reduce(0) { $0 + $1.species.baseZooValue }
        let unlocked = GameMap(
            id: Self.lockedMap.id, nameEN: Self.lockedMap.nameEN, nameJA: Self.lockedMap.nameJA,
            region: Self.lockedMap.region, biomeID: Self.lockedMap.biomeID,
            mapRole: Self.lockedMap.mapRole, difficulty: Self.lockedMap.difficulty,
            riskLevel: Self.lockedMap.riskLevel, expeditionMinutes: Self.lockedMap.expeditionMinutes,
            baseCostG: Self.lockedMap.baseCostG,
            recommendedHunterRank: Self.lockedMap.recommendedHunterRank,
            unlockRule: Self.lockedMap.unlockRule, unlockValue: Self.lockedMap.unlockValue,
            unlocked: zooValue >= Self.lockedMap.unlockValue,
            descriptionEN: Self.lockedMap.descriptionEN, spawns: Self.lockedMap.spawns
        )
        return [Self.starterMap, unlocked]
    }

    func map(_ id: String) -> GameMap? {
        maps().first { $0.id == id }
    }

    func hunters() -> [Hunter] {
        [Self.cheapHunter, Self.rareFindHunter, Self.desertHunter]
    }

    func overview(playerID: String, displayName: String) -> PlayerOverview {
        PlayerOverview(
            playerID: playerID,
            displayName: displayName,
            gBalance: gBalance,
            zoo: zooSummary(),
            activeExpeditions: expeditions.values.filter { !$0.isResolved }.count,
            pendingDecisions: expeditions.values.filter(\.awaitsDecision).count
        )
    }

    func zoo() -> ZooContents {
        ZooContents(summary: zooSummary(), animals: animals)
    }

    private func zooSummary() -> ZooSummary {
        ZooSummary(
            id: "mock-zoo",
            zooValue: animals.reduce(0) { $0 + $1.species.baseZooValue },
            animalCount: animals.count
        )
    }

    // MARK: Writes

    func start(mapID: String, hunterID: String, devInstantResolve: Bool) throws -> Expedition {
        guard let map = map(mapID) else {
            throw GameAPIError(code: "map_not_found", message: "No such map.",
                               underlying: .invalidURL)
        }
        guard map.unlocked else {
            throw GameAPIError(code: "map_locked",
                               message: "\(map.nameEN) unlocks at Zoo value \(map.unlockValue).",
                               underlying: .invalidURL)
        }
        guard let hunter = hunters().first(where: { $0.id == hunterID }) else {
            throw GameAPIError(code: "hunter_not_found", message: "No such hunter.",
                               underlying: .invalidURL)
        }

        let cost = map.baseCostG + hunter.contractCostG
        guard gBalance >= cost else {
            throw GameAPIError(code: "insufficient_g",
                               message: "This expedition costs \(cost) G. You have \(gBalance) G.",
                               underlying: .invalidURL)
        }
        gBalance -= cost

        let minutes = hunter.costing?.durationMinutes ?? map.expeditionMinutes
        let now = Date()
        let id = "mock-expedition-\(nextID)"
        nextID += 1

        let expedition = Expedition(
            id: id, status: .inProgress, outcome: nil, decision: nil,
            mapID: map.id, mapNameEN: map.nameEN, mapExpeditionMinutes: map.expeditionMinutes,
            hunterID: hunter.id, hunterName: hunter.name, hunterRank: hunter.rank,
            mapCostG: map.baseCostG, contractCostG: hunter.contractCostG, totalCostG: cost,
            plannedDurationMinutes: minutes, devInstantResolve: devInstantResolve,
            startedAt: now,
            endsAt: devInstantResolve ? now : now.addingTimeInterval(Double(minutes) * 60),
            resolvedAt: nil, decidedAt: nil,
            isDue: devInstantResolve, awaitsDecision: false,
            resolution: nil, zooAnimal: nil
        )
        expeditions[id] = expedition
        return expedition
    }

    func expedition(_ id: String) throws -> Expedition {
        guard let expedition = expeditions[id] else {
            throw GameAPIError(code: "expedition_not_found", message: "No such expedition.",
                               underlying: .invalidURL)
        }
        return expedition
    }

    func allExpeditions() -> [Expedition] {
        expeditions.values.sorted { $0.startedAt > $1.startedAt }
    }

    func resolve(_ id: String) throws -> Expedition {
        let current = try expedition(id)
        if current.isResolved { return current }   // idempotent, like the server

        guard current.endsAt <= Date() else {
            throw GameAPIError(code: "expedition_not_due",
                               message: "This expedition is still out.",
                               underlying: .invalidURL)
        }

        let resolved = current.with(
            status: .resolved,
            outcome: .captured,
            resolvedAt: Date(),
            isDue: true,
            awaitsDecision: true,
            resolution: ExpeditionResolution(
                encounteredSpecies: capturedSpecies,
                captureChancePercent: 70,
                captureRoll: 12
            )
        )
        expeditions[id] = resolved
        return resolved
    }

    func keep(_ id: String, name: String) throws -> Expedition {
        let current = try expedition(id)
        if current.decision == .kept { return current }
        try requireUndecidedCapture(current)

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let species = current.resolution?.encounteredSpecies ?? capturedSpecies
        let animal = ZooAnimal(
            id: "mock-animal-\(animals.count + 1)",
            name: trimmed.isEmpty ? species.nameEN : trimmed,
            species: species,
            capturedAt: current.resolvedAt,
            capturedFromMapID: current.mapID,
            capturedByHunterID: current.hunterID
        )
        animals.insert(animal, at: 0)

        let decided = current.with(
            decision: .kept, decidedAt: Date(), awaitsDecision: false, zooAnimal: animal
        )
        expeditions[id] = decided
        return decided
    }

    func release(_ id: String) throws -> Expedition {
        let current = try expedition(id)
        if current.decision == .released { return current }
        try requireUndecidedCapture(current)

        let decided = current.with(decision: .released, decidedAt: Date(), awaitsDecision: false)
        expeditions[id] = decided
        return decided
    }

    private func requireUndecidedCapture(_ expedition: Expedition) throws {
        guard expedition.isResolved else {
            throw GameAPIError(code: "expedition_not_resolved",
                               message: "This expedition has not been resolved yet.",
                               underlying: .invalidURL)
        }
        guard expedition.captured else {
            throw GameAPIError(code: "nothing_to_decide",
                               message: "This expedition returned without a capture.",
                               underlying: .invalidURL)
        }
        guard expedition.decidedAt == nil else {
            throw GameAPIError(code: "already_decided",
                               message: "This capture was already handled.",
                               underlying: .invalidURL)
        }
    }
}

// MARK: - Copy helper

private extension Expedition {
    /// Field-wise copy. Expedition is a `let`-only value type on purpose —
    /// only the server changes an expedition — so the mock, which has to
    /// play server, needs an explicit way to produce the next version.
    func with(
        status: ExpeditionStatus? = nil,
        outcome: ExpeditionOutcome? = nil,
        decision: ExpeditionDecision? = nil,
        resolvedAt: Date? = nil,
        decidedAt: Date? = nil,
        isDue: Bool? = nil,
        awaitsDecision: Bool? = nil,
        resolution: ExpeditionResolution? = nil,
        zooAnimal: ZooAnimal? = nil
    ) -> Expedition {
        Expedition(
            id: id,
            status: status ?? self.status,
            outcome: outcome ?? self.outcome,
            decision: decision ?? self.decision,
            mapID: mapID, mapNameEN: mapNameEN, mapExpeditionMinutes: mapExpeditionMinutes,
            hunterID: hunterID, hunterName: hunterName, hunterRank: hunterRank,
            mapCostG: mapCostG, contractCostG: contractCostG, totalCostG: totalCostG,
            plannedDurationMinutes: plannedDurationMinutes, devInstantResolve: devInstantResolve,
            startedAt: startedAt, endsAt: endsAt,
            resolvedAt: resolvedAt ?? self.resolvedAt,
            decidedAt: decidedAt ?? self.decidedAt,
            isDue: isDue ?? self.isDue,
            awaitsDecision: awaitsDecision ?? self.awaitsDecision,
            resolution: resolution ?? self.resolution,
            zooAnimal: zooAnimal ?? self.zooAnimal
        )
    }
}

// MARK: - Repositories

final class MockGameCatalogRepository: GameCatalogRepository {
    private let world: MockGameWorld

    init(world: MockGameWorld = .shared) {
        self.world = world
    }

    func maps(playerID: String) async throws -> [GameMap] {
        await world.maps()
    }

    func mapDetail(playerID: String, mapID: String) async throws -> GameMap {
        guard let map = await world.map(mapID) else {
            throw GameAPIError(code: "map_not_found", message: "No such map.", underlying: .invalidURL)
        }
        return map
    }

    func hunters(forMapID mapID: String?) async throws -> [Hunter] {
        await world.hunters()
    }
}

final class MockPlayerProfileRepository: PlayerProfileRepository {
    private let world: MockGameWorld
    private let displayName: String

    init(world: MockGameWorld = .shared, displayName: String = "UITest") {
        self.world = world
        self.displayName = displayName
    }

    func overview(playerID: String) async throws -> PlayerOverview {
        await world.overview(playerID: playerID, displayName: displayName)
    }

    func zoo(playerID: String) async throws -> ZooContents {
        await world.zoo()
    }
}

final class MockExpeditionRepository: ExpeditionRepository {
    private let world: MockGameWorld

    init(world: MockGameWorld = .shared) {
        self.world = world
    }

    func start(
        playerID: String,
        mapID: String,
        hunterID: String,
        devInstantResolve: Bool
    ) async throws -> Expedition {
        try await world.start(mapID: mapID, hunterID: hunterID, devInstantResolve: devInstantResolve)
    }

    func list(playerID: String) async throws -> [Expedition] {
        await world.allExpeditions()
    }

    func get(playerID: String, expeditionID: String) async throws -> Expedition {
        let current = try await world.expedition(expeditionID)
        // Mirrors the server's lazy resolution on read.
        if !current.isResolved && current.endsAt <= Date() {
            return try await world.resolve(expeditionID)
        }
        return current
    }

    func resolve(playerID: String, expeditionID: String) async throws -> Expedition {
        try await world.resolve(expeditionID)
    }

    func keep(playerID: String, expeditionID: String, name: String) async throws -> Expedition {
        try await world.keep(expeditionID, name: name)
    }

    func release(playerID: String, expeditionID: String) async throws -> Expedition {
        try await world.release(expeditionID)
    }
}
