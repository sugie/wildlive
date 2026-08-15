// WildLive — In-memory PlayerRepository for UI tests and SwiftUI Previews.
//
// UI-first workflow: any screen that consumes PlayerRepository can be
// developed and previewed against this mock without booting Laravel or
// PostgreSQL.

import Foundation

final class MockPlayerRepository: PlayerRepository {
    /// If non-nil, `register` throws this instead of returning a fake player.
    var errorToThrow: Error?

    /// Simulated latency so callers can exercise their "isSubmitting"
    /// state in previews without staring at an instant transition.
    var simulatedLatencyNanos: UInt64 = 300_000_000

    init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }

    func register(displayName: String) async throws -> RegisteredPlayer {
        if simulatedLatencyNanos > 0 {
            try? await Task.sleep(nanoseconds: simulatedLatencyNanos)
        }
        if let errorToThrow {
            throw errorToThrow
        }
        return RegisteredPlayer(
            playerId: "00000000-0000-0000-0000-00000000cafe",
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            zooId: "00000000-0000-0000-0000-00000000beef",
            createdAt: Date()
        )
    }
}
