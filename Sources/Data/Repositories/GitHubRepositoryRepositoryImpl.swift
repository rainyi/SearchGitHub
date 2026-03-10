import Foundation

/// GitHub 저장소 검색 Repository 구현체
@MainActor
final class GitHubRepositoryRepositoryImpl: GitHubRepositoryRepository {

    // MARK: - Properties

    private let apiClient: GitHubAPIClient
    private let perPage: Int

    // MARK: - Initialization

    init(apiClient: GitHubAPIClient, perPage: Int = 30) {
        self.apiClient = apiClient
        self.perPage = perPage
    }

    // MARK: - GitHubRepositoryRepository

    func search(keyword: String, page: Int) async throws -> SearchResult {
        let (repositories, totalCount) = try await apiClient.searchRepositories(
            query: keyword,
            page: page
        )

        let hasNextPage = calculateHasNextPage(
            currentPage: page,
            totalCount: totalCount
        )

        return SearchResult(
            repositories: repositories,
            totalCount: totalCount,
            hasNextPage: hasNextPage
        )
    }

    // MARK: - Private Helpers

    /// 다음 페이지 존재 여부 계산
    private func calculateHasNextPage(currentPage: Int, totalCount: Int) -> Bool {
        let loadedCount = currentPage * perPage
        return loadedCount < totalCount
    }
}
