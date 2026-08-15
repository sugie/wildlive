// WildLive — Data-layer unit tests for UserDefaultsPlayerSessionRepository.
//
// Uses an isolated `UserDefaults(suiteName:)` per test so `UserDefaults.standard`
// is never touched.

import XCTest
@testable import WildLive

final class UserDefaultsPlayerSessionRepositoryTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "dev.wildlive.tests." + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_load_returns_nil_when_empty() {
        let repo = UserDefaultsPlayerSessionRepository(defaults: defaults)
        XCTAssertNil(repo.load())
    }

    func test_save_then_load_round_trips() {
        let repo = UserDefaultsPlayerSessionRepository(defaults: defaults)
        let registered = RegisteredPlayer(
            playerId: "P-1", displayName: "Kai", zooId: "Z-1", createdAt: Date()
        )

        repo.save(registered)
        let loaded = repo.load()

        XCTAssertEqual(loaded, PersistedSession(playerId: "P-1", displayName: "Kai", zooId: "Z-1"))
    }

    func test_clear_removes_stored_session() {
        let repo = UserDefaultsPlayerSessionRepository(defaults: defaults)
        repo.save(RegisteredPlayer(playerId: "P-1", displayName: "Kai", zooId: "Z-1", createdAt: nil))
        XCTAssertNotNil(repo.load())

        repo.clear()

        XCTAssertNil(repo.load())
    }

    func test_load_returns_nil_when_only_partial_state_present() {
        // Manually poke the defaults so only playerId is set — should be
        // treated as "no session".
        defaults.set("P-1", forKey: "wildlive.playerId")
        defaults.set("", forKey: "wildlive.displayName")
        // zooId deliberately absent.

        let repo = UserDefaultsPlayerSessionRepository(defaults: defaults)
        XCTAssertNil(repo.load(), "partial session must not be resurrected as a valid one")
    }

    func test_two_instances_share_the_same_suite() {
        let a = UserDefaultsPlayerSessionRepository(defaults: defaults)
        let b = UserDefaultsPlayerSessionRepository(defaults: defaults)
        a.save(RegisteredPlayer(playerId: "P-9", displayName: "Zed", zooId: "Z-9", createdAt: nil))
        XCTAssertEqual(b.load()?.playerId, "P-9")
    }

    func test_does_not_touch_standard_defaults() {
        // Snapshot a marker in `.standard` and prove repo operations do
        // not disturb it. (`.standard` might contain other unrelated keys;
        // we only assert about our own keys.)
        let standard = UserDefaults.standard
        standard.removeObject(forKey: "wildlive.playerId")
        standard.removeObject(forKey: "wildlive.displayName")
        standard.removeObject(forKey: "wildlive.zooId")

        let repo = UserDefaultsPlayerSessionRepository(defaults: defaults)
        repo.save(RegisteredPlayer(playerId: "P-1", displayName: "Kai", zooId: "Z-1", createdAt: nil))

        XCTAssertNil(standard.string(forKey: "wildlive.playerId"))
        XCTAssertNil(standard.string(forKey: "wildlive.displayName"))
        XCTAssertNil(standard.string(forKey: "wildlive.zooId"))
    }
}
