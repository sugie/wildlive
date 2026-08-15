// WildLive — Presentation-layer unit tests for RegistrationViewModel.
//
// No Simulator, no SwiftUI rendering, no URLSession. The use case is
// composed against in-memory fakes so this file only exercises the
// ViewModel's state-transition logic.

import XCTest
@testable import WildLive

final class RegistrationViewModelTests: XCTestCase {

    // MARK: initial state

    func test_initial_state() {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        XCTAssertEqual(vm.displayName, "")
        XCTAssertFalse(vm.isSubmitting)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.canSubmit, "empty name is not submittable")
    }

    // MARK: input validation (mirrors Laravel's 2..32 rule)

    func test_canSubmit_false_when_name_too_short() {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        vm.displayName = "A"
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_false_when_name_too_long() {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        vm.displayName = String(repeating: "x", count: 33)
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_true_when_name_valid() {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        vm.displayName = "Kai"
        XCTAssertTrue(vm.canSubmit)
    }

    func test_canSubmit_uses_trimmed_length() {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        vm.displayName = "  A  " // trimmed = "A" — still too short
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: submission — success path

    func test_submit_success_invokes_onSuccess_with_registered_player() async {
        var received: RegisteredPlayer?
        let vm = makeViewModel(
            playerRepo: FakePlayerRepository(mode: .succeed(playerId: "P-42")),
            onSuccess: { received = $0 }
        )
        vm.displayName = "Kai"
        await vm.submit()

        XCTAssertEqual(received?.playerId, "P-42")
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isSubmitting, "isSubmitting flips back to false after completion")
    }

    // MARK: submission — failure path

    func test_submit_failure_sets_error_message_and_does_not_invoke_onSuccess() async {
        struct SimulatedNetworkError: LocalizedError {
            var errorDescription: String? { "Simulated network error" }
        }
        var successInvocations = 0
        let vm = makeViewModel(
            playerRepo: FakePlayerRepository(mode: .fail(SimulatedNetworkError())),
            onSuccess: { _ in successInvocations += 1 }
        )
        vm.displayName = "Kai"
        await vm.submit()

        XCTAssertEqual(vm.errorMessage, "Simulated network error")
        XCTAssertEqual(successInvocations, 0)
        XCTAssertFalse(vm.isSubmitting)
    }

    // MARK: re-entry guard

    func test_submit_ignored_when_already_submitting() async {
        let vm = makeViewModel(playerRepo: FakePlayerRepository(mode: .succeed()))
        vm.displayName = "Kai"
        vm.isSubmitting = true // simulate a submission already in flight
        await vm.submit()
        XCTAssertTrue(vm.isSubmitting, "second submit must not clear the flag")
    }

    func test_submit_ignored_when_name_invalid() async {
        var successInvocations = 0
        let vm = makeViewModel(
            playerRepo: FakePlayerRepository(mode: .succeed()),
            onSuccess: { _ in successInvocations += 1 }
        )
        vm.displayName = "A"
        await vm.submit()
        XCTAssertEqual(successInvocations, 0)
    }

    // MARK: helpers

    private func makeViewModel(
        playerRepo: PlayerRepository,
        onSuccess: @escaping (RegisteredPlayer) -> Void = { _ in }
    ) -> RegistrationViewModel {
        let sessions = InMemorySessionRepository()
        let useCase = RegisterPlayer(players: playerRepo, sessions: sessions)
        return RegistrationViewModel(registerPlayer: useCase, onSuccess: onSuccess)
    }
}

// -- Fakes --------------------------------------------------------------------

/// Instant PlayerRepository double: no latency, either succeeds with a
/// configurable id or throws a configured error.
private final class FakePlayerRepository: PlayerRepository {
    enum Mode {
        case succeed(playerId: String = "P-1")
        case fail(Error)
    }
    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func register(displayName: String) async throws -> RegisteredPlayer {
        switch mode {
        case .succeed(let playerId):
            return RegisteredPlayer(
                playerId: playerId,
                displayName: displayName,
                zooId: "Z-\(playerId.dropFirst(2))",
                createdAt: nil
            )
        case .fail(let error):
            throw error
        }
    }
}

private final class InMemorySessionRepository: PlayerSessionRepository {
    func load() -> PersistedSession? { nil }
    func save(_ registered: RegisteredPlayer) {}
    func clear() {}
}
