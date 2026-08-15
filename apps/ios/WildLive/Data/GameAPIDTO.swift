// WildLive — Wire-format DTOs for the gameplay endpoints.
//
// Shapes dictated by the Laravel API, so the property names are the
// server's snake_case rather than Swift style. Keeping them out of the
// Domain layer is what lets the API rename a field without the game model
// changing: only the `toDomain()` functions in this file move.
//
// Only the Data Layer touches these types.

import Foundation

// MARK: - Catalogue

struct RarityDTO: Decodable {
    let id: String
    let name_en: String
    let name_ja: String
    let sort_order: Int

    func toDomain() -> Rarity {
        Rarity(id: id, nameEN: name_en, nameJA: name_ja, sortOrder: sort_order)
    }
}

struct AnimalDTO: Decodable {
    let id: String
    let name_en: String
    let name_ja: String
    let rarity: RarityDTO
    let base_zoo_value: Int
    let capture_difficulty: Int
    let description_en: String?

    func toDomain() -> AnimalSpecies {
        AnimalSpecies(
            id: id,
            nameEN: name_en,
            nameJA: name_ja,
            rarity: rarity.toDomain(),
            baseZooValue: base_zoo_value,
            captureDifficulty: capture_difficulty,
            descriptionEN: description_en ?? ""
        )
    }
}

struct MapSpawnDTO: Decodable {
    let spawn_weight: Int
    let capture_modifier: Int
    let animal: AnimalDTO

    func toDomain() -> MapSpawn {
        MapSpawn(
            species: animal.toDomain(),
            spawnWeight: spawn_weight,
            captureModifier: capture_modifier
        )
    }
}

struct MapDTO: Decodable {
    let id: String
    let name_en: String
    let name_ja: String
    let region: String
    let biome_id: String
    let map_role: String
    let difficulty: Int
    let risk_level: Int
    let expedition_minutes: Int
    let base_cost_g: Int
    let recommended_hunter_rank: Int
    let unlock_rule: String
    let unlock_value: Int
    let unlocked: Bool
    let description_en: String?
    let animals: [MapSpawnDTO]?

    func toDomain() -> GameMap {
        GameMap(
            id: id,
            nameEN: name_en,
            nameJA: name_ja,
            region: region,
            biomeID: biome_id,
            mapRole: map_role,
            difficulty: difficulty,
            riskLevel: risk_level,
            expeditionMinutes: expedition_minutes,
            baseCostG: base_cost_g,
            recommendedHunterRank: recommended_hunter_rank,
            unlockRule: unlock_rule,
            unlockValue: unlock_value,
            unlocked: unlocked,
            descriptionEN: description_en ?? "",
            spawns: (animals ?? []).map { $0.toDomain() }
        )
    }
}

struct MapListResponseDTO: Decodable {
    let zoo_value: Int
    let maps: [MapDTO]
}

struct MapDetailResponseDTO: Decodable {
    let zoo_value: Int
    let map: MapDTO
}

struct HunterCostingDTO: Decodable {
    let biome_affinity: Bool
    let total_cost_g: Int
    let duration_minutes: Int

    func toDomain() -> HunterCosting {
        HunterCosting(
            biomeAffinity: biome_affinity,
            totalCostG: total_cost_g,
            durationMinutes: duration_minutes
        )
    }
}

struct HunterDTO: Decodable {
    let id: String
    let name: String
    let name_ja: String
    let rank: String
    let level: Int
    let specialty: String
    let preferred_biome_id: String
    let capture_bonus: Int
    let rare_find_bonus: Int
    let speed_bonus: Int
    let contract_cost_g: Int
    let personality: String?
    let description: String?
    let for_map: HunterCostingDTO?

    func toDomain() -> Hunter {
        Hunter(
            id: id,
            name: name,
            nameJA: name_ja,
            rank: rank,
            level: level,
            specialty: specialty,
            preferredBiomeID: preferred_biome_id,
            captureBonus: capture_bonus,
            rareFindBonus: rare_find_bonus,
            speedBonus: speed_bonus,
            contractCostG: contract_cost_g,
            personality: personality ?? "",
            hunterDescription: description ?? "",
            costing: for_map?.toDomain()
        )
    }
}

struct HunterListResponseDTO: Decodable {
    let map_id: String?
    let hunters: [HunterDTO]
}

// MARK: - Player + Zoo

struct ZooSummaryDTO: Decodable {
    let id: String?
    let zoo_value: Int
    let animal_count: Int

    func toDomain() -> ZooSummary {
        ZooSummary(id: id, zooValue: zoo_value, animalCount: animal_count)
    }
}

struct PlayerOverviewResponseDTO: Decodable {
    struct PlayerDTO: Decodable {
        let id: String
        let display_name: String
        let g_balance: Int
    }
    struct ExpeditionCountsDTO: Decodable {
        let active: Int
        let pending_decisions: Int
    }

    let player: PlayerDTO
    let zoo: ZooSummaryDTO
    let expeditions: ExpeditionCountsDTO

    func toDomain() -> PlayerOverview {
        PlayerOverview(
            playerID: player.id,
            displayName: player.display_name,
            gBalance: player.g_balance,
            zoo: zoo.toDomain(),
            activeExpeditions: expeditions.active,
            pendingDecisions: expeditions.pending_decisions
        )
    }
}

struct ZooAnimalDTO: Decodable {
    let id: String
    let name: String
    let species: AnimalDTO
    let captured_at: Date?
    let captured_from_map_id: String?
    let captured_by_hunter_id: String?

    func toDomain() -> ZooAnimal {
        ZooAnimal(
            id: id,
            name: name,
            species: species.toDomain(),
            capturedAt: captured_at,
            capturedFromMapID: captured_from_map_id,
            capturedByHunterID: captured_by_hunter_id
        )
    }
}

struct ZooResponseDTO: Decodable {
    let zoo: ZooSummaryDTO
    let animals: [ZooAnimalDTO]

    func toDomain() -> ZooContents {
        ZooContents(summary: zoo.toDomain(), animals: animals.map { $0.toDomain() })
    }
}

// MARK: - Expedition

struct ExpeditionDTO: Decodable {
    struct MapRefDTO: Decodable {
        let id: String
        let name_en: String
        let expedition_minutes: Int
    }
    struct HunterRefDTO: Decodable {
        let id: String
        let name: String
        let rank: String
    }
    struct CostDTO: Decodable {
        let map_cost_g: Int
        let contract_cost_g: Int
        let total_cost_g: Int
    }
    struct ResolutionDTO: Decodable {
        let encountered_animal: AnimalDTO?
        let capture_chance_percent: Int
        let capture_roll: Int

        func toDomain() -> ExpeditionResolution {
            ExpeditionResolution(
                encounteredSpecies: encountered_animal?.toDomain(),
                captureChancePercent: capture_chance_percent,
                captureRoll: capture_roll
            )
        }
    }

    let id: String
    let status: String
    let outcome: String?
    let decision: String?
    let map: MapRefDTO
    let hunter: HunterRefDTO
    let cost: CostDTO
    let planned_duration_minutes: Int
    let dev_instant_resolve: Bool
    let started_at: Date
    let ends_at: Date
    let resolved_at: Date?
    let decided_at: Date?
    let is_due: Bool
    let awaits_decision: Bool
    let resolution: ResolutionDTO?
    let zoo_animal: ZooAnimalDTO?

    func toDomain() -> Expedition {
        Expedition(
            id: id,
            // An unrecognised status means the server grew a state this
            // build does not know. Treating it as in-progress keeps the
            // screen readable instead of crashing on a force-unwrap.
            status: ExpeditionStatus(rawValue: status) ?? .inProgress,
            outcome: outcome.flatMap(ExpeditionOutcome.init(rawValue:)),
            decision: decision.flatMap(ExpeditionDecision.init(rawValue:)),
            mapID: map.id,
            mapNameEN: map.name_en,
            mapExpeditionMinutes: map.expedition_minutes,
            hunterID: hunter.id,
            hunterName: hunter.name,
            hunterRank: hunter.rank,
            mapCostG: cost.map_cost_g,
            contractCostG: cost.contract_cost_g,
            totalCostG: cost.total_cost_g,
            plannedDurationMinutes: planned_duration_minutes,
            devInstantResolve: dev_instant_resolve,
            startedAt: started_at,
            endsAt: ends_at,
            resolvedAt: resolved_at,
            decidedAt: decided_at,
            isDue: is_due,
            awaitsDecision: awaits_decision,
            resolution: resolution?.toDomain(),
            zooAnimal: zoo_animal?.toDomain()
        )
    }
}

struct ExpeditionResponseDTO: Decodable {
    let expedition: ExpeditionDTO
}

struct ExpeditionListResponseDTO: Decodable {
    let expeditions: [ExpeditionDTO]
}

// MARK: - Requests

struct StartExpeditionRequestDTO: Encodable {
    let map_id: String
    let hunter_id: String
    let dev_instant_resolve: Bool
}

struct KeepCapturedAnimalRequestDTO: Encodable {
    let name: String
}

// MARK: - Errors

/// The server's structured refusal: `{"error": {"code", "message"}}`.
///
/// Decoded so the UI can show the server's own wording ("Kenyan Savanna
/// unlocks at Zoo value 100. Your Zoo is worth 40.") rather than a generic
/// "Server returned 422".
struct APIErrorBodyDTO: Decodable {
    struct Payload: Decodable {
        let code: String
        let message: String
    }
    let error: Payload
}
