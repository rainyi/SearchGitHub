import XCTest
@testable import GitHubSearch

// MARK: - Mock

actor MockGitHubAPIClient: GitHubAPIClient {
    nonisolated(unsafe) var mockResult: (repositories: [GitHubRepository], totalCount: Int)?
    nonisolated(unsafe) var mockError: Error?
    nonisolated(unsafe) var capturedQuery: String?
    nonisolated(unsafe) var capturedPage: Int?

    func searchRepositories(query: String, page: Int) async throws -> (repositories: [GitHubRepository], totalCount: Int) {
        capturedQuery = query
        capturedPage = page

        if let error = mockError {
            throw error
        }

        return mockResult ?? ([], 0)
    }
}

// MARK: - Tests

@MainActor
final class GitHubRepositoryRepositoryImplTests: XCTestCase {

    private var apiClient: MockGitHubAPIClient!
    private var sut: GitHubRepositoryRepositoryImpl!

    override func setUp() async throws {
        apiClient = MockGitHubAPIClient()
        sut = GitHubRepositoryRepositoryImpl(apiClient: apiClient)
    }

    // MARK: - Success Cases

    func testSearch_WhenFirstPage_ThenReturnsCorrectResult() async throws {
        // Given
        let repositories = [
            GitHubRepository.sample,
            GitHubRepository(
                id: 2,
                name: "another",
                fullName: "user2/another",
                owner: RepositoryOwner(login: "user2", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                htmlUrl: URL(string: "https://github.com/user2/another")!,
                description: nil,
                stargazersCount: 50,
                language: nil,
                updatedAt: nil
            )
        ]
        apiClient.mockResult = (repositories: repositories, totalCount: 100)

        // When
        let result = try await sut.search(keyword: "swift", page: 1)

        // Then
        XCTAssertEqual(result.repositories.count, 2)
        XCTAssertEqual(result.totalCount, 100)
        XCTAssertTrue(result.hasNextPage)
        XCTAssertEqual(apiClient.capturedQuery, "swift")
        XCTAssertEqual(apiClient.capturedPage, 1)
    }

    func testSearch_WhenLastPage_ThenHasNextPageIsFalse() async throws {
        // Given: 30개씩, 65개 전체
        let repositories = (0..<30).map { i in
            GitHubRepository(
                id: i,
                name: "repo\(i)",
                fullName: "user/repo\(i)",
                owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                htmlUrl: URL(string: "https://github.com/user/repo\(i)")!,
                description: nil,
                stargazersCount: 0,
                language: nil,
                updatedAt: nil
            )
        }
        apiClient.mockResult = (repositories: repositories, totalCount: 65)

        // When: 2페이지 (60 < 65)
        let result = try await sut.search(keyword: "test", page: 2)

        // Then
        XCTAssertTrue(result.hasNextPage)

        // When: 3페이지 (90 > 65)
        let lastResult = try await sut.search(keyword: "test", page: 3)

        // Then
        XCTAssertFalse(lastResult.hasNextPage)
    }

    func testSearch_WhenExactPageBoundary_ThenHasNextPageIsFalse() async throws {
        // Given: 30개씩, 60개 전체
        let repositories = (0..<30).map { i in
            GitHubRepository(
                id: i,
                name: "repo\(i)",
                fullName: "user/repo\(i)",
                owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                htmlUrl: URL(string: "https://github.com/user/repo\(i)")!,
                description: nil,
                stargazersCount: 0,
                language: nil,
                updatedAt: nil
            )
        }
        apiClient.mockResult = (repositories: repositories, totalCount: 60)

        // When: 2페이지 (정확히 마지막)
        let result = try await sut.search(keyword: "test", page: 2)

        // Then: 60 < 60이므로 hasNextPage는 false
        XCTAssertFalse(result.hasNextPage)
    }

    // MARK: - Error Cases

    func testSearch_WhenAPIThrowsError_ThenPropagatesError() async {
        // Given
        apiClient.mockError = AppError.network(NSError(domain: "test", code: -1))

        // When/Then
        do {
            _ = try await sut.search(keyword: "swift", page: 1)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    func testSearch_WhenRateLimitError_ThenPropagatesRateLimitError() async {
        // Given
        let resetDate = Date().addingTimeInterval(60)
        apiClient.mockError = AppError.rateLimit(resetAt: resetDate)

        // When/Then
        do {
            _ = try await sut.search(keyword: "swift", page: 1)
            XCTFail("Expected error to be thrown")
        } catch {
            if case AppError.rateLimit = error {
                // Success
            } else {
                XCTFail("Expected rateLimit error")
            }
        }
    }

    // MARK: - Empty Results

    func testSearch_WhenEmptyResults_ThenReturnsEmptyWithNoNextPage() async throws {
        // Given
        apiClient.mockResult = (repositories: [], totalCount: 0)

        // When
        let result = try await sut.search(keyword: "nonexistent", page: 1)

        // Then
        XCTAssertTrue(result.repositories.isEmpty)
        XCTAssertEqual(result.totalCount, 0)
        XCTAssertFalse(result.hasNextPage)
    }
}
