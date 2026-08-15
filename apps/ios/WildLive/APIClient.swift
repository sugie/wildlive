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
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.decoding(error))
        }

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard acceptedStatuses.contains(status) else {
                let body = String(data: data, encoding: .utf8) ?? ""
                return .failure(.badStatus(status, body: body))
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
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
