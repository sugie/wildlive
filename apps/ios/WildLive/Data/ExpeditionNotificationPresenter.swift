// WildLive — Makes return reminders visible while the app is open.
//
// iOS suppresses a local notification's banner whenever the app that
// scheduled it is frontmost, unless a delegate says otherwise. Without this
// object a player sitting on the Map list when their Hunter is due back
// sees nothing at all, and the reminder looks broken rather than absent.
//
// A Hunter returning is worth interrupting for wherever the player happens
// to be, so the banner is presented in the foreground too.
//
// Deliberately not a router: tapping is left to the system's default of
// foregrounding the app. The pending-decision row on Home leads to the same
// place, and a deep link is a separate change.

import Foundation
import UserNotifications

final class ExpeditionNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    /// Installs itself as the notification centre's delegate.
    ///
    /// Must be called before any notification could be delivered, i.e. at
    /// launch — the delegate is consulted at delivery time, not at
    /// scheduling time, so setting it late loses banners.
    ///
    /// - Returns: the presenter, which the caller must keep alive. The
    ///   notification centre holds its delegate weakly.
    @discardableResult
    static func install(on center: UNUserNotificationCenter = .current()) -> ExpeditionNotificationPresenter {
        let presenter = ExpeditionNotificationPresenter()
        center.delegate = presenter
        return presenter
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
