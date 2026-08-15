// WildLive — UI tests.
//
// Since Milestone 002 the START button navigates into a Home dashboard
// (own Zoo status, Buy G, navigation cards). These tests exercise the
// title-to-home hand-off and the top-level navigation surfaces of the
// UI prototype. They do NOT exercise the full contract → dispatch →
// resolve loop — that flow is deliberately time-based (a few seconds
// per Region) and belongs in a longer manual playthrough.

import XCTest

final class WildLiveUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Title screen shows the WildLive brand, the subtitle, and a
    /// tappable START button (Milestone 001 acceptance, retained).
    func test_titleScreen_showsBrandingAndTappableStartButton() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["WildLive"]
        XCTAssertTrue(title.waitForExistence(timeout: 5),
                      "Title text 'WildLive' should be visible on launch")

        // SwiftUI's .textCase(.uppercase) also transforms the accessibility
        // string, so XCUITest sees the uppercase form.
        let subtitle = app.staticTexts["AI MADE LIVE MMO"]
        XCTAssertTrue(subtitle.exists,
                      "Subtitle should be visible on launch")

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2),
                      "START button should exist")
        XCTAssertTrue(startButton.isHittable,
                      "START button should be hittable")
    }

    /// Milestone 002: START advances to the Home dashboard.
    func test_startAdvancesToHomeDashboard() throws {
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Home dashboard exposes a Buy G button in the status card and
        // navigation cards for the main sections.
        XCTAssertTrue(app.buttons["buyGButton"].waitForExistence(timeout: 3),
                      "Home should expose the 'Buy G' quick-action button")
        XCTAssertTrue(app.buttons["navMyZoo"].exists,
                      "Home should offer the My Zoo navigation card")
        XCTAssertTrue(app.buttons["navGuild"].exists,
                      "Home should offer the Guild navigation card")
        XCTAssertTrue(app.buttons["navExpeditions"].exists,
                      "Home should offer the Expeditions navigation card")
        XCTAssertTrue(app.buttons["navStore"].exists,
                      "Home should offer the Store navigation card")
    }

    /// Milestone 002: navigation cards push the expected destinations.
    func test_homeNavigationCards_pushDestinations() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["startButton"].tap()

        // My Zoo
        XCTAssertTrue(app.buttons["navMyZoo"].waitForExistence(timeout: 3))
        app.buttons["navMyZoo"].tap()
        XCTAssertTrue(app.otherElements["myZooView"].waitForExistence(timeout: 2)
                      || app.navigationBars["My Zoo"].waitForExistence(timeout: 2),
                      "Tapping My Zoo should push the My Zoo screen")
        app.navigationBars.buttons.firstMatch.tap()

        // Guild
        XCTAssertTrue(app.buttons["navGuild"].waitForExistence(timeout: 3))
        app.buttons["navGuild"].tap()
        XCTAssertTrue(app.navigationBars["Guild"].waitForExistence(timeout: 2),
                      "Tapping Guild should push the Guild screen")
        app.navigationBars.buttons.firstMatch.tap()

        // Store
        XCTAssertTrue(app.buttons["navStore"].waitForExistence(timeout: 3))
        app.buttons["navStore"].tap()
        XCTAssertTrue(app.navigationBars["Buy G"].waitForExistence(timeout: 2),
                      "Tapping Store should push the Buy G screen")
    }
}
