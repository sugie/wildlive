// WildLive — Presentation state for a single expedition.
//
// Three jobs, all of them the server's decisions relayed:
//   - load the expedition (which settles it if it is due, because the read
//     endpoint resolves lazily);
//   - resolve it explicitly when the player taps the button;
//   - release the capture, when the player would rather not keep it.
//
// KEEP is not here: naming is its own screen, and its own ViewModel.

import Foundation
import Observation

@Observable
final class ExpeditionDetailViewModel {
    var expedition: Expedition?
    var isLoading = false
    var isActing = false
    var errorMessage: String?

    private let playerID: String
    private let expeditionID: String
    private let repository: ExpeditionRepository
    private let resolveExpedition: ResolveExpedition
    private let decideCapture: DecideCapturedAnimal
    private let notifier: ExpeditionNotifying
    private let onOverviewChanged: (PlayerOverview) -> Void

    init(
        playerID: String,
        expeditionID: String,
        repository: ExpeditionRepository,
        resolveExpedition: ResolveExpedition,
        decideCapture: DecideCapturedAnimal,
        notifier: ExpeditionNotifying,
        onOverviewChanged: @escaping (PlayerOverview) -> Void
    ) {
        self.playerID = playerID
        self.expeditionID = expeditionID
        self.repository = repository
        self.resolveExpedition = resolveExpedition
        self.decideCapture = decideCapture
        self.notifier = notifier
        self.onOverviewChanged = onOverviewChanged
    }

    var canResolve: Bool {
        guard let expedition else { return false }
        return !expedition.isResolved && expedition.isDue
    }

    var secondsRemaining: Int {
        guard let expedition, !expedition.isResolved else { return 0 }
        return max(0, Int(expedition.endsAt.timeIntervalSinceNow.rounded()))
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await repository.get(playerID: playerID, expeditionID: expeditionID)
            expedition = loaded
            errorMessage = nil
            // The read endpoint settles a due expedition on the way out, so
            // simply opening this screen can beat the reminder to it.
            await cancelReminderIfSettled(loaded)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resolve() async {
        guard !isActing else { return }
        isActing = true
        defer { isActing = false }
        do {
            let resolved = try await resolveExpedition(playerID: playerID, expeditionID: expeditionID)
            expedition = resolved
            errorMessage = nil
            await cancelReminderIfSettled(resolved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func release() async {
        guard !isActing else { return }
        isActing = true
        defer { isActing = false }
        do {
            let decided = try await decideCapture.release(playerID: playerID, expeditionID: expeditionID)
            expedition = decided.expedition
            errorMessage = nil
            onOverviewChanged(decided.overview)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Drop the return reminder once the expedition it announces has been
    /// settled, so an alarm never fires for something already seen.
    private func cancelReminderIfSettled(_ expedition: Expedition) async {
        guard expedition.isResolved else { return }
        await notifier.cancelReturn(expeditionID: expedition.id)
    }
}
