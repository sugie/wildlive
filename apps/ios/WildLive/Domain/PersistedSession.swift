// WildLive — Domain value: the shape of a persisted player session.
//
// Framework-free by design. Storage details (UserDefaults, Keychain, …)
// live in the Data layer.

import Foundation

struct PersistedSession: Equatable {
    let playerId: String
    let displayName: String
    let zooId: String
}
