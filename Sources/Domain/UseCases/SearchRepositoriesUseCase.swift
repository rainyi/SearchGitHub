import Foundation

/// 저장소 검색 UseCase 프로토콜
@MainActor
protocol SearchRepositoriesUseCase {
    /// 저장소 검색 실행
    /// - Parameters:
    ///   - keyword: 검색어
    ///   - page: 페이지 번호 (1부터 시작)
    /// - Returns: 검색 결과
    func execute(keyword: String, page: Int) async throws -> SearchResult

    /// 특정 키워드의 캐시 무효화
    /// - Parameter keyword: 무효화할 검색어
    func invalidateCache(for keyword: String)
}

// MARK: - Default Implementation

@MainActor
final class DefaultSearchRepositoriesUseCase: SearchRepositoriesUseCase {
    private let repository: GitHubRepositoryRepository
    private let cache: SearchResultCache

    init(
        repository: GitHubRepositoryRepository,
        cache: SearchResultCache = .shared
    ) {
        self.repository = repository
        self.cache = cache
    }

    func execute(keyword: String, page: Int) async throws -> SearchResult {
        // 입력 검증
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            throw AppError.emptyQuery
        }

        guard page > 0 else {
            throw AppError.invalidParameter("page must be greater than 0")
        }

        // 캐시 확인 (첫 페이지만 캐싱)
        if page == 1, let cachedResult = cache.get(keyword: trimmedKeyword, page: page) {
            return cachedResult
        }

        // API 호출
        let result = try await repository.search(keyword: trimmedKeyword, page: page)

        // 결과 캐싱 (첫 페이지만)
        if page == 1 {
            cache.set(keyword: trimmedKeyword, page: page, result: result)
        }

        return result
    }

    /// 특정 키워드의 캐시 무효화
    func invalidateCache(for keyword: String) {
        cache.invalidate(keyword: keyword.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
