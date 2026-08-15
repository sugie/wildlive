// WildLive — Domain contract for player-session persistence.
//
// The Application Layer talks to this; the Data Layer provides the
// concrete implementation (UserDefaultsPlayerSessionRepository). When a
// Keychain / OAuth token appears, only the Data implementation changes.

import Foundation

protocol PlayerSessionRepository: AnyObject {
    func load() -> PersistedSession?
    func save(_ registered: RegisteredPlayer)
    func clear()
}
