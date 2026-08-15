// WildLive — Domain value: the result of a successful player registration.
//
// Framework-free by design. No SwiftUI, no URLSession, no UserDefaults.

import Foundation

struct RegisteredPlayer: Equatable {
    let playerId: String
    let displayName: String
    let zooId: String
    let createdAt: Date?
}
