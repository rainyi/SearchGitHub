import Foundation

/// 저장소 검색 UseCase 프로토콜
protocol SearchRepositoriesUseCase {
    /// 저장소 검색 실행
    /// - Parameters:
    ///   - keyword: 검색어
    ///   - page: 페이지 번호 (1부터 시작)
    /// - Returns: 검색 결과
    func execute(keyword: String, page: Int) async throws -> SearchResult
}

// MARK: - Default Implementation

final class DefaultSearchRepositoriesUseCase: SearchRepositoriesUseCase {
    private let repository: GitHubRepositoryRepository

    init(repository: GitHubRepositoryRepository) {
        self.repository = repository
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

        return try await repository.search(keyword: trimmedKeyword, page: page)
    }
}
