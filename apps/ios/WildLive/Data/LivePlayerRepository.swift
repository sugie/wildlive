// WildLive — Real HTTP-backed PlayerRepository implementation.
//
// Calls POST /api/players on the local Laravel via APIClient. This is the
// only file allowed to touch APIClient for registration; the Application
// Layer talks to the PlayerRepository protocol instead.

import Foundation

final class LivePlayerRepository: PlayerRepository {
    private let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
    }

    func register(displayName: String) async throws -> RegisteredPlayer {
        let result = await api.post(
            path: "players",
            body: PlayerRegistrationRequestDTO(display_name: displayName),
            as: PlayerRegistrationResponseDTO.self
        )
        switch result {
        case .success(let dto):
            return dto.toDomain()
        case .failure(let error):
            throw error
        }
    }
}
