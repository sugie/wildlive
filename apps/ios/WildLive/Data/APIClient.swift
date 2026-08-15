// WildLive — Thin URLSession wrapper.
//
// Deliberately small: one `send` method with async/await + Codable.
// The base URL is read from Info.plist key `WildLiveAPIBaseURL`
// (default `http://localhost:8000/api`) so a tester on the Simulator
// can point at a different host without a rebuild.

import Foundation

enum APIError: Error, LocalizedError {
    case transport(URLError)
    case badStatus(Int, body: String)
    case decoding(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .transport(let e):
            return "Network error: \(e.localizedDescription)"
        case .badStatus(let code, let body):
            let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = trimmed.isEmpty ? "(no body)" : String(trimmed.prefix(200))
            return "Server returned \(code). \(snippet)"
        case .decoding(let e):
            return "Could not read the server's response: \(e.localizedDescription)"
        case .invalidURL:
            return "Invalid API URL."
        }
    }
}

struct APIClient {
    let baseURL: URL
    let session: URLSession

    init(session: URLSession = .shared) {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "WildLiveAPIBaseURL") as? String)?
            .trimmingCharacters(in: .whitespaces)
        let raw = (configured?.isEmpty == false) ? configured! : "http://localhost:8000/api"
        self.baseURL = URL(string: raw) ?? URL(string: "http://localhost:8000/api")!
        self.session = session
    }

    func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as _: Response.Type,
        acceptedStatuses: Set<Int> = [200, 201]
    ) async -> Result<Response, APIError> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let encoded: Data
        do {
            encoded = try encoder.encode(body)
        } catch {
            return .failure(.decoding(error))
        }

        return await send(
            method: "POST",
            path: path,
            body: encoded,
            as: Response.self,
            acceptedStatuses: acceptedStatuses
        )
    }

    /// GET, for the read-only endpoints (catalogue, zoo, expedition list).
    func get<Response: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        as _: Response.Type,
        acceptedStatuses: Set<Int> = [200]
    ) async -> Result<Response, APIError> {
        await send(
            method: "GET",
            path: path,
            query: query,
            body: nil,
            as: Response.self,
            acceptedStatuses: acceptedStatuses
        )
    }

    /// POST with no request body, for the command endpoints
    /// (resolve / release) that need only the URL.
    func command<Response: Decodable>(
        path: String,
        as _: Response.Type,
        acceptedStatuses: Set<Int> = [200, 201]
    ) async -> Result<Response, APIError> {
        await send(
            method: "POST",
            path: path,
            body: nil,
            as: Response.self,
            acceptedStatuses: acceptedStatuses
        )
    }

    /// Date decoding that accepts both shapes the API produces.
    ///
    /// Laravel's `toISOString()` emits microseconds
    /// (`2026-08-15T12:57:27.000000Z`), which `JSONDecoder.iso8601`
    /// rejects outright — it only understands whole seconds. Accepting
    /// both spellings here is the difference between the client parsing
    /// the server's responses and failing on every timestamp.
    static let lenientISO8601: JSONDecoder.DateDecodingStrategy = {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let whole = ISO8601DateFormatter()
        whole.formatOptions = [.withInternetDateTime]

        return .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = withFraction.date(from: raw) ?? whole.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Not an ISO-8601 date: \(raw)"
                )
            )
        }
    }()

    private func send<Response: Decodable>(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        body: Data?,
        as _: Response.Type,
        acceptedStatuses: Set<Int>
    ) async -> Result<Response, APIError> {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = baseURL
        // appendingPathComponent(_:) percent-encodes the whole string, so a
        // multi-segment path has to be appended one segment at a time or the
        // slashes end up as %2F.
        for segment in trimmed.split(separator: "/") {
            url.appendPathComponent(String(segment))
        }

        if !query.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return .failure(.invalidURL)
            }
            components.queryItems = query
            guard let withQuery = components.url else { return .failure(.invalidURL) }
            url = withQuery
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = body

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard acceptedStatuses.contains(status) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return .failure(.badStatus(status, body: body))
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = Self.lenientISO8601
            do {
                let decoded = try decoder.decode(Response.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(.decoding(error))
            }
        } catch let urlError as URLError {
            return .failure(.transport(urlError))
        } catch {
            return .failure(.decoding(error))
        }
    }
}
