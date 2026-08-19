// WildLive — Presentation state for HomeView.
//
// Loads the player's server snapshot and hands it to an injected closure
// so this ViewModel stays independent of AppStore. Presentation-only: no
// URLSession, no UserDefaults, no Data-layer type.

import Foundation
import Observation

@Observable
final class HomeViewModel {
    var overview: PlayerOverview?
    var isLoading = false
    var errorMessage: String?

    private let playerID: String
    private let profiles: PlayerProfileRepository
    private let notifier: ExpeditionNotifying
    private let onLoaded: (PlayerOverview) -> Void

    init(
        playerID: String,
        profiles: PlayerProfileRepository,
        notifier: ExpeditionNotifying,
        onLoaded: @escaping (PlayerOverview) -> Void
    ) {
        self.playerID = playerID
        self.profiles = profiles
        self.notifier = notifier
        self.onLoaded = onLoaded
    }

    /// Refresh the snapshot. Called every time Home appears, because an
    /// expedition resolved on another screen changes what Home should say.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await profiles.overview(playerID: playerID)
            overview = snapshot
            errorMessage = nil
            onLoaded(snapshot)
            // The overview already carries the count, so the badge costs no
            // extra request. Home reloads on every appearance, which is the
            // same cadence the badge wants.
            await notifier.setPendingDecisionCount(snapshot.pendingDecisions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
