// WildLive — ViewModel and use-case tests for the expedition loop.
//
// Repository fakes are hand-rolled rather than generated, so each test file
// also documents what the server is expected to do. Nothing here touches
// the network, SwiftUI, or AppStore.

import XCTest
@testable import WildLive

// MARK: - Fakes

/// Records every call and returns whatever the test set up.
final class FakeExpeditionRepository: ExpeditionRepository, @unchecked Sendable {
    var startResult: Result<Expedition, Error> = .failure(TestError.notConfigured)
    var getResult: Result<Expedition, Error> = .failure(TestError.notConfigured)
    var resolveResult: Result<Expedition, Error> = .failure(TestError.notConfigured)
    var keepResult: Result<Expedition, Error> = .failure(TestError.notConfigured)
    var releaseResult: Result<Expedition, Error> = .failure(TestError.notConfigured)
    var listResult: Result<[Expedition], Error> = .success([])

    private(set) var startCalls: [(mapID: String, hunterID: String, instant: Bool)] = []
    private(set) var keepCalls: [(expeditionID: String, name: String)] = []
    private(set) var resolveCallCount = 0
    private(set) var releaseCallCount = 0

    func start(playerID: String, mapID: String, hunterID: String, devInstantResolve: Bool) async throws -> Expedition {
        startCalls.append((mapID, hunterID, devInstantResolve))
        return try startResult.get()
    }

    func list(playerID: String) async throws -> [Expedition] {
        try listResult.get()
    }

    func get(playerID: String, expeditionID: String) async throws -> Expedition {
        try getResult.get()
    }

    func resolve(playerID: String, expeditionID: String) async throws -> Expedition {
        resolveCallCount += 1
        return try resolveResult.get()
    }

    func keep(playerID: String, expeditionID: String, name: String) async throws -> Expedition {
        keepCalls.append((expeditionID, name))
        return try keepResult.get()
    }

    func release(playerID: String, expeditionID: String) async throws -> Expedition {
        releaseCallCount += 1
        return try releaseResult.get()
    }
}

final class FakeProfileRepository: PlayerProfileRepository, @unchecked Sendable {
    var overviewResult: Result<PlayerOverview, Error>
    var zooResult: Result<ZooContents, Error> = .failure(TestError.notConfigured)
    private(set) var overviewCallCount = 0

    init(overview: PlayerOverview = .fixture()) {
        self.overviewResult = .success(overview)
    }

    func overview(playerID: String) async throws -> PlayerOverview {
        overviewCallCount += 1
        return try overviewResult.get()
    }

    func zoo(playerID: String) async throws -> ZooContents {
        try zooResult.get()
    }
}

final class FakeCatalogRepository: GameCatalogRepository, @unchecked Sendable {
    var mapsResult: Result<[GameMap], Error> = .success([])
    var mapDetailResult: Result<GameMap, Error> = .failure(TestError.notConfigured)
    var huntersResult: Result<[Hunter], Error> = .success([])
    private(set) var huntersMapIDs: [String?] = []

    func maps(playerID: String) async throws -> [GameMap] {
        try mapsResult.get()
    }

    func mapDetail(playerID: String, mapID: String) async throws -> GameMap {
        try mapDetailResult.get()
    }

    func hunters(forMapID mapID: String?) async throws -> [Hunter] {
        huntersMapIDs.append(mapID)
        return try huntersResult.get()
    }
}

enum TestError: Error, LocalizedError {
    case notConfigured
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "test double not configured"
        case .server(let message): return message
        }
    }
}

// MARK: - Fixtures

extension PlayerOverview {
    static func fixture(
        gBalance: Int = 1000,
        zooValue: Int = 0,
        animalCount: Int = 0,
        pendingDecisions: Int = 0
    ) -> PlayerOverview {
        PlayerOverview(
            playerID: "player-1",
            displayName: "Tester",
            gBalance: gBalance,
            zoo: ZooSummary(id: "zoo-1", zooValue: zooValue, animalCount: animalCount),
            activeExpeditions: 0,
            pendingDecisions: pendingDecisions
        )
    }
}

extension AnimalSpecies {
    static func impala() -> AnimalSpecies {
        AnimalSpecies(
            id: "animal_impala_001", nameEN: "Impala", nameJA: "インパラ",
            rarity: Rarity(id: "rarity_common", nameEN: "Common", nameJA: "コモン", sortOrder: 1),
            baseZooValue: 10, captureDifficulty: 1, descriptionEN: "Graceful."
        )
    }
}

extension Expedition {
    static func fixture(
        id: String = "exp-1",
        status: ExpeditionStatus = .resolved,
        outcome: ExpeditionOutcome? = .captured,
        decision: ExpeditionDecision? = nil,
        endsAt: Date = .distantPast,
        resolvedAt: Date? = Date(),
        isDue: Bool = true,
        awaitsDecision: Bool = true,
        species: AnimalSpecies? = .impala(),
        zooAnimal: ZooAnimal? = nil,
        devInstantResolve: Bool = false
    ) -> Expedition {
        Expedition(
            id: id, status: status, outcome: outcome, decision: decision,
            mapID: "map_kenyan_savanna_001", mapNameEN: "Kenyan Savanna",
            mapExpeditionMinutes: 10,
            hunterID: "hunter_amara_kone_001", hunterName: "Amara Koné", hunterRank: "Bronze",
            mapCostG: 50, contractCostG: 50, totalCostG: 100,
            plannedDurationMinutes: 10, devInstantResolve: devInstantResolve,
            startedAt: Date(timeIntervalSince1970: 0), endsAt: endsAt,
            resolvedAt: resolvedAt, decidedAt: decision == nil ? nil : Date(),
            isDue: isDue, awaitsDecision: awaitsDecision,
            resolution: species.map {
                ExpeditionResolution(encounteredSpecies: $0, captureChancePercent: 70, captureRoll: 12)
            },
            zooAnimal: zooAnimal
        )
    }
}

// MARK: - Use cases

final class StartExpeditionUseCaseTests: XCTestCase {

    func test_dispatch_passesThroughAndRefreshesTheOverview() async throws {
        let expeditions = FakeExpeditionRepository()
        expeditions.startResult = .success(.fixture(status: .inProgress, outcome: nil, awaitsDecision: false))
        let profiles = FakeProfileRepository(overview: .fixture(gBalance: 900))

        let useCase = StartExpedition(expeditions: expeditions, profiles: profiles)
        let started = try await useCase(
            playerID: "player-1",
            mapID: "map_kenyan_savanna_001",
            hunterID: "hunter_amara_kone_001"
        )

        XCTAssertEqual(started.expedition.mapID, "map_kenyan_savanna_001")
        XCTAssertEqual(started.overview.gBalance, 900,
                       "dispatching costs G, so the caller gets a fresh balance")
        XCTAssertEqual(profiles.overviewCallCount, 1)
    }

    func test_devInstantResolveIsForwardedButDefaultsOff() async throws {
        let expeditions = FakeExpeditionRepository()
        expeditions.startResult = .success(.fixture())
        let useCase = StartExpedition(expeditions: expeditions, profiles: FakeProfileRepository())

        _ = try await useCase(playerID: "p", mapID: "m", hunterID: "h")
        _ = try await useCase(playerID: "p", mapID: "m", hunterID: "h", devInstantResolve: true)

        XCTAssertEqual(expeditions.startCalls.map(\.instant), [false, true],
                       "a normal dispatch never asks for the development shortcut")
    }

    func test_aRefusedDispatchPropagatesAndSkipsTheOverviewRefresh() async {
        let expeditions = FakeExpeditionRepository()
        expeditions.startResult = .failure(TestError.server("This expedition costs 4550 G. You have 1000 G."))
        let profiles = FakeProfileRepository()

        let useCase = StartExpedition(expeditions: expeditions, profiles: profiles)

        do {
            _ = try await useCase(playerID: "p", mapID: "m", hunterID: "h")
            XCTFail("the refusal should have propagated")
        } catch {
            XCTAssertEqual(error.localizedDescription,
                           "This expedition costs 4550 G. You have 1000 G.")
        }
        XCTAssertEqual(profiles.overviewCallCount, 0,
                       "nothing changed, so nothing needs re-reading")
    }
}

final class DecideCapturedAnimalUseCaseTests: XCTestCase {

    func test_keep_trimsTheNameAndReturnsTheKeptAnimal() async throws {
        let animal = ZooAnimal(id: "a-1", name: "Nala", species: .impala(),
                               capturedAt: Date(), capturedFromMapID: nil, capturedByHunterID: nil)
        let expeditions = FakeExpeditionRepository()
        expeditions.keepResult = .success(.fixture(decision: .kept, awaitsDecision: false, zooAnimal: animal))
        let profiles = FakeProfileRepository(overview: .fixture(zooValue: 10, animalCount: 1))

        let useCase = DecideCapturedAnimal(expeditions: expeditions, profiles: profiles)
        let decided = try await useCase.keep(playerID: "p", expeditionID: "exp-1", name: "  Nala  ")

        XCTAssertEqual(expeditions.keepCalls.first?.name, "Nala")
        XCTAssertEqual(decided.keptAnimal?.name, "Nala")
        XCTAssertEqual(decided.overview.zoo.animalCount, 1)
    }

    func test_keep_sendsABlankNameThroughSoTheServerDecidesTheFallback() async throws {
        let expeditions = FakeExpeditionRepository()
        expeditions.keepResult = .success(.fixture(decision: .kept, awaitsDecision: false))

        let useCase = DecideCapturedAnimal(expeditions: expeditions, profiles: FakeProfileRepository())
        _ = try await useCase.keep(playerID: "p", expeditionID: "exp-1", name: "   ")

        XCTAssertEqual(expeditions.keepCalls.first?.name, "",
                       "the species-name fallback lives on the server, in one place")
    }

    func test_release_keepsNothing() async throws {
        let expeditions = FakeExpeditionRepository()
        expeditions.releaseResult = .success(
            .fixture(decision: .released, awaitsDecision: false, zooAnimal: nil)
        )

        let useCase = DecideCapturedAnimal(expeditions: expeditions, profiles: FakeProfileRepository())
        let decided = try await useCase.release(playerID: "p", expeditionID: "exp-1")

        XCTAssertEqual(decided.expedition.decision, .released)
        XCTAssertNil(decided.keptAnimal)
        XCTAssertEqual(expeditions.releaseCallCount, 1)
    }
}

// MARK: - ViewModels

final class HomeViewModelTests: XCTestCase {

    func test_load_publishesTheSnapshotAndNotifiesTheStore() async {
        let profiles = FakeProfileRepository(overview: .fixture(gBalance: 750, animalCount: 3))
        var received: PlayerOverview?

        let viewModel = HomeViewModel(playerID: "p", profiles: profiles) { received = $0 }
        await viewModel.load()

        XCTAssertEqual(viewModel.overview?.gBalance, 750)
        XCTAssertEqual(received?.zoo.animalCount, 3)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_load_surfacesAFailureWithoutClearingTheScreen() async {
        let profiles = FakeProfileRepository()
        profiles.overviewResult = .failure(TestError.server("Network error"))
        var notified = false

        let viewModel = HomeViewModel(playerID: "p", profiles: profiles) { _ in notified = true }
        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, "Network error")
        XCTAssertNil(viewModel.overview)
        XCTAssertFalse(notified, "a failed load must not push a stale snapshot into the store")
    }
}

final class MyZooViewModelTests: XCTestCase {

    func test_load_reportsPersistedAnimals() async {
        let profiles = FakeProfileRepository()
        profiles.zooResult = .success(ZooContents(
            summary: ZooSummary(id: "z", zooValue: 10, animalCount: 1),
            animals: [ZooAnimal(id: "a-1", name: "Nala", species: .impala(),
                                capturedAt: nil, capturedFromMapID: nil, capturedByHunterID: nil)]
        ))

        let viewModel = MyZooViewModel(playerID: "p", profiles: profiles)
        await viewModel.load()

        XCTAssertEqual(viewModel.animalCount, 1)
        XCTAssertEqual(viewModel.zooValue, 10)
        XCTAssertEqual(viewModel.animals.first?.name, "Nala")
        XCTAssertFalse(viewModel.isEmpty)
    }

    func test_anEmptyZooIsEmptyOnlyAfterLoading() async {
        let profiles = FakeProfileRepository()
        profiles.zooResult = .success(ZooContents(
            summary: ZooSummary(id: "z", zooValue: 0, animalCount: 0), animals: []
        ))

        let viewModel = MyZooViewModel(playerID: "p", profiles: profiles)
        XCTAssertFalse(viewModel.isEmpty, "before loading, 'empty' would be a lie")

        await viewModel.load()
        XCTAssertTrue(viewModel.isEmpty)
    }
}

final class ExpeditionDetailViewModelTests: XCTestCase {

    private func makeViewModel(
        repository: FakeExpeditionRepository,
        onOverviewChanged: @escaping (PlayerOverview) -> Void = { _ in }
    ) -> ExpeditionDetailViewModel {
        ExpeditionDetailViewModel(
            playerID: "p",
            expeditionID: "exp-1",
            repository: repository,
            resolveExpedition: ResolveExpedition(expeditions: repository),
            decideCapture: DecideCapturedAnimal(expeditions: repository, profiles: FakeProfileRepository()),
            onOverviewChanged: onOverviewChanged
        )
    }

    func test_loadingAnUnresolvedButDueExpeditionOffersResolve() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture(
            status: .inProgress, outcome: nil, resolvedAt: nil,
            isDue: true, awaitsDecision: false, species: nil
        ))

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        XCTAssertTrue(viewModel.canResolve)
    }

    func test_anExpeditionStillInTheFieldCannotBeResolved() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture(
            status: .inProgress, outcome: nil, endsAt: Date().addingTimeInterval(600),
            resolvedAt: nil, isDue: false, awaitsDecision: false, species: nil
        ))

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        XCTAssertFalse(viewModel.canResolve)
        XCTAssertGreaterThan(viewModel.secondsRemaining, 0)
    }

    func test_anAlreadyResolvedExpeditionIsNotOfferedForResolution() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture())

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        XCTAssertFalse(viewModel.canResolve, "resolution happens exactly once")
        XCTAssertEqual(viewModel.expedition?.outcome, .captured)
    }

    func test_resolve_publishesTheOutcome() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture(
            status: .inProgress, outcome: nil, resolvedAt: nil, awaitsDecision: false, species: nil
        ))
        repository.resolveResult = .success(.fixture())

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()
        await viewModel.resolve()

        XCTAssertEqual(repository.resolveCallCount, 1)
        XCTAssertEqual(viewModel.expedition?.outcome, .captured)
        XCTAssertEqual(viewModel.expedition?.resolution?.encounteredSpecies?.nameEN, "Impala")
    }

    func test_release_recordsTheDecisionAndRefreshesTheOverview() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture())
        repository.releaseResult = .success(.fixture(decision: .released, awaitsDecision: false))
        var refreshed = false

        let viewModel = makeViewModel(repository: repository) { _ in refreshed = true }
        await viewModel.load()
        await viewModel.release()

        XCTAssertEqual(viewModel.expedition?.decision, .released)
        XCTAssertTrue(refreshed)
    }

    func test_aFailedActionSurfacesTheServerMessage() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture())
        repository.releaseResult = .failure(TestError.server("This capture was already kept."))

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()
        await viewModel.release()

        XCTAssertEqual(viewModel.errorMessage, "This capture was already kept.")
    }
}

final class CaptureNameViewModelTests: XCTestCase {

    private func makeViewModel(
        repository: FakeExpeditionRepository,
        onKept: @escaping (ZooAnimal?, PlayerOverview) -> Void = { _, _ in }
    ) -> CaptureNameViewModel {
        CaptureNameViewModel(
            playerID: "p",
            expeditionID: "exp-1",
            repository: repository,
            decideCapture: DecideCapturedAnimal(expeditions: repository, profiles: FakeProfileRepository()),
            onKept: onKept
        )
    }

    func test_effectiveName_fallsBackToTheSpeciesName() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture())

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        XCTAssertEqual(viewModel.effectiveName, "Impala", "a blank field previews the species name")

        viewModel.name = "  Nala  "
        XCTAssertEqual(viewModel.effectiveName, "Nala")

        viewModel.name = "   "
        XCTAssertEqual(viewModel.effectiveName, "Impala", "whitespace is not a name")
    }

    func test_keep_reportsTheAnimalItPersisted() async {
        let animal = ZooAnimal(id: "a-1", name: "Nala", species: .impala(),
                               capturedAt: nil, capturedFromMapID: nil, capturedByHunterID: nil)
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture())
        repository.keepResult = .success(.fixture(decision: .kept, awaitsDecision: false, zooAnimal: animal))

        var kept: ZooAnimal?
        let viewModel = makeViewModel(repository: repository) { animal, _ in kept = animal }
        await viewModel.load()
        viewModel.name = "Nala"
        await viewModel.keep()

        XCTAssertEqual(kept?.name, "Nala")
        XCTAssertEqual(repository.keepCalls.first?.name, "Nala")
    }

    func test_cannotSaveOnceTheCaptureHasBeenHandled() async {
        let repository = FakeExpeditionRepository()
        repository.getResult = .success(.fixture(decision: .kept, awaitsDecision: false))

        let viewModel = makeViewModel(repository: repository)
        await viewModel.load()

        XCTAssertFalse(viewModel.canSave)
    }
}

final class HunterListViewModelTests: XCTestCase {

    private func hunter(id: String, totalCost: Int?) -> Hunter {
        Hunter(
            id: id, name: id, nameJA: id, rank: "Bronze", level: 1, specialty: "Test",
            preferredBiomeID: "biome_savanna", captureBonus: 0, rareFindBonus: 0, speedBonus: 0,
            contractCostG: 50, personality: "", hunterDescription: "",
            costing: totalCost.map { HunterCosting(biomeAffinity: true, totalCostG: $0, durationMinutes: 10) }
        )
    }

    func test_withAMap_theServerIsAskedToPriceTheRoster() async {
        let catalog = FakeCatalogRepository()
        catalog.huntersResult = .success([hunter(id: "h1", totalCost: 100)])

        let viewModel = HunterListViewModel(mapID: "map_kenyan_savanna_001", catalog: catalog)
        await viewModel.load()

        XCTAssertEqual(catalog.huntersMapIDs, ["map_kenyan_savanna_001"])
        XCTAssertTrue(viewModel.isPickingForExpedition)
        XCTAssertEqual(viewModel.hunters.first?.costing?.totalCostG, 100)
    }

    func test_withoutAMap_theRosterIsJustBrowsable() async {
        let catalog = FakeCatalogRepository()
        catalog.huntersResult = .success([hunter(id: "h1", totalCost: nil)])

        let viewModel = HunterListViewModel(mapID: nil, catalog: catalog)
        await viewModel.load()

        XCTAssertEqual(catalog.huntersMapIDs, [nil])
        XCTAssertFalse(viewModel.isPickingForExpedition)
    }

    func test_affordabilityUsesTheQuotedTotalNotTheContractFee() async {
        let catalog = FakeCatalogRepository()
        let expensive = hunter(id: "h1", totalCost: 610)
        catalog.huntersResult = .success([expensive])

        let viewModel = HunterListViewModel(mapID: "m", catalog: catalog)
        await viewModel.load()

        XCTAssertFalse(viewModel.isAffordable(expensive, balance: 600))
        XCTAssertTrue(viewModel.isAffordable(expensive, balance: 610))
        XCTAssertTrue(viewModel.isAffordable(expensive, balance: nil),
                      "with no known balance, do not pre-emptively block the player")
    }
}

final class MapListViewModelTests: XCTestCase {

    private func map(id: String, unlocked: Bool, unlockValue: Int = 0) -> GameMap {
        GameMap(
            id: id, nameEN: id, nameJA: id, region: "East Africa", biomeID: "biome_savanna",
            mapRole: "general", difficulty: 1, riskLevel: 1, expeditionMinutes: 10,
            baseCostG: 50, recommendedHunterRank: 1,
            unlockRule: unlocked ? "always" : "zoo_value", unlockValue: unlockValue,
            unlocked: unlocked, descriptionEN: "", spawns: []
        )
    }

    func test_splitsUnlockedFromLocked() async {
        let catalog = FakeCatalogRepository()
        catalog.mapsResult = .success([
            map(id: "open", unlocked: true),
            map(id: "closed", unlocked: false, unlockValue: 100),
        ])

        let viewModel = MapListViewModel(playerID: "p", catalog: catalog)
        await viewModel.load()

        XCTAssertEqual(viewModel.unlockedMaps.map(\.id), ["open"])
        XCTAssertEqual(viewModel.lockedMaps.map(\.id), ["closed"])
        XCTAssertEqual(viewModel.lockedMaps.first?.unlockRequirement, "Unlocks at Zoo value 100")
    }
}

final class MapDetailViewModelTests: XCTestCase {

    private func spawn(_ name: String, rarity: Int, weight: Int) -> MapSpawn {
        MapSpawn(
            species: AnimalSpecies(
                id: name, nameEN: name, nameJA: name,
                rarity: Rarity(id: "r\(rarity)", nameEN: "R\(rarity)", nameJA: "", sortOrder: rarity),
                baseZooValue: 10, captureDifficulty: 1, descriptionEN: ""
            ),
            spawnWeight: weight, captureModifier: 0
        )
    }

    func test_spawnsAreOrderedRarestFirst() async {
        let catalog = FakeCatalogRepository()
        catalog.mapDetailResult = .success(GameMap(
            id: "m", nameEN: "M", nameJA: "M", region: "", biomeID: "biome_savanna",
            mapRole: "starter", difficulty: 1, riskLevel: 1, expeditionMinutes: 10,
            baseCostG: 50, recommendedHunterRank: 1, unlockRule: "always", unlockValue: 0,
            unlocked: true, descriptionEN: "",
            spawns: [spawn("Impala", rarity: 1, weight: 35),
                     spawn("Lion", rarity: 3, weight: 6),
                     spawn("Leopard", rarity: 2, weight: 8)]
        ))

        let viewModel = MapDetailViewModel(playerID: "p", mapID: "m", catalog: catalog)
        await viewModel.load()

        XCTAssertEqual(viewModel.spawnsByRarity.map(\.species.nameEN), ["Lion", "Leopard", "Impala"])
    }

    func test_encounterShareIsTheSpawnWeightFraction() async {
        let catalog = FakeCatalogRepository()
        catalog.mapDetailResult = .success(GameMap(
            id: "m", nameEN: "M", nameJA: "M", region: "", biomeID: "biome_savanna",
            mapRole: "starter", difficulty: 1, riskLevel: 1, expeditionMinutes: 10,
            baseCostG: 50, recommendedHunterRank: 1, unlockRule: "always", unlockValue: 0,
            unlocked: true, descriptionEN: "",
            spawns: [spawn("A", rarity: 1, weight: 75), spawn("B", rarity: 1, weight: 25)]
        ))

        let viewModel = MapDetailViewModel(playerID: "p", mapID: "m", catalog: catalog)
        await viewModel.load()

        let a = try! XCTUnwrap(viewModel.spawnsByRarity.first { $0.species.nameEN == "A" })
        XCTAssertEqual(viewModel.encounterShare(a), 0.75, accuracy: 0.0001)
    }
}
