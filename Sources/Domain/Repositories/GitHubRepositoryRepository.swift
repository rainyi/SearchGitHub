import Foundation

/// GitHub 저장소 검색 결과
struct SearchResult {
    let repositories: [GitHubRepository]
    let totalCount: Int
    let hasNextPage: Bool
}

/// GitHub 저장소 검색 Repository 인터페이스
protocol GitHubRepositoryRepository {
    /// 저장소 검색
    /// - Parameters:
    ///   - keyword: 검색어
    ///   - page: 페이지 번호 (1부터 시작)
    /// - Returns: 검색 결과 (저장소 목록, 총 개수, 다음 페이지 여부)
    func search(keyword: String, page: Int) async throws -> SearchResult
}
