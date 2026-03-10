import XCTest
@testable import GitHubSearch

/// GitHubAPIClient 단위 테스트
@MainActor
final class GitHubAPIClientTests: XCTestCase {

    private var sut: DefaultGitHubAPIClient!
    private var mockURLProtocol: MockURLProtocol.Type = MockURLProtocol.self

    override func setUp() {
        super.setUp()

        // URLProtocol mocking 설정
        mockURLProtocol = MockURLProtocol.self
        mockURLProtocol.requestHandler = nil

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [mockURLProtocol.self]
        let session = URLSession(configuration: config)

        sut = DefaultGitHubAPIClient(session: session)
    }

    override func tearDown() {
        sut = nil
        mockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testSearchRepositories_WhenSuccess200_ThenReturnsRepositories() async throws {
        // Given
        let jsonData = """
        {
            "total_count": 1,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "name": "swift",
                    "full_name": "apple/swift",
                    "owner": {
                        "login": "apple",
                        "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
                    },
                    "description": "The Swift Programming Language",
                    "html_url": "https://github.com/apple/swift",
                    "stargazers_count": 65000,
                    "language": "Swift",
                    "forks_count": 10000,
                    "updated_at": "2024-03-10T10:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, jsonData)
        }

        // When
        let result = try await sut.searchRepositories(query: "swift", page: 1)

        // Then
        XCTAssertEqual(result.totalCount, 1)
        XCTAssertEqual(result.repositories.count, 1)
        XCTAssertEqual(result.repositories[0].name, "swift")
        XCTAssertEqual(result.repositories[0].fullName, "apple/swift")
    }

    func testSearchRepositories_WhenMultipleResults_ThenReturnsAllRepositories() async throws {
        // Given
        let jsonData = """
        {
            "total_count": 2,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "name": "swift",
                    "full_name": "apple/swift",
                    "owner": {
                        "login": "apple",
                        "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
                    },
                    "description": "Swift language",
                    "html_url": "https://github.com/apple/swift",
                    "stargazers_count": 100,
                    "language": "Swift",
                    "forks_count": 10,
                    "updated_at": "2024-03-10T10:00:00Z"
                },
                {
                    "id": 2,
                    "name": "kotlin",
                    "full_name": "jetbrains/kotlin",
                    "owner": {
                        "login": "jetbrains",
                        "avatar_url": "https://avatars.githubusercontent.com/u/2?v=4"
                    },
                    "description": "Kotlin language",
                    "html_url": "https://github.com/jetbrains/kotlin",
                    "stargazers_count": 200,
                    "language": "Kotlin",
                    "forks_count": 20,
                    "updated_at": "2024-03-11T11:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, jsonData)
        }

        // When
        let result = try await sut.searchRepositories(query: "language", page: 1)

        // Then
        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(result.repositories.count, 2)
        XCTAssertEqual(result.repositories[0].name, "swift")
        XCTAssertEqual(result.repositories[1].name, "kotlin")
    }

    // MARK: - HTTP Status Code Error Cases

    func testSearchRepositories_When401Unauthorized_ThenThrowsUnauthorizedError() async {
        // Given
        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected unauthorized error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.unauthorized)
        } catch {
            XCTFail("Expected AppError.unauthorized, got \(error)")
        }
    }

    func testSearchRepositories_When403Forbidden_ThenThrowsForbiddenError() async {
        // Given
        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected forbidden error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.forbidden)
        } catch {
            XCTFail("Expected AppError.forbidden, got \(error)")
        }
    }

    func testSearchRepositories_When403WithRateLimitHeader_ThenThrowsRateLimitError() async {
        // Given
        let resetTimestamp = Int(Date().addingTimeInterval(60).timeIntervalSince1970)

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: "HTTP/1.1",
                headerFields: ["X-RateLimit-Reset": String(resetTimestamp)]
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected rateLimit error to be thrown")
        } catch let error as AppError {
            if case .rateLimit = error {
                // Success
            } else {
                XCTFail("Expected AppError.rateLimit, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.rateLimit, got \(error)")
        }
    }

    func testSearchRepositories_When429TooManyRequests_ThenThrowsRateLimitError() async {
        // Given
        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected rateLimit error to be thrown")
        } catch let error as AppError {
            if case .rateLimit = error {
                // Success
            } else {
                XCTFail("Expected AppError.rateLimit, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.rateLimit, got \(error)")
        }
    }

    func testSearchRepositories_When429WithResetHeader_ThenThrowsRateLimitWithCorrectDate() async {
        // Given
        let resetTimestamp = Int(Date().addingTimeInterval(120).timeIntervalSince1970)

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: "HTTP/1.1",
                headerFields: ["X-RateLimit-Reset": String(resetTimestamp)]
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected rateLimit error to be thrown")
        } catch let error as AppError {
            if case .rateLimit(let resetAt) = error {
                let expectedDate = Date(timeIntervalSince1970: TimeInterval(resetTimestamp))
                XCTAssertEqual(resetAt.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 1)
            } else {
                XCTFail("Expected AppError.rateLimit with reset date, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.rateLimit, got \(error)")
        }
    }

    func testSearchRepositories_When500ServerError_ThenThrowsServerError() async {
        // Given
        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected serverError to be thrown")
        } catch let error as AppError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 500)
            } else {
                XCTFail("Expected AppError.serverError, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.serverError, got \(error)")
        }
    }

    func testSearchRepositories_When503ServiceUnavailable_ThenThrowsServerError() async {
        // Given
        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected serverError to be thrown")
        } catch let error as AppError {
            if case .serverError(let code) = error {
                XCTAssertEqual(code, 503)
            } else {
                XCTFail("Expected AppError.serverError, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.serverError, got \(error)")
        }
    }

    // MARK: - Network Error Cases

    func testSearchRepositories_WhenNetworkError_ThenThrowsNetworkError() async {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        mockURLProtocol.requestHandler = { request in
            throw networkError
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected network error to be thrown")
        } catch let error as AppError {
            if case .network = error {
                // Success
            } else {
                XCTFail("Expected AppError.network, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.network, got \(error)")
        }
    }

    func testSearchRepositories_WhenTimeoutError_ThenThrowsNetworkError() async {
        // Given
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        mockURLProtocol.requestHandler = { request in
            throw timeoutError
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected network error to be thrown")
        } catch let error as AppError {
            if case .network = error {
                // Success
            } else {
                XCTFail("Expected AppError.network, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.network, got \(error)")
        }
    }

    // MARK: - Decoding Error Cases

    func testSearchRepositories_WhenInvalidJSON_ThenThrowsDecodingError() async {
        // Given
        let invalidJSON = "not valid json".data(using: .utf8)!

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, invalidJSON)
        }

        // When/Then
        do {
            _ = try await sut.searchRepositories(query: "swift", page: 1)
            XCTFail("Expected decoding error to be thrown")
        } catch let error as AppError {
            if case .decoding = error {
                // Success
            } else {
                XCTFail("Expected AppError.decoding, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.decoding, got \(error)")
        }
    }

    func testSearchRepositories_WhenMalformedRepositoryData_ThenReturnsOnlyValidRepositories() async throws {
        // Given: items 중 일부가 유효하지 않은 URL을 가짐
        let jsonData = """
        {
            "total_count": 2,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "name": "valid",
                    "full_name": "user/valid",
                    "owner": {
                        "login": "user",
                        "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"
                    },
                    "description": "Valid repo",
                    "html_url": "https://github.com/user/valid",
                    "stargazers_count": 100,
                    "language": "Swift",
                    "forks_count": 10,
                    "updated_at": "2024-03-10T10:00:00Z"
                },
                {
                    "id": 2,
                    "name": "invalid",
                    "full_name": "user/invalid",
                    "owner": {
                        "login": "user",
                        "avatar_url": "ht!tp://[invalid"
                    },
                    "description": null,
                    "html_url": "https://github.com/user/invalid",
                    "stargazers_count": 0,
                    "language": null,
                    "forks_count": 0,
                    "updated_at": null
                }
            ]
        }
        """.data(using: .utf8)!

        mockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, jsonData)
        }

        // When
        let result = try await sut.searchRepositories(query: "test", page: 1)

        // Then
        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(result.repositories.count, 1)
        XCTAssertEqual(result.repositories[0].name, "valid")
    }

    // MARK: - Request Building Tests

    func testSearchRepositories_WhenPageSpecified_ThenIncludesPageInRequest() async throws {
        // Given
        let jsonData = """
        {
            "total_count": 0,
            "incomplete_results": false,
            "items": []
        }
        """.data(using: .utf8)!

        var capturedRequest: URLRequest?
        mockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, jsonData)
        }

        // When
        _ = try await sut.searchRepositories(query: "swift", page: 3)

        // Then
        XCTAssertEqual(capturedRequest?.url?.query, "q=swift&page=3&per_page=30")
    }

    func testSearchRepositories_WhenQueryHasSpecialCharacters_ThenProperlyEncoded() async throws {
        // Given
        let jsonData = """
        {
            "total_count": 0,
            "incomplete_results": false,
            "items": []
        }
        """.data(using: .utf8)!

        var capturedRequest: URLRequest?
        mockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, jsonData)
        }

        // When
        _ = try await sut.searchRepositories(query: "swift language", page: 1)

        // Then
        let query = capturedRequest?.url?.query
        XCTAssertTrue(query?.contains("q=swift%20language") ?? false)
    }
}

// MARK: - Mock URLProtocol

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("No request handler set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
