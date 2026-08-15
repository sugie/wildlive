// WildLive — UI coverage for the expedition loop.
//
// Two kinds of test live here:
//
//   * Flow tests, run against the in-memory repositories
//     (`--ui-tests-mock-api`). They check that the screens connect up and
//     that each step leads to the next, without needing Laravel running.
//
//   * The real end-to-end test, which uses NO mocks: a real iOS app, the
//     real Laravel API, and real PostgreSQL. It is gated on the
//     WILDLIVE_E2E environment variable so a normal `xcodebuild test` or a
//     CI run does not fail on a machine with no backend — but when the
//     variable IS set, the test fails rather than skips. A silent skip is
//     how an end-to-end test quietly stops testing anything.
//
// Both use the `--ui-tests-instant-expeditions` launch argument, which
// pre-arms the dispatch screen's developer toggle. Canonical expedition
// durations start at 10 minutes; no UI test can wait that out. The server
// still decides whether to honour the request and refuses outside local
// and testing environments.

import XCTest

final class ExpeditionFlowUITests: XCTestCase {

    private static let expeditionTimeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ extraArgs: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += extraArgs
        app.launch()
        return app
    }

    // MARK: - Flow, against the in-memory repositories

    func test_home_offersTheExpeditionEntryPoint() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()

        XCTAssertTrue(app.buttons["navMaps"].waitForExistence(timeout: 5),
                      "Home should offer a way to send an expedition")
        XCTAssertTrue(app.staticTexts["gBalanceValue"].exists,
                      "Home should show the server-reported G balance")
    }

    func test_mapList_showsUnlockedAndLockedMaps() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()
        app.buttons["navMaps"].tap()

        XCTAssertTrue(app.navigationBars["Maps"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["mapRow_map_kenyan_savanna_001"].waitForExistence(timeout: 5),
                      "the starter map should be open")
        XCTAssertTrue(app.staticTexts["Locked"].exists || app.cells.count > 1,
                      "locked maps stay visible so a player can see what is next")
    }

    func test_mapDetail_listsTheAnimalsThatCanAppear() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()
        app.buttons["navMaps"].tap()
        app.buttons["mapRow_map_kenyan_savanna_001"].tap()

        XCTAssertTrue(app.navigationBars["Kenyan Savanna"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Impala"].waitForExistence(timeout: 5),
                      "the map's real spawn table should be listed")
        XCTAssertTrue(app.buttons["chooseHunterButton"].exists)
    }

    func test_hunterPicker_leadsToDispatchConfirmation() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()
        app.buttons["navMaps"].tap()
        app.buttons["mapRow_map_kenyan_savanna_001"].tap()
        app.buttons["chooseHunterButton"].tap()

        XCTAssertTrue(app.navigationBars["Hunters"].waitForExistence(timeout: 10))
        let hunter = app.buttons["hunterRow_hunter_amara_kone_001"]
        XCTAssertTrue(hunter.waitForExistence(timeout: 5))
        hunter.tap()

        XCTAssertTrue(app.navigationBars["Dispatch"].waitForExistence(timeout: 10))
        // The button is below the fold and SwiftUI builds Form rows lazily,
        // so assert on the quote, which is what the player is here to read.
        XCTAssertTrue(app.staticTexts["dispatchTotalCost"].waitForExistence(timeout: 10),
                      "the dispatch screen should quote the total cost")
    }

    func test_fullLoop_againstMockRepositories() throws {
        let app = launch([
            "--ui-tests-mock-api",
            "--ui-tests-preregistered",
            "--ui-tests-instant-expeditions",
        ])

        playTheLoop(app, animalName: "Mocky")

        XCTAssertTrue(app.navigationBars["My Zoo"].waitForExistence(timeout: Self.expeditionTimeout))
        XCTAssertTrue(app.staticTexts["zooAnimalName_Mocky"].waitForExistence(timeout: 10),
                      "the named animal should appear in My Zoo")
    }

    // MARK: - Real end-to-end: iOS → Laravel → PostgreSQL

    /// The whole vertical slice, with nothing mocked but the developer
    /// toggle that skips the 10-minute wait.
    ///
    /// Run it with:
    ///
    ///     docker compose up -d
    ///     docker compose exec app php artisan migrate --force
    ///     docker compose exec app php artisan db:seed --force
    ///     WILDLIVE_E2E=1 xcodebuild test \
    ///       -project WildLive.xcodeproj -scheme WildLive \
    ///       -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
    ///       -only-testing:WildLiveUITests/ExpeditionFlowUITests/test_realEndToEnd_registerDispatchResolveKeepAndSeeItInMyZoo
    func test_realEndToEnd_registerDispatchResolveKeepAndSeeItInMyZoo() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WILDLIVE_E2E"] == "1",
            "Set WILDLIVE_E2E=1 (with Laravel + PostgreSQL up) to run the real end-to-end test."
        )

        // No --ui-tests-mock-api: every call in this test hits the real API.
        let app = launch(["--ui-tests-fresh", "--ui-tests-instant-expeditions"])

        // 1. Registration, through POST /api/players.
        app.buttons["startButton"].tap()

        let nameField = app.textFields["displayNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10),
                      "a fresh install should present the registration form")
        nameField.tap()
        nameField.typeText("E2EZookeeper")
        app.buttons["registerButton"].tap()

        // 2. Home, populated from GET /api/players/{id}.
        XCTAssertTrue(app.navigationBars["WildLive"].waitForExistence(timeout: 20),
                      "Home should appear after registering against the real API")
        let balance = app.staticTexts["gBalanceValue"]
        XCTAssertTrue(balance.waitForExistence(timeout: 15),
                      "the real server should report a starting G balance")
        XCTAssertTrue(balance.label.contains("1,000") || balance.label.contains("1000"),
                      "a new player starts with 1000 G — got \(balance.label)")

        // 3..8. Maps → Hunter → dispatch → resolve → keep → name.
        let animalName = "E2ENala"
        playTheLoop(app, animalName: animalName)

        // 9. My Zoo, from GET /api/players/{id}/zoo — i.e. from PostgreSQL.
        XCTAssertTrue(app.navigationBars["My Zoo"].waitForExistence(timeout: Self.expeditionTimeout),
                      "keeping the animal should land the player in My Zoo")
        XCTAssertTrue(app.staticTexts["zooAnimalName_\(animalName)"].waitForExistence(timeout: 15),
                      "the animal the server persisted should be listed by the name we gave it")

        let count = app.staticTexts["zooAnimalCountValue"]
        XCTAssertTrue(count.waitForExistence(timeout: 5))
        XCTAssertTrue(count.label.hasSuffix("1"), "exactly one animal was kept — got \(count.label)")

        // 10. Leave and come back: proof it is server state, not screen state.
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["WildLive"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["animalCountValue"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["animalCountValue"].label.hasSuffix("1"),
                      "Home re-reads the count from the server and agrees with My Zoo")

        app.buttons["navMyZoo"].tap()
        XCTAssertTrue(app.staticTexts["zooAnimalName_\(animalName)"].waitForExistence(timeout: 15),
                      "the animal is still there after navigating away and back")
    }

    // MARK: - Screenshots

    /// Walks the real loop and attaches a screenshot at each step, for the
    /// development log. Same gate as the end-to-end test — these are
    /// pictures of the live app talking to the live server, not mock-ups.
    ///
    ///     TEST_RUNNER_WILDLIVE_E2E=1 xcodebuild test ... \
    ///       -resultBundlePath /tmp/wl-shots.xcresult \
    ///       -only-testing:WildLiveUITests/ExpeditionFlowUITests/test_captureExpeditionScreenshots
    ///     xcrun xcresulttool export attachments \
    ///       --path /tmp/wl-shots.xcresult --output-path /tmp/wl-shots
    func test_captureExpeditionScreenshots() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WILDLIVE_E2E"] == "1",
            "Set WILDLIVE_E2E=1 (with Laravel + PostgreSQL up) to capture live screenshots."
        )

        let app = launch(["--ui-tests-fresh", "--ui-tests-instant-expeditions"])

        app.buttons["startButton"].tap()
        let nameField = app.textFields["displayNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("ScreenshotKeeper")
        app.buttons["registerButton"].tap()

        XCTAssertTrue(app.navigationBars["WildLive"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["gBalanceValue"].waitForExistence(timeout: 15))
        snapshot("01-home")

        app.buttons["navMaps"].tap()
        XCTAssertTrue(app.buttons["mapRow_map_kenyan_savanna_001"].waitForExistence(timeout: 15))
        snapshot("02-map-selection")

        app.buttons["mapRow_map_kenyan_savanna_001"].tap()
        XCTAssertTrue(app.buttons["chooseHunterButton"].waitForExistence(timeout: 15))
        snapshot("03-map-detail-animals")

        app.buttons["chooseHunterButton"].tap()
        XCTAssertTrue(app.buttons["hunterRow_hunter_amara_kone_001"].waitForExistence(timeout: 15))
        snapshot("04-hunter-selection")

        app.buttons["hunterRow_hunter_amara_kone_001"].tap()
        XCTAssertTrue(app.navigationBars["Dispatch"].waitForExistence(timeout: 15))
        snapshot("05-dispatch-confirm")

        let dispatch = app.buttons["dispatchButton"]
        for _ in 0..<5 where !dispatch.isHittable { app.swipeUp() }
        dispatch.tap()

        XCTAssertTrue(app.navigationBars["Expedition"].waitForExistence(timeout: Self.expeditionTimeout))
        snapshot("06-expedition")

        let resolve = app.buttons["resolveButton"]
        if resolve.waitForExistence(timeout: 5), resolve.isEnabled {
            resolve.tap()
        }
        // Either a capture (Keep offered) or an honest miss — both are real
        // outcomes and both are worth a picture.
        _ = app.buttons["keepButton"].waitForExistence(timeout: Self.expeditionTimeout)
        snapshot("07-capture-result")

        guard app.buttons["keepButton"].exists else {
            snapshot("08-no-capture")
            return
        }

        app.buttons["keepButton"].tap()
        let animalName = app.textFields["animalNameField"]
        XCTAssertTrue(animalName.waitForExistence(timeout: 15))
        animalName.tap()
        animalName.typeText("Shutterbug")
        snapshot("08-naming")

        app.buttons["confirmKeepButton"].tap()
        XCTAssertTrue(app.navigationBars["My Zoo"].waitForExistence(timeout: Self.expeditionTimeout))
        XCTAssertTrue(app.staticTexts["zooAnimalName_Shutterbug"].waitForExistence(timeout: 15))
        snapshot("09-my-zoo")
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Shared journey

    /// Maps → map → hunter → dispatch → resolve → keep → name → My Zoo.
    ///
    /// Identical steps for the mocked and the real run; only the launch
    /// arguments differ. That is deliberate: the day the two need different
    /// steps is the day the mock has stopped resembling the server.
    private func playTheLoop(_ app: XCUIApplication, animalName: String) {
        if app.buttons["startButton"].waitForExistence(timeout: 5) {
            app.buttons["startButton"].tap()
        }

        // Maps
        let maps = app.buttons["navMaps"]
        XCTAssertTrue(maps.waitForExistence(timeout: 15), "Home should offer the Maps entry point")
        maps.tap()

        // Choose the starter map
        let starter = app.buttons["mapRow_map_kenyan_savanna_001"]
        XCTAssertTrue(starter.waitForExistence(timeout: 15), "the starter map should be unlocked")
        starter.tap()

        // Its spawn table, then on to the Guild
        let chooseHunter = app.buttons["chooseHunterButton"]
        XCTAssertTrue(chooseHunter.waitForExistence(timeout: 15))
        chooseHunter.tap()

        // Contract the cheapest hunter
        let hunter = app.buttons["hunterRow_hunter_amara_kone_001"]
        XCTAssertTrue(hunter.waitForExistence(timeout: 15))
        hunter.tap()

        // The dispatch screen is taller than the phone, and SwiftUI's Form
        // builds rows lazily — the bottom of the screen does not exist in
        // the accessibility tree until it has been scrolled to. Scroll
        // first, then assert.
        XCTAssertTrue(app.navigationBars["Dispatch"].waitForExistence(timeout: 15))
        let dispatch = app.buttons["dispatchButton"]
        for _ in 0..<5 where !dispatch.isHittable {
            app.swipeUp()
        }

        // The developer toggle is pre-armed by the launch argument; assert
        // it really is on, so a change to that wiring fails loudly here
        // rather than as a mysterious timeout later.
        let devToggle = app.switches["devInstantResolveToggle"]
        XCTAssertTrue(devToggle.waitForExistence(timeout: 10),
                      "the DEBUG-only developer toggle should be present")
        XCTAssertEqual(devToggle.value as? String, "1",
                       "--ui-tests-instant-expeditions should pre-arm the toggle")

        XCTAssertTrue(dispatch.isHittable, "the dispatch button should be reachable")
        dispatch.tap()

        // The expedition screen, reached automatically after dispatch
        XCTAssertTrue(app.navigationBars["Expedition"].waitForExistence(timeout: Self.expeditionTimeout),
                      "dispatching should open the expedition")

        // Resolve it. The screen may already have resolved it lazily on
        // load, in which case the button is gone and the capture is shown.
        let resolve = app.buttons["resolveButton"]
        if resolve.waitForExistence(timeout: 5), resolve.isEnabled {
            resolve.tap()
        }

        // Keep the capture
        let keep = app.buttons["keepButton"]
        XCTAssertTrue(keep.waitForExistence(timeout: Self.expeditionTimeout),
                      "a resolved capture should offer Keep")
        keep.tap()

        // Name it
        let nameField = app.textFields["animalNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 15))
        nameField.tap()
        nameField.typeText(animalName)

        app.buttons["confirmKeepButton"].tap()
    }
}
