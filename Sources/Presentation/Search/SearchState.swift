import Foundation

// MARK: - Search State

/// 검색 결과 및 페이지네이션 상태
struct SearchState {
    var repositories: [GitHubRepository] = []
    var totalCount: Int = 0
    var hasNextPage: Bool = false
    var currentPage: Int = 1
    var hasSearched: Bool = false

    var isEmpty: Bool { repositories.isEmpty }

    mutating func reset() {
        repositories = []
        totalCount = 0
        hasNextPage = false
        currentPage = 1
        hasSearched = false
    }

    mutating func startNewSearch() {
        reset()
        hasSearched = true
    }

    mutating func setResults(_ result: SearchResult) {
        repositories = result.repositories
        totalCount = result.totalCount
        hasNextPage = result.hasNextPage
        currentPage = 1
    }

    mutating func appendResults(_ result: SearchResult) {
        repositories.append(contentsOf: result.repositories)
        hasNextPage = result.hasNextPage
        currentPage += 1
    }

    mutating func revertPageIncrement() {
        currentPage = max(1, currentPage - 1)
    }
}

// MARK: - Search UI State

/// 검색 UI 상태 (로딩, 에러 등)
struct SearchUIState {
    var isSearching: Bool = false
    var isLoadingMore: Bool = false
    var error: AppError?

    var shouldShowError: Bool { error != nil }

    mutating func startSearch() {
        isSearching = true
        error = nil
    }

    mutating func finishSearch() {
        isSearching = false
    }

    mutating func startLoadingMore() {
        isLoadingMore = true
    }

    mutating func finishLoadingMore() {
        isLoadingMore = false
    }

    mutating func setError(_ error: AppError) {
        self.error = error
    }

    mutating func clearError() {
        error = nil
    }
}
