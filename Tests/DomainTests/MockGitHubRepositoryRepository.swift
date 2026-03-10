import Foundation
@testable import GitHubSearchApp

/// 테스트용 Mock GitHubRepositoryRepository
@MainActor
final class MockGitHubRepositoryRepository: GitHubRepositoryRepository {
    var stubResult: SearchResult?
    var stubError: Error?
    var capturedKeyword: String?
    var capturedPage: Int?
    private var callCount: Int = 0

    func search(keyword: String, page: Int) async throws -> SearchResult {
        capturedKeyword = keyword
        capturedPage = page
        callCount += 1

        if let error = stubError {
            throw error
        }

        return stubResult ?? SearchResult(
            repositories: [],
            totalCount: 0,
            hasNextPage: false
        )
    }

    func getCallCount() -> Int {
        return callCount
    }
}
