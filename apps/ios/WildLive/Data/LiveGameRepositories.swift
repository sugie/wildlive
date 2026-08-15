// WildLive — HTTP-backed implementations of the game Domain contracts.
//
// These are the only files allowed to touch APIClient for gameplay. The
// Application and Presentation layers see the protocols in
// Domain/GameRepositories.swift and never learn that HTTP exists.
//
// Every method follows the same three steps: build the path, ask
// APIClient, map the DTO to the Domain type. Anything else — retries,
// caching, optimistic updates — is deliberately absent: the server is
// authoritative and the screens are thin.

import Foundation

/// Turns an APIError into the server's own explanation when it sent one.
///
/// The API answers a refused action with `{"error":{"code","message"}}`,
/// and that message is written for a player ("This expedition costs 4550 G.
/// You have 1000 G."). Showing it beats "Server returned 422".
struct GameAPIError: Error, LocalizedError {
    let code: String
    let message: String
    let underlying: APIError

    var errorDescription: String? { message }

    /// Refusals the UI wants to recognise rather than merely display.
    var isAlreadyDecided: Bool { code == "already_decided" }
    var isNotDue: Bool { code == "expedition_not_due" }

    static func from(_ error: APIError) -> Error {
        guard case .badStatus(_, let body) = error,
              let data = body.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(APIErrorBodyDTO.self, from: data)
        else {
            return error
        }
        return GameAPIError(code: decoded.error.code, message: decoded.error.message, underlying: error)
    }
}

private func unwrap<T>(_ result: Result<T, APIError>) throws -> T {
    switch result {
    case .success(let value): return value
    case .failure(let error): throw GameAPIError.from(error)
    }
}

// MARK: - Catalogue

final class LiveGameCatalogRepository: GameCatalogRepository, @unchecked Sendable {
    private let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
    }

    func maps(playerID: String) async throws -> [GameMap] {
        let dto = try unwrap(await api.get(
            path: "players/\(playerID)/maps",
            as: MapListResponseDTO.self
        ))
        return dto.maps.map { $0.toDomain() }
    }

    func mapDetail(playerID: String, mapID: String) async throws -> GameMap {
        let dto = try unwrap(await api.get(
            path: "players/\(playerID)/maps/\(mapID)",
            as: MapDetailResponseDTO.self
        ))
        return dto.map.toDomain()
    }

    func hunters(forMapID mapID: String?) async throws -> [Hunter] {
        let query = mapID.map { [URLQueryItem(name: "map_id", value: $0)] } ?? []
        let dto = try unwrap(await api.get(
            path: "hunters",
            query: query,
            as: HunterListResponseDTO.self
        ))
        return dto.hunters.map { $0.toDomain() }
    }
}

// MARK: - Player profile

final class LivePlayerProfileRepository: PlayerProfileRepository, @unchecked Sendable {
    private let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
    }

    func overview(playerID: String) async throws -> PlayerOverview {
        try unwrap(await api.get(
            path: "players/\(playerID)",
            as: PlayerOverviewResponseDTO.self
        )).toDomain()
    }

    func zoo(playerID: String) async throws -> ZooContents {
        try unwrap(await api.get(
            path: "players/\(playerID)/zoo",
            as: ZooResponseDTO.self
        )).toDomain()
    }
}

// MARK: - Expeditions

final class LiveExpeditionRepository: ExpeditionRepository, @unchecked Sendable {
    private let api: APIClient

    init(api: APIClient = APIClient()) {
        self.api = api
    }

    func start(
        playerID: String,
        mapID: String,
        hunterID: String,
        devInstantResolve: Bool
    ) async throws -> Expedition {
        try unwrap(await api.post(
            path: "players/\(playerID)/expeditions",
            body: StartExpeditionRequestDTO(
                map_id: mapID,
                hunter_id: hunterID,
                dev_instant_resolve: devInstantResolve
            ),
            as: ExpeditionResponseDTO.self
        )).expedition.toDomain()
    }

    func list(playerID: String) async throws -> [Expedition] {
        let dto = try unwrap(await api.get(
            path: "players/\(playerID)/expeditions",
            as: ExpeditionListResponseDTO.self
        ))
        return dto.expeditions.map { $0.toDomain() }
    }

    func get(playerID: String, expeditionID: String) async throws -> Expedition {
        try unwrap(await api.get(
            path: "players/\(playerID)/expeditions/\(expeditionID)",
            as: ExpeditionResponseDTO.self
        )).expedition.toDomain()
    }

    func resolve(playerID: String, expeditionID: String) async throws -> Expedition {
        try unwrap(await api.command(
            path: "players/\(playerID)/expeditions/\(expeditionID)/resolve",
            as: ExpeditionResponseDTO.self
        )).expedition.toDomain()
    }

    func keep(playerID: String, expeditionID: String, name: String) async throws -> Expedition {
        try unwrap(await api.post(
            path: "players/\(playerID)/expeditions/\(expeditionID)/keep",
            body: KeepCapturedAnimalRequestDTO(name: name),
            as: ExpeditionResponseDTO.self
        )).expedition.toDomain()
    }

    func release(playerID: String, expeditionID: String) async throws -> Expedition {
        try unwrap(await api.command(
            path: "players/\(playerID)/expeditions/\(expeditionID)/release",
            as: ExpeditionResponseDTO.self
        )).expedition.toDomain()
    }
}
