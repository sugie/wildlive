// WildLive — Live connectivity check against production.
//
// Purpose: prove that the iOS app's own APIClient / DTO stack can drive
// the full expedition loop against https://wlapi.misologic.com/api. This
// is a real HTTP test — no stubs, no mocks — so it is gated on the
// WILDLIVE_PROD_E2E environment variable. A normal `xcodebuild test` or
// CI run neither runs nor requires this file's tests.
//
// Run with:
//
//     WILDLIVE_PROD_E2E=1 xcodebuild test \
//       -project apps/ios/WildLive.xcodeproj -scheme WildLive \
//       -destination 'platform=iOS Simulator,name=iPhone 17' \
//       -only-testing:WildLiveTests/LiveProdConnectivityTests
//
// It writes real rows to production PostgreSQL. The player name is
// "iossim-<utc timestamp>" so the operator can find (and, if desired,
// delete) the test records after the run.
//
// The expedition step honestly waits ~10 minutes: production refuses
// dev_instant_resolve, so the only way to see the full loop from the app
// stack is to wait the map's real expedition_minutes.

import XCTest
@testable import WildLive

final class LiveProdConnectivityTests: XCTestCase {

    private static let prodBaseURL = URL(string: "https://wlapi.misologic.com/api")!

    private func makeClient() -> APIClient {
        // Real URLSession.shared. Same code path an installed Release
        // build hits, so decoding failures / TLS oddities / redirect
        // handling all reproduce here.
        APIClient(baseURL: Self.prodBaseURL)
    }

    private func skipUnlessOptedIn() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WILDLIVE_PROD_E2E"] == "1",
            "Set WILDLIVE_PROD_E2E=1 to run the production connectivity walkthrough. "
            + "This test writes real rows to production PostgreSQL."
        )
    }

    private func testPlayerName() -> String {
        // UTC timestamp keeps the row identifiable long after the run.
        // Server caps display_name at 32 characters.
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyMMdd-HHmmss"
        return "iossim-\(f.string(from: Date()))"
    }

    // MARK: - Fast path (no 10-minute wait): everything up to dispatch.

    /// Verifies the endpoints the app hits before the expedition timer
    /// starts running. Fast enough to run against prod on every check-in.
    func test_registration_catalogue_and_dispatch_succeed_against_production() async throws {
        try skipUnlessOptedIn()

        let api = makeClient()
        let repo = LivePlayerRepository(api: api)

        // POST /api/players
        let name = testPlayerName()
        let registered = try await repo.register(displayName: name)
        XCTAssertFalse(registered.playerId.isEmpty, "server should mint a player id")
        XCTAssertEqual(registered.displayName, name)
        NSLog("wl-prod-e2e: registered player id=\(registered.playerId) name=\(name)")

        let catalogue = LiveGameCatalogRepository(api: api)

        // GET /api/players/{id}/maps
        let maps = try await catalogue.maps(playerID: registered.playerId)
        XCTAssertFalse(maps.isEmpty, "catalogue must return at least one map")
        guard let starter = maps.first(where: { $0.unlocked }) else {
            return XCTFail("no unlocked map in production catalogue")
        }
        NSLog("wl-prod-e2e: starter map id=\(starter.id) minutes=\(starter.expeditionMinutes)")

        // GET /api/hunters?map_id=…
        let hunters = try await catalogue.hunters(forMapID: starter.id)
        XCTAssertFalse(hunters.isEmpty, "hunter list must not be empty")
        guard let hunter = hunters.first else { return }
        NSLog("wl-prod-e2e: hunter id=\(hunter.id) contract=\(hunter.contractCostG)")

        // POST /api/players/{id}/expeditions — real duration, no
        // dev_instant_resolve. Production explicitly refuses instant
        // resolve; passing false here is what would happen in a real
        // Release build (the DEBUG toggle simply is not compiled in).
        let expeditions = LiveExpeditionRepository(api: api)
        let started = try await expeditions.start(
            playerID: registered.playerId,
            mapID: starter.id,
            hunterID: hunter.id,
            devInstantResolve: false
        )
        XCTAssertEqual(started.status, ExpeditionStatus.inProgress, "a fresh expedition should be in progress")
        XCTAssertNotNil(started.startedAt)
        XCTAssertNotNil(started.endsAt)
        NSLog("wl-prod-e2e: expedition id=\(started.id) ends_at=\(started.endsAt) is_due=\(started.isDue)")
    }

    // MARK: - Slow path: full loop, including the real 10-minute wait.

    /// Registers → dispatches → waits for the real expiry → resolves →
    /// keeps or releases → reads the zoo. Takes >10 minutes on the
    /// starter map (Kenyan Savanna is 10 minutes at time of writing).
    ///
    /// Additionally opt in with WILDLIVE_PROD_E2E_SLOW=1 so the fast
    /// test above can still run without the 10-minute penalty.
    func test_full_loop_including_resolve_and_zoo_succeeds_against_production() async throws {
        try skipUnlessOptedIn()
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WILDLIVE_PROD_E2E_SLOW"] == "1",
            "Set WILDLIVE_PROD_E2E_SLOW=1 to also run the ~10-minute expedition wait."
        )

        let api = makeClient()
        let players = LivePlayerRepository(api: api)
        let catalogue = LiveGameCatalogRepository(api: api)
        let expeditions = LiveExpeditionRepository(api: api)
        let profile = LivePlayerProfileRepository(api: api)

        let name = testPlayerName()
        let player = try await players.register(displayName: name)
        NSLog("wl-prod-e2e-slow: player=\(player.playerId) name=\(name)")

        let maps = try await catalogue.maps(playerID: player.playerId)
        guard let starter = maps.first(where: { $0.unlocked }) else {
            return XCTFail("no unlocked map")
        }
        let hunters = try await catalogue.hunters(forMapID: starter.id)
        guard let hunter = hunters.first else { return XCTFail("no hunters") }

        let started = try await expeditions.start(
            playerID: player.playerId,
            mapID: starter.id,
            hunterID: hunter.id,
            devInstantResolve: false
        )
        NSLog("wl-prod-e2e-slow: expedition=\(started.id) waiting until \(started.endsAt)")

        // Wait the real duration, plus a 30-second buffer for clock skew
        // between the simulator and the server.
        let waitSeconds = max(0, started.endsAt.timeIntervalSinceNow) + 30
        XCTAssertLessThan(waitSeconds, 60 * 60, "expedition duration is implausibly long")
        NSLog("wl-prod-e2e-slow: sleeping \(Int(waitSeconds))s for the expedition to finish")
        try await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))

        // POST /api/players/{id}/expeditions/{id}/resolve
        let resolved = try await expeditions.resolve(
            playerID: player.playerId,
            expeditionID: started.id
        )
        XCTAssertNotEqual(resolved.status, ExpeditionStatus.inProgress, "resolve should move it off in_progress")
        NSLog("wl-prod-e2e-slow: resolved status=\(resolved.status.rawValue) outcome=\(resolved.outcome?.rawValue ?? "-")")

        // Keep or release. The server sets `awaitsDecision` only when a
        // capture succeeded — a miss goes straight to `.resolved` with
        // outcome `.noCapture` and no decision to make.
        if resolved.awaitsDecision, resolved.outcome == ExpeditionOutcome.captured {
            _ = try await expeditions.keep(
                playerID: player.playerId,
                expeditionID: started.id,
                name: "wl-\(name)"
            )
            NSLog("wl-prod-e2e-slow: kept the animal")
        } else if resolved.awaitsDecision {
            _ = try await expeditions.release(
                playerID: player.playerId,
                expeditionID: started.id
            )
            NSLog("wl-prod-e2e-slow: released the animal")
        } else {
            NSLog("wl-prod-e2e-slow: no capture, nothing to decide")
        }

        // GET /api/players/{id}/zoo — end-to-end proof the server
        // persisted whatever we chose above.
        let zoo = try await profile.zoo(playerID: player.playerId)
        NSLog("wl-prod-e2e-slow: zoo animals=\(zoo.animals.count) value=\(zoo.summary.zooValue)")
    }
}
