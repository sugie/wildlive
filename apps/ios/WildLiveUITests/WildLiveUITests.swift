// WildLive — Milestone 001 UI tests.
//
// Deliberately minimal. This suite exists to prove that the title
// screen actually shows the WildLive brand and a functional START
// button. It intentionally does NOT drive any post-tap flow — the
// next screen has not been designed yet.

import XCTest

final class WildLiveUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The Milestone-001 acceptance check: on launch, the title
    /// screen exposes the WildLive brand, the subtitle, and a
    /// tappable START button.
    func test_titleScreen_showsBrandingAndTappableStartButton() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["WildLive"]
        XCTAssertTrue(
            title.waitForExistence(timeout: 5),
            "Title text 'WildLive' should be visible on launch"
        )

        // SwiftUI's `.textCase(.uppercase)` transforms the subtitle for
        // both display and accessibility, so XCUITest sees the uppercase
        // form here — not the mixed-case source string in TitleView.swift.
        let subtitle = app.staticTexts["AI MADE LIVE MMO"]
        XCTAssertTrue(
            subtitle.exists,
            "Subtitle should be visible on launch (matched against SwiftUI's .textCase(.uppercase) transformation)"
        )

        let startButton = app.buttons["startButton"]
        XCTAssertTrue(
            startButton.waitForExistence(timeout: 2),
            "START button should exist (accessibilityIdentifier 'startButton')"
        )
        XCTAssertTrue(
            startButton.isHittable,
            "START button should be hittable — no other view should be obscuring it"
        )

        // Milestone 001 §19: tapping must not crash and must not
        // transition to a new screen. Verify by tapping and then
        // re-asserting that the title is still on-screen.
        startButton.tap()
        XCTAssertTrue(
            title.exists,
            "Title should still be visible after tapping START (Milestone 001 does not navigate away yet)"
        )
    }
}
