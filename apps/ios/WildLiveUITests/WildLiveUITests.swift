// WildLive — UI tests.
//
// Since Milestone 002 (Task 010) the app has a real registration gate.
// UI tests inject state via launch arguments handled by WildLiveApp.init:
//
//   --ui-tests-mock-api        → swaps LivePlayerRegistrationService for
//                                MockPlayerRegistrationService (no HTTP).
//   --ui-tests-preregistered   → seeds a fake persisted session so the
//                                app treats the launch as "already
//                                registered" and START goes straight to
//                                Home. Used by tests that only care about
//                                the post-registration UI.
//   --ui-tests-fresh           → clears any persisted session on launch.
//                                Used by the registration-flow test so
//                                each run starts blank.

import XCTest

final class WildLiveUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += extraArgs
        app.launch()
        return app
    }

    // MARK: - Milestone 001 — title screen

    /// Title screen shows branding + a tappable START button.
    /// Uses the pre-registered launch arg so we don't depend on the real
    /// API being running.
    func test_titleScreen_showsBrandingAndTappableStartButton() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])

        let title = app.staticTexts["WildLive"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "Title text 'WildLive' should be visible on launch")

        let subtitle = app.staticTexts["AI MADE LIVE MMO"]
        XCTAssertTrue(subtitle.exists,
                      "Subtitle should be visible on launch")

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2),
                      "START button should exist")
        XCTAssertTrue(startButton.isHittable,
                      "START button should be hittable")
    }

    // MARK: - Milestone 002 — post-START (assumes existing session)

    /// With a pre-seeded session, START advances straight to Home.
    func test_startAdvancesToHomeDashboard() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()

        XCTAssertTrue(app.buttons["buyGButton"].waitForExistence(timeout: 3),
                      "Home should expose the 'Buy G' quick-action button")
        XCTAssertTrue(app.buttons["navMyZoo"].exists)
        XCTAssertTrue(app.buttons["navGuild"].exists)
        XCTAssertTrue(app.buttons["navExpeditions"].exists)
        XCTAssertTrue(app.buttons["navStore"].exists)
    }

    /// Navigation cards on Home push the expected destinations.
    func test_homeNavigationCards_pushDestinations() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()

        XCTAssertTrue(app.buttons["navMyZoo"].waitForExistence(timeout: 3))
        app.buttons["navMyZoo"].tap()
        XCTAssertTrue(app.navigationBars["My Zoo"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(app.buttons["navGuild"].waitForExistence(timeout: 3))
        app.buttons["navGuild"].tap()
        XCTAssertTrue(app.navigationBars["Guild"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(app.buttons["navStore"].waitForExistence(timeout: 3))
        app.buttons["navStore"].tap()
        XCTAssertTrue(app.navigationBars["Buy G"].waitForExistence(timeout: 2))
    }

    // MARK: - Milestone 002 — registration flow (Task 010)

    /// Fresh launch (no session): START → Registration form → submit →
    /// Home. Uses the mock service so the test does not need the real
    /// Laravel API to be running.
    func test_firstLaunch_presentsRegistrationThenHome() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-fresh"])

        app.buttons["startButton"].tap()

        let nameField = app.textFields["displayNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3),
                      "Registration form should appear after START on a fresh install")

        nameField.tap()
        nameField.typeText("Kai")

        let register = app.buttons["registerButton"]
        XCTAssertTrue(register.waitForExistence(timeout: 2))
        XCTAssertTrue(register.isEnabled, "Register should be enabled once name is 2+ chars")
        register.tap()

        XCTAssertTrue(app.buttons["buyGButton"].waitForExistence(timeout: 5),
                      "Home dashboard should appear after successful registration")
    }

    // MARK: - Real end-to-end (opt-in)

    /// Real end-to-end: SwiftUI → Laravel → PostgreSQL. Self-gated: if the
    /// local Laravel API is not reachable at
    /// `http://localhost:8000/api/health`, the test is skipped rather than
    /// failed, so this file can stay in the default suite without breaking
    /// CI or a fresh checkout that has not started Docker.
    ///
    /// To run intentionally:
    ///
    ///     docker compose up -d
    ///     docker compose exec app php artisan migrate
    ///     docker compose exec postgres psql -U wildlive -d wildlive \
    ///         -c "TRUNCATE zoos, players CASCADE;"
    ///     xcodebuild test ... \
    ///         -only-testing:WildLiveUITests/WildLiveUITests/test_realAPI_endToEndRegistration
    func test_realAPI_endToEndRegistration() throws {
        guard Self.isLiveAPIReachable() else {
            throw XCTSkip("Local Laravel API not reachable at http://localhost:8000/api/health — skipping the real end-to-end test.")
        }

        let app = launch(["--ui-tests-fresh"])
        app.buttons["startButton"].tap()

        let nameField = app.textFields["displayNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("E2ETestFromSimulator")

        app.buttons["registerButton"].tap()

        XCTAssertTrue(app.buttons["buyGButton"].waitForExistence(timeout: 15),
                      "Home dashboard should appear after real API registration")
    }

    // MARK: - Screenshot capture (for social manifest)

    /// Captures a screenshot of the Home dashboard immediately after START.
    /// Uses the pre-seeded session so no API is called. Screenshot lands as
    /// an XCTAttachment in the .xcresult bundle; extract with `xcrun
    /// xcresulttool` after running the test to a known bundle path:
    ///
    ///     xcodebuild test ... \
    ///         -resultBundlePath /tmp/wl-shot.xcresult \
    ///         -only-testing:'WildLiveUITests/WildLiveUITests/test_captureHomeScreenshotForDocs'
    ///     xcrun xcresulttool export attachments \
    ///         --path /tmp/wl-shot.xcresult --output-path /tmp/wl-shots
    func test_captureHomeScreenshotForDocs() throws {
        let app = launch(["--ui-tests-mock-api", "--ui-tests-preregistered"])
        app.buttons["startButton"].tap()
        XCTAssertTrue(app.buttons["buyGButton"].waitForExistence(timeout: 5))
        // Small settle so any nav-bar animation completes before capture.
        _ = XCUIApplication().wait(for: .runningForeground, timeout: 1)
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "wildlive-home-post-registration"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Non-Test helper — synchronous ping so the test can self-gate.
    private static func isLiveAPIReachable() -> Bool {
        guard let url = URL(string: "http://localhost:8000/api/health") else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        var ok = false
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let http = response as? HTTPURLResponse, http.statusCode == 200 { ok = true }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 3)
        return ok
    }
}
