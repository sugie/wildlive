// WildLive — First-time player registration service.
//
// Protocol + Live impl (calls `POST /api/players` through APIClient) + Mock
// impl (used by UI tests via launch argument). The whole rest of the app
// depends only on the protocol — swapping the concrete instance is enough.

import Foundation

struct RegisteredPlayer: Equatable {
    let playerId: String
    let displayName: String
    let zooId: String
    let createdAt: Date?
}

protocol PlayerRegistrationServiceProtocol: AnyObject {
    func register(displayName: String) async -> Result<RegisteredPlayer, APIError>
}

// MARK: - Live (real HTTP)

final class LivePlayerRegistrationService: PlayerRegistrationServiceProtocol {
    private let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
    }

    private struct Request: Encodable {
        let display_name: String
    }

    private struct Response: Decodable {
        struct Player: Decodable {
            let id: String
            let display_name: String
            let created_at: Date?
        }
        struct Zoo: Decodable {
            let id: String
            let created_at: Date?
        }
        let player: Player
        let zoo: Zoo
    }

    func register(displayName: String) async -> Result<RegisteredPlayer, APIError> {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = await api.post(
            path: "players",
            body: Request(display_name: trimmed),
            as: Response.self
        )
        return result.map { r in
            RegisteredPlayer(
                playerId: r.player.id,
                displayName: r.player.display_name,
                zooId: r.zoo.id,
                createdAt: r.player.created_at
            )
        }
    }
}

// MARK: - Mock (UI tests only)

final class MockPlayerRegistrationService: PlayerRegistrationServiceProtocol {
    func register(displayName: String) async -> Result<RegisteredPlayer, APIError> {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return .success(
            RegisteredPlayer(
                playerId: "00000000-0000-0000-0000-00000000cafe",
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                zooId: "00000000-0000-0000-0000-00000000beef",
                createdAt: Date()
            )
        )
    }
}
