// WildLive — First-time registration use case.
//
// Sits between the Presentation Layer (RegistrationViewModel) and the
// Data Layer (PlayerRepository, PlayerSessionRepository). Owns the
// application-flow rule "on successful registration, persist the
// session so subsequent launches skip the form".
//
// Framework-free: no SwiftUI, no URLSession, no UserDefaults, no
// AppStore. The use case does not know a persistence backend exists — it
// only sees two protocols.

import Foundation

final class RegisterPlayer {
    private let players: PlayerRepository
    private let sessions: PlayerSessionRepository

    init(players: PlayerRepository, sessions: PlayerSessionRepository) {
        self.players = players
        self.sessions = sessions
    }

    /// Register and persist. Any error from the repository propagates
    /// as-is; on success, the returned `RegisteredPlayer` has already
    /// been handed to the session repository.
    @discardableResult
    func callAsFunction(_ input: RegisterPlayerInput) async throws -> RegisteredPlayer {
        let trimmed = input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let registered = try await players.register(displayName: trimmed)
        sessions.save(registered)
        return registered
    }
}
