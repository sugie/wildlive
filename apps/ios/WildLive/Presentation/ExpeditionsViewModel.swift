// WildLive — Presentation state for the expedition list.
//
// A read-only view: the list endpoint deliberately does not resolve
// anything, so opening an expedition is what settles it. That keeps a
// screen refresh from fanning out into a pile of writes.

import Foundation
import Observation

@Observable
final class ExpeditionsViewModel {
    var expeditions: [Expedition] = []
    var isLoading = false
    var errorMessage: String?

    private let playerID: String
    private let repository: ExpeditionRepository
    private let notifier: ExpeditionNotifying

    init(
        playerID: String,
        repository: ExpeditionRepository,
        notifier: ExpeditionNotifying
    ) {
        self.playerID = playerID
        self.repository = repository
        self.notifier = notifier
    }

    var ongoing: [Expedition] { expeditions.filter { !$0.isResolved } }
    var awaitingDecision: [Expedition] { expeditions.filter(\.awaitsDecision) }
    var settled: [Expedition] {
        expeditions.filter { $0.isResolved && !$0.awaitsDecision }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            expeditions = try await repository.list(playerID: playerID)
            errorMessage = nil
            // The authoritative list just arrived, so this is the cheapest
            // honest moment to make the pending reminders match it.
            await notifier.resync(with: expeditions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
