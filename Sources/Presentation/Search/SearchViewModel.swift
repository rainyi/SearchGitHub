import Foundation

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Dependencies

    private let searchUseCase: SearchRepositoriesUseCase
    private let recentSearchUseCase: RecentSearchUseCase
    private let router: AppRouter

    // MARK: - State

    @Published var searchQuery: String = ""
    @Published var recentSearches: [RecentSearchItem] = []

    // 검색 결과 상태
    @Published var repositories: [GitHubRepository] = []
    @Published var totalCount: Int = 0
    @Published var isSearching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasSearched: Bool = false
    @Published var error: AppError?
    @Published var hasNextPage: Bool = false

    private var currentPage: Int = 1

    // MARK: - Computed Properties

    var isSearchButtonEnabled: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSearching
    }

    var shouldShowError: Bool {
        error != nil && repositories.isEmpty
    }

    var shouldShowEmptyState: Bool {
        hasSearched && repositories.isEmpty && error == nil
    }

    var shouldShowResults: Bool {
        hasSearched
    }

    // MARK: - Initialization

    init(
        searchUseCase: SearchRepositoriesUseCase,
        recentSearchUseCase: RecentSearchUseCase,
        router: AppRouter
    ) {
        self.searchUseCase = searchUseCase
        self.recentSearchUseCase = recentSearchUseCase
        self.router = router
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadRecentSearches()
    }

    // MARK: - Actions

    func search() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        isSearching = true
        error = nil
        hasSearched = true
        currentPage = 1

        do {
            try await recentSearchUseCase.addSearch(query: trimmedQuery)
            let result = try await searchUseCase.execute(keyword: trimmedQuery, page: 1)
            repositories = result.repositories
            totalCount = result.totalCount
            hasNextPage = result.hasNextPage
            await loadRecentSearches()
        } catch let error as AppError {
            self.error = error
            repositories = []
        } catch {
            self.error = .unknown(error)
            repositories = []
        }

        isSearching = false
    }

    func loadNextPage() async {
        guard !isLoadingMore && hasNextPage else { return }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let result = try await searchUseCase.execute(keyword: trimmedQuery, page: currentPage)
            repositories.append(contentsOf: result.repositories)
            hasNextPage = result.hasNextPage
        } catch {
            currentPage -= 1
        }

        isLoadingMore = false
    }

    func refresh() async {
        await search()
    }

    func selectRecentSearch(_ item: RecentSearchItem) {
        searchQuery = item.query
        Task {
            await search()
        }
    }

    func deleteRecentSearch(id: UUID) async {
        do {
            try await recentSearchUseCase.deleteSearch(id: id)
            await loadRecentSearches()
        } catch {
            // Silently handle deletion error
        }
    }

    func clearAllRecentSearches() async {
        do {
            try await recentSearchUseCase.clearAll()
            await loadRecentSearches()
        } catch {
            // Silently handle clear error
        }
    }

    func selectRepository(_ repository: GitHubRepository) {
        router.showDetail(url: repository.htmlUrl)
    }

    func clearSearch() {
        searchQuery = ""
        repositories = []
        hasSearched = false
        error = nil
        totalCount = 0
    }

    // MARK: - Private Methods

    private func loadRecentSearches() async {
        do {
            recentSearches = try await recentSearchUseCase.getRecentSearches()
        } catch {
            recentSearches = []
        }
    }
}
