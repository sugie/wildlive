// WildLive — Wire-format DTOs for the Laravel /api/players endpoint.
//
// Kept out of the Domain / Application layers because the shape is
// dictated by the server response, not by the game model. Only the Data
// Layer touches these types.

import Foundation

struct PlayerRegistrationRequestDTO: Encodable {
    let display_name: String
}

struct PlayerRegistrationResponseDTO: Decodable {
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

    func toDomain() -> RegisteredPlayer {
        RegisteredPlayer(
            playerId: player.id,
            displayName: player.display_name,
            zooId: zoo.id,
            createdAt: player.created_at
        )
    }
}
