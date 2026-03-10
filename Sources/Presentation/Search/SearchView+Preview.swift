import SwiftUI

// MARK: - Preview

#Preview("검색 전") {
    NavigationStack {
        SearchView(
            viewModel: SearchViewModel(
                searchUseCase: MockSearchRepositoriesUseCase(),
                recentSearchUseCase: MockRecentSearchUseCasePreview(),
                router: AppRouter()
            )
        )
    }
}

#Preview("검색 중 - 텍스트 입력") {
    NavigationStack {
        SearchView(
            viewModel: createSearchViewModelWithText()
        )
    }
}

#Preview("검색 결과") {
    NavigationStack {
        SearchView(
            viewModel: createSearchViewModelWithResults()
        )
    }
}

// MARK: - Preview Helpers

@MainActor
private func createSearchViewModelWithText() -> SearchViewModel {
    let viewModel = SearchViewModel(
        searchUseCase: MockSearchRepositoriesUseCase(),
        recentSearchUseCase: MockRecentSearchUseCasePreview(),
        router: AppRouter()
    )
    viewModel.searchQuery = "swift"
    return viewModel
}

@MainActor
private func createSearchViewModelWithResults() -> SearchViewModel {
    let repositories = (1...10).map { index in
        GitHubRepository(
            id: index,
            name: "repo-\(index)",
            fullName: "user/repo-\(index)",
            owner: RepositoryOwner(
                login: "user",
                avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!
            ),
            htmlUrl: URL(string: "https://github.com/user/repo-\(index)")!,
            description: "Repository \(index)",
            stargazersCount: 100 + index,
            language: "Swift",
            updatedAt: Date()
        )
    }

    let initialState = SearchState(
        repositories: repositories,
        totalCount: 100,
        hasNextPage: true,
        currentPage: 1,
        hasSearched: true
    )

    return SearchViewModel(
        searchUseCase: MockSearchRepositoriesUseCaseWithResults(),
        recentSearchUseCase: MockRecentSearchUseCasePreview(),
        router: AppRouter(),
        initialQuery: "swift",
        initialState: initialState
    )
}

// MARK: - Preview Mocks

private struct MockSearchRepositoriesUseCase: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        SearchResult(repositories: [], totalCount: 0, hasNextPage: false)
    }

    func invalidateCache(for keyword: String) {}
}

private struct MockSearchRepositoriesUseCaseWithResults: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        // 페이지별로 다른 결과 반환하여 페이지네이션 테스트 가능
        let baseId = (page - 1) * 10
        let repositories = (1...10).map { index in
            GitHubRepository(
                id: baseId + index,
                name: "repo-\(baseId + index)",
                fullName: "user/repo-\(baseId + index)",
                owner: RepositoryOwner(
                    login: "user",
                    avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!
                ),
                htmlUrl: URL(string: "https://github.com/user/repo-\(baseId + index)")!,
                description: "Repository \(baseId + index)",
                stargazersCount: 100 + baseId + index,
                language: "Swift",
                updatedAt: Date()
            )
        }
        return SearchResult(
            repositories: repositories,
            totalCount: 100,
            hasNextPage: page < 10
        )
    }

    func invalidateCache(for keyword: String) {}
}

@MainActor
private final class MockRecentSearchUseCasePreview: RecentSearchUseCase {
    func getRecentSearches() async throws -> [RecentSearchItem] {
        return [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date().addingTimeInterval(-3600)),
            RecentSearchItem(query: "combine", searchedAt: Date().addingTimeInterval(-7200))
        ]
    }

    func addSearch(query: String) async throws {}
    func deleteSearch(id: UUID) async throws {}
    func clearAll() async throws {}
}
