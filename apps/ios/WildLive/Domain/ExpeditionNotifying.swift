// WildLive — Contract for telling the player their Hunter is back.
//
// Expeditions are timestamps, not running processes: `ends_at` is fixed the
// moment one is dispatched and nothing on the server is watching the clock
// (an expired expedition is resolved lazily, when something asks for it).
// So there is no server-side moment at which a push could be sent, and
// adding a scheduler or a queue purely to manufacture one would be new
// infrastructure for no other purpose.
//
// A local notification needs none of that. The return time is already
// known and already in the future, so the device can hold the reminder
// itself. See the decision record: notifications are local, not APNs.
//
// The scheduled reminder is a projection of server state, never a source of
// truth. It says only that the Hunter is due back — the outcome does not
// exist yet at the moment it fires, because resolution happens when the
// player (or anything else) asks. Nothing here decides anything about the
// game.
//
// Framework-free: no UserNotifications, no SwiftUI. The Data layer supplies
// the implementation that talks to the system.

import Foundation

protocol ExpeditionNotifying: AnyObject, Sendable {
    /// Ask for permission to post return reminders and show a badge.
    ///
    /// Safe to call repeatedly: the system prompts at most once per install,
    /// and answers from its stored decision afterwards. Callers therefore do
    /// not need to track whether they have asked before.
    ///
    /// - Returns: whether reminders may be posted. A refusal is not an
    ///   error — the game is fully playable without notifications, and the
    ///   pending-decision row on Home covers the same ground.
    @discardableResult
    func requestAuthorization() async -> Bool

    /// Schedule the return reminder for one expedition.
    ///
    /// A no-op when the expedition is already resolved or its `endsAt` has
    /// passed; there is nothing to look forward to in either case.
    /// Re-scheduling the same expedition replaces the previous reminder
    /// rather than adding a second one.
    func scheduleReturn(for expedition: Expedition) async

    /// Drop the pending reminder for one expedition, because it has been
    /// settled ahead of its own alarm.
    func cancelReturn(expeditionID: String) async

    /// Make the pending reminders match this list exactly.
    ///
    /// Called with a freshly fetched expedition list so a reinstall, a
    /// restore, or a resolution that happened on another device converges
    /// back to what the server actually says. Reminders this app scheduled
    /// for expeditions absent from the list are removed.
    func resync(with expeditions: [Expedition]) async

    /// Reflect how many captures the player still has to keep or release.
    func setPendingDecisionCount(_ count: Int) async
}
