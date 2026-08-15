// WildLive — UserDefaults-backed PlayerSessionRepository.
//
// The suite is injectable so tests can use `UserDefaults(suiteName:)` and
// leave the real `standard` defaults untouched.

import Foundation

final class UserDefaultsPlayerSessionRepository: PlayerSessionRepository {
    private enum Keys {
        static let playerId    = "wildlive.playerId"
        static let displayName = "wildlive.displayName"
        static let zooId       = "wildlive.zooId"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PersistedSession? {
        guard
            let playerId = defaults.string(forKey: Keys.playerId), !playerId.isEmpty,
            let displayName = defaults.string(forKey: Keys.displayName),
            let zooId = defaults.string(forKey: Keys.zooId), !zooId.isEmpty
        else { return nil }
        return PersistedSession(playerId: playerId, displayName: displayName, zooId: zooId)
    }

    func save(_ registered: RegisteredPlayer) {
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
