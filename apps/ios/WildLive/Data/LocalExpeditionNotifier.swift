// WildLive — ExpeditionNotifying backed by UNUserNotificationCenter.
//
// The only file in the app that touches the UserNotifications framework.
//
// Every request this schedules is identified by `expedition-return.<id>`,
// which does two jobs: scheduling the same expedition twice replaces the
// first request instead of stacking a duplicate, and `resync` can tell its
// own requests apart from anything else the app might post later.

import Foundation
import UserNotifications

final class LocalExpeditionNotifier: ExpeditionNotifying {
    private static let identifierPrefix = "expedition-return."

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    // MARK: Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // A failure to ask is not a failure to play. Swallow it: the
            // caller is in the middle of dispatching an expedition and must
            // not be interrupted because the notification prompt misfired.
            return false
        }
    }

    // MARK: Scheduling

    func scheduleReturn(for expedition: Expedition) async {
        guard let request = Self.makeRequest(for: expedition, now: Date()) else { return }
        try? await center.add(request)
    }

    func cancelReturn(expeditionID: String) async {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.identifier(for: expeditionID)]
        )
    }

    func resync(with expeditions: [Expedition]) async {
        let now = Date()
        let wanted = expeditions.compactMap { Self.makeRequest(for: $0, now: now) }
        let wantedIdentifiers = Set(wanted.map(\.identifier))

        // Drop only our own stale requests. Anything the app posts for other
        // reasons in future is none of this method's business.
        let pending = await center.pendingNotificationRequests()
        let obsolete = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) && !wantedIdentifiers.contains($0) }

        if !obsolete.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
        }

        for request in wanted {
            try? await center.add(request)
        }
    }

    // MARK: Badge

    func setPendingDecisionCount(_ count: Int) async {
        try? await center.setBadgeCount(max(0, count))
    }

    // MARK: Request construction

    private static func identifier(for expeditionID: String) -> String {
        identifierPrefix + expeditionID
    }

    /// The request for one expedition, or nil when there is nothing to
    /// announce.
    ///
    /// Pure and static so the scheduling rules — what is worth a reminder,
    /// and what the reminder says — can be tested without a notification
    /// centre.
    static func makeRequest(for expedition: Expedition, now: Date) -> UNNotificationRequest? {
        guard !expedition.isResolved else { return nil }
        guard expedition.endsAt > now else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Your Hunter is back"
        // Deliberately no outcome. At the moment this fires the server has
        // not resolved anything — resolution happens when the player opens
        // the expedition — so there is no result to report, and inventing
        // one here would make the client the authority on a capture.
        content.body = "\(expedition.hunterName) has returned from \(expedition.mapNameEN). "
            + "Open WildLive to see what they found."
        content.sound = .default
        content.userInfo = ["expeditionID": expedition.id]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, expedition.endsAt.timeIntervalSince(now)),
            repeats: false
        )

        return UNNotificationRequest(
            identifier: identifier(for: expedition.id),
            content: content,
            trigger: trigger
        )
    }
}
