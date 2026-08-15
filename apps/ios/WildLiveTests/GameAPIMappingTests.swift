// WildLive — Data-layer mapping tests.
//
// The API is the only source of game state, so the wire → Domain mapping is
// where a client-side bug would silently change what a player sees. These
// tests feed real response payloads (copied from the running Laravel) through
// the DTOs and assert the Domain values that come out.
//
// The date cases matter more than they look: Laravel emits microseconds, and
// `JSONDecoder.iso8601` rejects that outright. Every timestamp in the app
// depends on the lenient strategy tested here.

import XCTest
@testable import WildLive

final class GameAPIMappingTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = APIClient.lenientISO8601
        return try decoder.decode(type, from: Data(json.utf8))
    }

    // MARK: - Dates

    func test_decodesLaravelTimestampsWithMicroseconds() throws {
        struct Wrapper: Decodable { let at: Date }

        let wrapper = try decode(Wrapper.self, #"{"at":"2026-08-15T12:57:27.000000Z"}"#)

        XCTAssertEqual(
            wrapper.at.timeIntervalSince1970,
            ISO8601DateFormatter().date(from: "2026-08-15T12:57:27Z")!.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_decodesTimestampsWithoutFractionalSeconds() throws {
        struct Wrapper: Decodable { let at: Date }

        XCTAssertNoThrow(try decode(Wrapper.self, #"{"at":"2026-08-15T12:57:27Z"}"#))
    }

    func test_rejectsSomethingThatIsNotADate() throws {
        struct Wrapper: Decodable { let at: Date }

        XCTAssertThrowsError(try decode(Wrapper.self, #"{"at":"yesterday"}"#))
    }

    // MARK: - Map

    private let mapJSON = """
    {
      "zoo_value": 40,
      "map": {
        "id": "map_kenyan_savanna_001",
        "name_en": "Kenyan Savanna",
        "name_ja": "ケニアのサバンナ",
        "region": "East Africa",
        "biome_id": "biome_savanna",
        "map_role": "starter",
        "availability_phase": "initial_africa",
        "difficulty": 1,
        "risk_level": 1,
        "expedition_minutes": 10,
        "base_cost_g": 50,
        "recommended_hunter_rank": 1,
        "unlock_rule": "always",
        "unlock_value": 0,
        "unlocked": true,
        "description_en": "Wide-open grassland.",
        "description_ja": "広大な草原。",
        "animals": [
          {
            "spawn_weight": 35,
            "capture_modifier": 0,
            "notes": "",
            "animal": {
              "id": "animal_impala_001",
              "name_en": "Impala",
              "name_ja": "インパラ",
              "category": "hoofed",
              "rarity": {"id": "rarity_common", "name_en": "Common", "name_ja": "コモン", "sort_order": 1},
              "base_zoo_value": 10,
              "capture_difficulty": 1,
              "visitor_appeal": 8,
              "habitat_biome_id": "biome_savanna",
              "size": "medium",
              "active_time": "diurnal",
              "description_en": "Graceful savanna antelope.",
              "description_ja": "優雅なサバンナのアンテロープ。"
            }
          }
        ]
      }
    }
    """

    func test_mapsCarryTheirGameMasterValues() throws {
        let map = try decode(MapDetailResponseDTO.self, mapJSON).map.toDomain()

        XCTAssertEqual(map.id, "map_kenyan_savanna_001")
        XCTAssertEqual(map.nameEN, "Kenyan Savanna")
        XCTAssertEqual(map.nameJA, "ケニアのサバンナ")
        XCTAssertEqual(map.biomeID, "biome_savanna")
        XCTAssertEqual(map.expeditionMinutes, 10, "the canonical duration reaches the client unchanged")
        XCTAssertEqual(map.baseCostG, 50)
        XCTAssertTrue(map.unlocked)
        XCTAssertNil(map.unlockRequirement, "an unlocked map has nothing left to require")
    }

    func test_spawnTableMapsSpeciesAndRarity() throws {
        let map = try decode(MapDetailResponseDTO.self, mapJSON).map.toDomain()

        XCTAssertEqual(map.spawns.count, 1)
        let spawn = try XCTUnwrap(map.spawns.first)
        XCTAssertEqual(spawn.spawnWeight, 35)
        XCTAssertEqual(spawn.species.nameEN, "Impala")
        XCTAssertEqual(spawn.species.rarity.sortOrder, 1)
        XCTAssertEqual(spawn.species.baseZooValue, 10)
    }

    func test_lockedMapExplainsWhatItNeeds() throws {
        let json = mapJSON
            .replacingOccurrences(of: "\"unlocked\": true", with: "\"unlocked\": false")
            .replacingOccurrences(of: "\"unlock_rule\": \"always\"", with: "\"unlock_rule\": \"zoo_value\"")
            .replacingOccurrences(of: "\"unlock_value\": 0", with: "\"unlock_value\": 100")

        let map = try decode(MapDetailResponseDTO.self, json).map.toDomain()

        XCTAssertFalse(map.unlocked)
        XCTAssertEqual(map.unlockRequirement, "Unlocks at Zoo value 100")
    }

    func test_mapListOmitsTheSpawnTable() throws {
        let json = """
        {"zoo_value": 0, "maps": [{
          "id": "map_namib_desert_004", "name_en": "Namib Desert", "name_ja": "ナミブ砂漠",
          "region": "Southern Africa", "biome_id": "biome_desert", "map_role": "specialist",
          "availability_phase": "initial_africa", "difficulty": 3, "risk_level": 3,
          "expedition_minutes": 60, "base_cost_g": 240, "recommended_hunter_rank": 2,
          "unlock_rule": "zoo_value", "unlock_value": 800, "unlocked": false,
          "description_en": "Extreme aridity.", "description_ja": "極度の乾燥地帯。"
        }]}
        """

        let maps = try decode(MapListResponseDTO.self, json).maps.map { $0.toDomain() }

        XCTAssertEqual(maps.count, 1)
        XCTAssertTrue(maps[0].spawns.isEmpty, "the list response stays small")
    }

    // MARK: - Hunter

    func test_hunterCarriesItsStructuredSkillsAndNoOwnership() throws {
        let json = """
        {"map_id": "map_namib_desert_004", "hunters": [{
          "id": "hunter_susumu_019", "name": "Susumu", "name_ja": "進",
          "rank": "Gold", "level": 7, "specialty": "Desert-Specialist",
          "preferred_biome_id": "biome_desert",
          "capture_bonus": 15, "rare_find_bonus": 3, "speed_bonus": 0,
          "contract_cost_g": 560,
          "personality": "Meticulous scout.",
          "description": "Only desert specialist in the Guild.",
          "for_map": {"biome_affinity": true, "total_cost_g": 800, "duration_minutes": 60}
        }]}
        """

        let hunter = try XCTUnwrap(decode(HunterListResponseDTO.self, json).hunters.first?.toDomain())

        XCTAssertEqual(hunter.id, "hunter_susumu_019")
        XCTAssertEqual(hunter.nameJA, "進")
        XCTAssertEqual(hunter.preferredBiomeID, "biome_desert")
        XCTAssertEqual(hunter.captureBonus, 15)
        XCTAssertEqual(hunter.rareFindBonus, 3)
        XCTAssertEqual(hunter.contractCostG, 560)
        XCTAssertEqual(hunter.costing?.totalCostG, 800)
        XCTAssertEqual(hunter.costing?.durationMinutes, 60)
        XCTAssertTrue(hunter.costing?.biomeAffinity == true)
        XCTAssertFalse(hunter.prefersAnyBiome)
    }

    func test_hunterWithoutAMapHasNoCosting() throws {
        let json = """
        {"map_id": null, "hunters": [{
          "id": "hunter_hana_ito_003", "name": "Hana Ito", "name_ja": "ハナ・イトー",
          "rank": "Bronze", "level": 3, "specialty": "All-round-Rookie",
          "preferred_biome_id": "any",
          "capture_bonus": 2, "rare_find_bonus": 0, "speed_bonus": 0,
          "contract_cost_g": 90, "personality": "", "description": ""
        }]}
        """

        let hunter = try XCTUnwrap(decode(HunterListResponseDTO.self, json).hunters.first?.toDomain())

        XCTAssertNil(hunter.costing)
        XCTAssertTrue(hunter.prefersAnyBiome, "`any` is a real value, not a missing one")
    }

    // MARK: - Expedition

    private func expeditionJSON(
        status: String = "resolved",
        outcome: String = "\"captured\"",
        decision: String = "null",
        resolution: String = """
        {"encountered_animal": {
            "id": "animal_impala_001", "name_en": "Impala", "name_ja": "インパラ",
            "category": "hoofed",
            "rarity": {"id": "rarity_common", "name_en": "Common", "name_ja": "コモン", "sort_order": 1},
            "base_zoo_value": 10, "capture_difficulty": 1, "visitor_appeal": 8,
            "habitat_biome_id": "biome_savanna", "size": "medium", "active_time": "diurnal",
            "description_en": "Graceful.", "description_ja": "優雅。"},
         "capture_chance_percent": 70, "capture_roll": 12, "encounter_roll": 4200}
        """,
        zooAnimal: String = "null",
        awaitsDecision: Bool = true
    ) -> String {
        """
        {"expedition": {
          "id": "a2822c77-e563-4c6c-971b-ba27b52f396a",
          "player_id": "a2822c77-e151-4a0c-b697-17bedb8f7921",
          "status": "\(status)", "outcome": \(outcome), "decision": \(decision),
          "map": {"id": "map_kenyan_savanna_001", "name_en": "Kenyan Savanna",
                  "name_ja": "ケニアのサバンナ", "biome_id": "biome_savanna",
                  "difficulty": 1, "expedition_minutes": 10},
          "hunter": {"id": "hunter_amara_kone_001", "name": "Amara Koné",
                     "name_ja": "アマラ・コネ", "rank": "Bronze", "specialty": "Beginner"},
          "cost": {"map_cost_g": 50, "contract_cost_g": 50, "total_cost_g": 100},
          "planned_duration_minutes": 10,
          "dev_instant_resolve": true,
          "started_at": "2026-08-15T12:57:27.000000Z",
          "ends_at": "2026-08-15T12:57:27.000000Z",
          "resolved_at": "2026-08-15T12:57:28.000000Z",
          "decided_at": null,
          "is_due": true,
          "awaits_decision": \(awaitsDecision),
          "resolution": \(resolution),
          "zoo_animal": \(zooAnimal)
        }}
        """
    }

    func test_capturedExpeditionMapsItsResolution() throws {
        let expedition = try decode(ExpeditionResponseDTO.self, expeditionJSON()).expedition.toDomain()

        XCTAssertEqual(expedition.status, .resolved)
        XCTAssertEqual(expedition.outcome, .captured)
        XCTAssertNil(expedition.decision)
        XCTAssertTrue(expedition.captured)
        XCTAssertTrue(expedition.isResolved)
        XCTAssertTrue(expedition.awaitsDecision)
        XCTAssertEqual(expedition.resolution?.encounteredSpecies?.nameEN, "Impala")
        XCTAssertEqual(expedition.resolution?.captureChancePercent, 70)
        XCTAssertEqual(expedition.resolution?.captureRoll, 12)
    }

    func test_expeditionCarriesCostsAndTheRealDuration() throws {
        let expedition = try decode(ExpeditionResponseDTO.self, expeditionJSON()).expedition.toDomain()

        XCTAssertEqual(expedition.mapCostG, 50)
        XCTAssertEqual(expedition.contractCostG, 50)
        XCTAssertEqual(expedition.totalCostG, 100)
        XCTAssertEqual(expedition.plannedDurationMinutes, 10,
                       "the real duration survives even a development run")
        XCTAssertTrue(expedition.devInstantResolve,
                      "a shortened development run is flagged, not hidden")
    }

    func test_noCaptureExpeditionStillNamesTheAnimalThatGotAway() throws {
        let json = expeditionJSON(outcome: "\"no_capture\"", awaitsDecision: false)

        let expedition = try decode(ExpeditionResponseDTO.self, json).expedition.toDomain()

        XCTAssertEqual(expedition.outcome, .noCapture)
        XCTAssertFalse(expedition.captured)
        XCTAssertFalse(expedition.awaitsDecision)
        XCTAssertEqual(expedition.resolution?.encounteredSpecies?.nameEN, "Impala")
    }

    func test_keptExpeditionCarriesTheZooAnimal() throws {
        let zooAnimal = """
        {"id": "a28225f2-20c0-48be-aca3-8885fd37fe97", "name": "Nala",
         "species": {"id": "animal_impala_001", "name_en": "Impala", "name_ja": "インパラ",
           "category": "hoofed",
           "rarity": {"id": "rarity_common", "name_en": "Common", "name_ja": "コモン", "sort_order": 1},
           "base_zoo_value": 10, "capture_difficulty": 1, "visitor_appeal": 8,
           "habitat_biome_id": "biome_savanna", "size": "medium", "active_time": "diurnal",
           "description_en": "Graceful.", "description_ja": "優雅。"},
         "captured_at": "2026-08-15T12:57:28.000000Z",
         "captured_from_map_id": "map_kenyan_savanna_001",
         "captured_by_hunter_id": "hunter_amara_kone_001",
         "expedition_id": "a2822c77-e563-4c6c-971b-ba27b52f396a"}
        """
        let json = expeditionJSON(decision: "\"kept\"", zooAnimal: zooAnimal, awaitsDecision: false)

        let expedition = try decode(ExpeditionResponseDTO.self, json).expedition.toDomain()

        XCTAssertEqual(expedition.decision, .kept)
        XCTAssertEqual(expedition.zooAnimal?.name, "Nala")
        XCTAssertEqual(expedition.zooAnimal?.species.nameEN, "Impala")
        XCTAssertEqual(expedition.zooAnimal?.capturedFromMapID, "map_kenyan_savanna_001")
    }

    func test_anUnknownStatusDoesNotCrashTheClient() throws {
        // A server that grows a new state must not brick an old build.
        let json = expeditionJSON(status: "abandoned", outcome: "null",
                                  resolution: "null", awaitsDecision: false)

        let expedition = try decode(ExpeditionResponseDTO.self, json).expedition.toDomain()

        XCTAssertEqual(expedition.status, .inProgress, "unknown states degrade to in-progress")
        XCTAssertNil(expedition.outcome)
    }

    // MARK: - Player + Zoo

    func test_playerOverviewMapsBalanceAndCounters() throws {
        let json = """
        {"player": {"id": "p-1", "display_name": "Zookeeper", "g_balance": 900,
                    "created_at": "2026-08-15T12:56:56.000000Z"},
         "zoo": {"id": "z-1", "zoo_value": 10, "animal_count": 1},
         "expeditions": {"active": 2, "pending_decisions": 1}}
        """

        let overview = try decode(PlayerOverviewResponseDTO.self, json).toDomain()

        XCTAssertEqual(overview.playerID, "p-1")
        XCTAssertEqual(overview.displayName, "Zookeeper")
        XCTAssertEqual(overview.gBalance, 900)
        XCTAssertEqual(overview.zoo.zooValue, 10)
        XCTAssertEqual(overview.zoo.animalCount, 1)
        XCTAssertEqual(overview.activeExpeditions, 2)
        XCTAssertEqual(overview.pendingDecisions, 1)
    }

    func test_zooMapsPersistedAnimals() throws {
        let json = """
        {"zoo": {"id": "z-1", "zoo_value": 10, "animal_count": 1},
         "animals": [{"id": "a-1", "name": "Nala",
           "species": {"id": "animal_impala_001", "name_en": "Impala", "name_ja": "インパラ",
             "category": "hoofed",
             "rarity": {"id": "rarity_common", "name_en": "Common", "name_ja": "コモン", "sort_order": 1},
             "base_zoo_value": 10, "capture_difficulty": 1, "visitor_appeal": 8,
             "habitat_biome_id": "biome_savanna", "size": "medium", "active_time": "diurnal",
             "description_en": "Graceful.", "description_ja": "優雅。"},
           "captured_at": "2026-08-15T12:57:28.000000Z",
           "captured_from_map_id": "map_kenyan_savanna_001",
           "captured_by_hunter_id": "hunter_amara_kone_001",
           "expedition_id": "e-1"}]}
        """

        let zoo = try decode(ZooResponseDTO.self, json).toDomain()

        XCTAssertEqual(zoo.summary.animalCount, 1)
        XCTAssertEqual(zoo.animals.first?.name, "Nala")
        XCTAssertEqual(zoo.animals.first?.species.rarity.nameEN, "Common")
    }

    // MARK: - Errors

    func test_serverRefusalIsSurfacedWithItsOwnMessage() throws {
        let body = #"{"error":{"code":"insufficient_g","message":"This expedition costs 4550 G. You have 1000 G."}}"#

        let mapped = GameAPIError.from(.badStatus(422, body: body))

        let gameError = try XCTUnwrap(mapped as? GameAPIError)
        XCTAssertEqual(gameError.code, "insufficient_g")
        XCTAssertEqual(gameError.localizedDescription, "This expedition costs 4550 G. You have 1000 G.")
    }

    func test_alreadyDecidedIsRecognisable() throws {
        let body = #"{"error":{"code":"already_decided","message":"This capture was already kept."}}"#

        let gameError = try XCTUnwrap(GameAPIError.from(.badStatus(409, body: body)) as? GameAPIError)

        XCTAssertTrue(gameError.isAlreadyDecided)
    }

    func test_aNonJsonFailureIsLeftAsTheTransportError() throws {
        let mapped = GameAPIError.from(.badStatus(500, body: "<html>Server Error</html>"))

        XCTAssertTrue(mapped is APIError, "only structured refusals become GameAPIError")
    }
}
