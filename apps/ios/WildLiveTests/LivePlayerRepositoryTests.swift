// WildLive — Data-layer unit tests for LivePlayerRepository.
//
// Uses URLProtocol stubbing so no real network / Laravel is required.
// Verifies request shape (method, URL, JSON body, headers) and response
// decoding (2xx → RegisteredPlayer, non-2xx → APIError.badStatus,
// malformed JSON → APIError.decoding, transport error → APIError.transport).

import XCTest
@testable import WildLive

final class LivePlayerRepositoryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    private func makeRepo() -> LivePlayerRepository {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = APIClient(session: session)
        return LivePlayerRepository(api: client)
    }

    // MARK: request shape

    func test_posts_json_to_players_endpoint_with_display_name() async throws {
        StubURLProtocol.stub = { request in
            let body = """
            {
              "player": {"id": "P-1", "display_name": "Kai", "created_at": "2026-08-15T12:34:56.000000Z"},
              "zoo":    {"id": "Z-1", "created_at": "2026-08-15T12:34:56.000000Z"}
            }
            """.data(using: .utf8)!
            return .success(status: 201, body: body)
        }

        let repo = makeRepo()
        _ = try await repo.register(displayName: "Kai")

        let recorded = StubURLProtocol.recordedRequests.first
        XCTAssertEqual(recorded?.httpMethod, "POST")
        XCTAssertEqual(recorded?.url?.absoluteString, "http://localhost:8000/api/players")
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(recorded?.value(forHTTPHeaderField: "Accept"), "application/json")
        if let body = StubURLProtocol.recordedBodies.first {
            let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(decoded?["display_name"] as? String, "Kai")
        } else {
            XCTFail("no request body recorded")
        }
    }

    // MARK: response decoding — happy path

    func test_decodes_201_response_into_registered_player() async throws {
        StubURLProtocol.stub = { _ in
            let body = """
            {
              "player": {"id": "P-abc", "display_name": "Rin", "created_at": "2026-08-15T12:00:00.000000Z"},
              "zoo":    {"id": "Z-xyz", "created_at": "2026-08-15T12:00:00.000000Z"}
            }
            """.data(using: .utf8)!
            return .success(status: 201, body: body)
        }
        let repo = makeRepo()
        let result = try await repo.register(displayName: "Rin")
        XCTAssertEqual(result.playerId, "P-abc")
        XCTAssertEqual(result.zooId, "Z-xyz")
        XCTAssertEqual(result.displayName, "Rin")
    }

    // MARK: response decoding — validation error 422

    func test_throws_on_non_2xx_status() async {
        StubURLProtocol.stub = { _ in
            let body = #"{"message":"The display name field is required.","errors":{"display_name":["required"]}}"#
                .data(using: .utf8)!
            return .success(status: 422, body: body)
        }
        let repo = makeRepo()

        do {
            _ = try await repo.register(displayName: "")
            XCTFail("expected error")
        } catch let APIError.badStatus(status, body) {
            XCTAssertEqual(status, 422)
            XCTAssertTrue(body.contains("display_name"))
        } catch {
            XCTFail("expected APIError.badStatus, got \(error)")
        }
    }

    // MARK: response decoding — malformed body

    func test_throws_decoding_error_on_malformed_body() async {
        StubURLProtocol.stub = { _ in
            .success(status: 201, body: "not json".data(using: .utf8)!)
        }
        let repo = makeRepo()

        do {
            _ = try await repo.register(displayName: "Kai")
            XCTFail("expected error")
        } catch APIError.decoding {
            // Expected.
        } catch {
            XCTFail("expected APIError.decoding, got \(error)")
        }
    }

    // MARK: transport error

    func test_throws_transport_error_when_url_loader_fails() async {
        StubURLProtocol.stub = { _ in .failure(URLError(.cannotConnectToHost)) }
        let repo = makeRepo()

        do {
            _ = try await repo.register(displayName: "Kai")
            XCTFail("expected error")
        } catch APIError.transport {
            // Expected.
        } catch {
            XCTFail("expected APIError.transport, got \(error)")
        }
    }
}

// -- URLProtocol stub ---------------------------------------------------------

final class StubURLProtocol: URLProtocol {

    enum Outcome {
        case success(status: Int, body: Data)
        case failure(URLError)
    }

    /// Called for every intercepted request.
    static var stub: ((URLRequest) -> Outcome)?

    static private(set) var recordedRequests: [URLRequest] = []
    static private(set) var recordedBodies: [Data] = []

    static func reset() {
        stub = nil
        recordedRequests = []
        recordedBodies = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.recordedRequests.append(request)
        if let body = request.httpBody {
            Self.recordedBodies.append(body)
        } else if let stream = request.httpBodyStream {
            // URLSession serializes JSON bodies via httpBodyStream in
            // ephemeral configurations. Drain into recordedBodies.
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            Self.recordedBodies.append(data)
        }

        guard let stub = Self.stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        switch stub(request) {
        case .success(let status, let body):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
