import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Dependencies

    private let searchUseCase: SearchRepositoriesUseCase
    private let recentSearchUseCase: RecentSearchUseCase
    private let router: AppRouter
    private let autocompleteManager: AutocompleteManager

    // MARK: - State

    @Published var searchQuery: String = ""
    @Published private(set) var searchState: SearchState
    @Published private(set) var uiState: SearchUIState
    @Published var recentSearches: [RecentSearchItem] = []
    @Published var autocompleteSuggestions: [RecentSearchItem] = []

    // MARK: - Computed Properties

    var repositories: [GitHubRepository] { searchState.repositories }
    var totalCount: Int { searchState.totalCount }
    var isSearching: Bool { uiState.isSearching }
    var isLoadingMore: Bool { uiState.isLoadingMore }
    var hasSearched: Bool { searchState.hasSearched }
    var error: AppError? { uiState.error }
    var hasNextPage: Bool { searchState.hasNextPage }

    var isSearchButtonEnabled: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSearching
    }

    var shouldShowError: Bool {
        uiState.shouldShowError && searchState.isEmpty
    }

    var shouldShowEmptyState: Bool {
        hasSearched && searchState.isEmpty && uiState.error == nil
    }

    var shouldShowResults: Bool {
        hasSearched
    }

    // MARK: - Initialization

    init(
        searchUseCase: SearchRepositoriesUseCase,
        recentSearchUseCase: RecentSearchUseCase,
        router: AppRouter,
        autocompleteManager: AutocompleteManager = AutocompleteManager()
    ) {
        self.searchUseCase = searchUseCase
        self.recentSearchUseCase = recentSearchUseCase
        self.router = router
        self.autocompleteManager = autocompleteManager
        self.searchState = SearchState()
        self.uiState = SearchUIState()

        setupBindings()
    }

    /// Preview용 초기화 - 지정된 상태로 ViewModel 생성
    init(
        searchUseCase: SearchRepositoriesUseCase,
        recentSearchUseCase: RecentSearchUseCase,
        router: AppRouter,
        initialQuery: String = "",
        initialState: SearchState = SearchState(),
        autocompleteManager: AutocompleteManager = AutocompleteManager()
    ) {
        self.searchUseCase = searchUseCase
        self.recentSearchUseCase = recentSearchUseCase
        self.router = router
        self.autocompleteManager = autocompleteManager
        self.searchState = initialState
        self.uiState = SearchUIState()
        self.searchQuery = initialQuery

        setupBindings()
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadRecentSearches()
    }

    // MARK: - Actions

    func search() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        uiState.startSearch()
        searchState.startNewSearch()

        do {
            try await recentSearchUseCase.addSearch(query: trimmedQuery)
            let result = try await searchUseCase.execute(keyword: trimmedQuery, page: 1)
            searchState.setResults(result)
            await loadRecentSearches()
        } catch {
            handleSearchError(error)
        }

        uiState.finishSearch()
    }

    func loadNextPage() async {
        guard !isLoadingMore && hasNextPage else { return }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        uiState.startLoadingMore()

        do {
            let result = try await searchUseCase.execute(keyword: trimmedQuery, page: searchState.currentPage + 1)
            searchState.appendResults(result)
        } catch {
            searchState.revertPageIncrement()
        }

        uiState.finishLoadingMore()
    }

    func refresh() async {
        // Pull to Refresh 시 캐시 무효화 후 재검색
        invalidateCacheForCurrentQuery()
        await search()
    }

    private func invalidateCacheForCurrentQuery() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        searchUseCase.invalidateCache(for: trimmedQuery)
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
            // Deletion error is non-critical; log for debugging
            print("[SearchViewModel] Failed to delete recent search: \(error)")
        }
    }

    func clearAllRecentSearches() async {
        do {
            try await recentSearchUseCase.clearAll()
            await loadRecentSearches()
        } catch {
            // Clear error is non-critical; log for debugging
            print("[SearchViewModel] Failed to clear recent searches: \(error)")
        }
    }

    func selectRepository(_ repository: GitHubRepository) {
        router.showDetail(url: repository.htmlUrl)
    }

    func clearSearch() {
        searchQuery = ""
        searchState.reset()
        uiState.clearError()
        autocompleteSuggestions = []
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // searchQuery 변경 시 자동완성 업데이트
        $searchQuery
            .sink { [weak self] query in
                self?.updateAutocompleteSuggestions(query: query)
            }
            .store(in: &cancellables)
    }

    private func updateAutocompleteSuggestions(query: String) {
        autocompleteManager.updateSuggestions(
            query: query,
            recentSearches: recentSearches,
            hasSearched: searchState.hasSearched
        ) { [weak self] suggestions in
            self?.autocompleteSuggestions = suggestions
        }
    }

    private func loadRecentSearches() async {
        do {
            recentSearches = try await recentSearchUseCase.getRecentSearches()
        } catch {
            recentSearches = []
        }
    }

    private func handleSearchError(_ error: Error) {
        if let appError = error as? AppError {
            uiState.setError(appError)
        } else {
            uiState.setError(.unknown(error))
        }
        searchState.repositories = []
    }

    // MARK: - Cancellables

    private var cancellables: Set<AnyCancellable> = []
}
