// WildLive — Thin URLSession wrapper.
//
// Deliberately small: one `send` method with async/await + Codable.
//
// Base URL resolution:
//   1. Debug builds honour the process environment variable
//      WILDLIVE_API_BASE_URL_OVERRIDE if set (used from the scheme to
//      re-point a running simulator at production or a staging box
//      without editing anything or rebuilding).
//   2. Otherwise, read the Info.plist key WildLiveAPIBaseURL. That value
//      is substituted from the active xcconfig (Config/Debug.xcconfig or
//      Config/Release.xcconfig) at build time, so the same source
//      produces a Debug build pointed at localhost and a Release build
//      pointed at wlapi.misologic.com without any code change.
//   3. In a Release build, if step 2 does not yield an https:// URL,
//      the app aborts on launch. This is deliberate: a Release/TestFlight
//      binary must never silently reach for localhost.

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
        self.baseURL = APIClient.resolveBaseURL()
        self.session = session
    }

    /// Test seam: construct an APIClient against an explicit base URL,
    /// bypassing Info.plist / environment resolution.
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Public so a diagnostics/live-integration test can verify what a
    /// fresh APIClient resolves to under the current build configuration.
    static func resolveBaseURL() -> URL {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["WILDLIVE_API_BASE_URL_OVERRIDE"]?
            .trimmingCharacters(in: .whitespaces),
           override.isEmpty == false,
           let url = URL(string: override) {
            return url
        }
        #endif

        let plistValue = (Bundle.main.object(forInfoDictionaryKey: "WildLiveAPIBaseURL") as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""

        #if DEBUG
        // Debug is permissive: an empty or malformed value falls back to
        // the local docker-compose Laravel so a fresh checkout still
        // boots without any per-machine setup.
        if plistValue.isEmpty {
            return URL(string: "http://localhost:8000/api")!
        }
        return URL(string: plistValue) ?? URL(string: "http://localhost:8000/api")!
        #else
        // Release must resolve to a real https:// URL. If the xcconfig
        // substitution failed or someone shipped a build with the wrong
        // value, refuse to launch instead of quietly hitting the wrong
        // host. Bug reports are cheaper than exfiltrating data to
        // localhost from a customer device.
        guard let url = URL(string: plistValue),
              let scheme = url.scheme?.lowercased(),
              scheme == "https",
              url.host?.isEmpty == false
        else {
            fatalError(
                "WildLiveAPIBaseURL is not a valid https URL in this Release build "
                + "(got \"\(plistValue)\"). Check Config/Release.xcconfig and the "
                + "Info.plist substitution."
            )
        }
        return url
        #endif
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
