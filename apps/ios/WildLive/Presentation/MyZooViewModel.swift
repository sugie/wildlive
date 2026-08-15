// WildLive — Presentation state for My Zoo.
//
// Every animal here came out of PostgreSQL. There is no client-side zoo and
// no local cache: if it is on this screen, the server persisted it.

import Foundation
import Observation

@Observable
final class MyZooViewModel {
    var contents: ZooContents?
    var isLoading = false
    var errorMessage: String?

    private let playerID: String
    private let profiles: PlayerProfileRepository

    init(playerID: String, profiles: PlayerProfileRepository) {
        self.playerID = playerID
        self.profiles = profiles
    }

    var animals: [ZooAnimal] { contents?.animals ?? [] }
    var zooValue: Int { contents?.summary.zooValue ?? 0 }
    var animalCount: Int { contents?.summary.animalCount ?? 0 }
    /// Only "empty" once the server has actually answered. Before the
    /// first load there is no zoo, empty or otherwise, and telling the
    /// player their zoo is empty would be a guess.
    var isEmpty: Bool { contents != nil && animals.isEmpty }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            contents = try await profiles.zoo(playerID: playerID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
