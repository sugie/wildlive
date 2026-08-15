// WildLive — Persistent record of the registered player.
//
// Milestone 002 uses UserDefaults because there is no auth token to protect
// and the only real state is the server-issued player identifier. When auth
// arrives, this class is the single place to swap for Keychain.

import Foundation

struct PersistedSession: Equatable {
    let playerId: String
    let displayName: String
    let zooId: String
}

final class PlayerSession {
    private enum Keys {
        static let playerId    = "wildlive.playerId"
        static let displayName = "wildlive.displayName"
        static let zooId       = "wildlive.zooId"
    }

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
    }

    func restore() -> PersistedSession? {
        guard
            let playerId = defaults.string(forKey: Keys.playerId), !playerId.isEmpty,
            let displayName = defaults.string(forKey: Keys.displayName),
            let zooId = defaults.string(forKey: Keys.zooId), !zooId.isEmpty
        else { return nil }
        return PersistedSession(playerId: playerId, displayName: displayName, zooId: zooId)
    }

    func persist(_ registered: RegisteredPlayer) {
        defaults.set(registered.playerId,    forKey: Keys.playerId)
        defaults.set(registered.displayName, forKey: Keys.displayName)
        defaults.set(registered.zooId,       forKey: Keys.zooId)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.playerId)
        defaults.removeObject(forKey: Keys.displayName)
        defaults.removeObject(forKey: Keys.zooId)
    }
}
