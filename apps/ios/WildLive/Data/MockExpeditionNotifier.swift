// WildLive — ExpeditionNotifying for previews, UI tests and unit tests.
//
// Records what it was asked to do instead of doing it. A UI test must not
// trigger the system permission alert — an alert nobody dismisses hangs the
// run — and a preview has no business scheduling anything at all.
//
// An actor because the recorded calls are mutable state reachable from the
// concurrent contexts the ViewModels run in.

import Foundation

actor MockExpeditionNotifier: ExpeditionNotifying {
    /// What the fake permission prompt answers.
    private let grantsAuthorization: Bool

    private(set) var authorizationRequests = 0
    private(set) var scheduled: [String] = []
    private(set) var cancelled: [String] = []
    private(set) var resyncs: [[String]] = []
    private(set) var badgeCounts: [Int] = []

    init(grantsAuthorization: Bool = true) {
        self.grantsAuthorization = grantsAuthorization
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        authorizationRequests += 1
        return grantsAuthorization
    }

    func scheduleReturn(for expedition: Expedition) async {
        // Mirrors the real implementation's guards, so a test asserting
        // "nothing was scheduled for an already-settled expedition" is
        // testing the same rule the device would apply.
        guard !expedition.isResolved, expedition.endsAt > Date() else { return }
        scheduled.append(expedition.id)
    }

    func cancelReturn(expeditionID: String) async {
        cancelled.append(expeditionID)
    }

    func resync(with expeditions: [Expedition]) async {
        resyncs.append(expeditions.map(\.id))
    }

    func setPendingDecisionCount(_ count: Int) async {
        badgeCounts.append(count)
    }
}
