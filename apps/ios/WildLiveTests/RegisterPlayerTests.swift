// WildLive — Application-layer unit tests for the RegisterPlayer use case.
//
// No HTTP, no PostgreSQL, no Simulator. Uses hand-rolled in-memory fakes
// for the Domain protocols so the test file also documents what each
// repository is expected to do.

import XCTest
@testable import WildLive

final class RegisterPlayerTests: XCTestCase {

    func test_success_returns_registered_player_and_persists_session() async throws {
        let players = InMemoryPlayerRepository(returning: .init(
            playerId: "P-1", displayName: "Kai", zooId: "Z-1", createdAt: nil
        ))
        let sessions = InMemorySessionRepository()

        let useCase = RegisterPlayer(players: players, sessions: sessions)
        let result = try await useCase(RegisterPlayerInput(displayName: "Kai"))

        XCTAssertEqual(result.playerId, "P-1")
        XCTAssertEqual(result.displayName, "Kai")
        XCTAssertEqual(sessions.saved?.playerId, "P-1",
                       "session repository must receive the registered player on success")
    }

    func test_calls_repository_with_trimmed_display_name() async throws {
        let players = InMemoryPlayerRepository(returning: .init(
            playerId: "P-1", displayName: "Rin", zooId: "Z-1", createdAt: nil
        ))
        let useCase = RegisterPlayer(players: players, sessions: InMemorySessionRepository())

        _ = try await useCase(RegisterPlayerInput(displayName: "  Rin  "))

        XCTAssertEqual(players.receivedDisplayNames, ["Rin"],
                       "use case trims whitespace before handing to the repository")
    }

    func test_repository_failure_propagates_and_nothing_is_persisted() async {
        struct Boom: Error {}
        let players = InMemoryPlayerRepository(errorToThrow: Boom())
        let sessions = InMemorySessionRepository()

        let useCase = RegisterPlayer(players: players, sessions: sessions)

        do {
            _ = try await useCase(RegisterPlayerInput(displayName: "Kai"))
            XCTFail("expected error to propagate")
        } catch is Boom {
            // Expected.
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        XCTAssertNil(sessions.saved,
                     "session must NOT be written if the repository throws")
    }

    func test_calls_repository_exactly_once() async throws {
        let players = InMemoryPlayerRepository(returning: .init(
            playerId: "P-1", displayName: "One", zooId: "Z-1", createdAt: nil
        ))
        let useCase = RegisterPlayer(players: players, sessions: InMemorySessionRepository())

        _ = try await useCase(RegisterPlayerInput(displayName: "One"))

        XCTAssertEqual(players.receivedDisplayNames.count, 1)
    }
}

// -- Fakes --------------------------------------------------------------------

private final class InMemoryPlayerRepository: PlayerRepository {
    private let returning: RegisteredPlayer?
    private let errorToThrow: Error?
    private(set) var receivedDisplayNames: [String] = []

    init(returning: RegisteredPlayer? = nil, errorToThrow: Error? = nil) {
        self.returning = returning
        self.errorToThrow = errorToThrow
    }

    func register(displayName: String) async throws -> RegisteredPlayer {
        receivedDisplayNames.append(displayName)
        if let errorToThrow { throw errorToThrow }
        guard let returning else {
            fatalError("InMemoryPlayerRepository: neither returning nor errorToThrow was set")
        }
        return returning
    }
}

private final class InMemorySessionRepository: PlayerSessionRepository {
    private(set) var saved: RegisteredPlayer?
    private(set) var loadedTimes = 0
    private(set) var clearedTimes = 0

    func load() -> PersistedSession? {
        loadedTimes += 1
        return nil
    }

    func save(_ registered: RegisteredPlayer) {
        saved = registered
    }

    func clear() {
        clearedTimes += 1
        saved = nil
    }
}
