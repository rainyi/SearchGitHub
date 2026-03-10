import Foundation

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Dependencies

    private let searchUseCase: SearchRepositoriesUseCase
    private let recentSearchUseCase: RecentSearchUseCase
    private let router: AppRouter

    // MARK: - State

    @Published var searchQuery: String = "" {
        didSet {
            updateAutocompleteSuggestions()
        }
    }
    @Published var recentSearches: [RecentSearchItem] = []
    @Published var autocompleteSuggestions: [RecentSearchItem] = []

    // 검색 결과 상태
    @Published var repositories: [GitHubRepository] = []
    @Published var totalCount: Int = 0
    @Published var isSearching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasSearched: Bool = false
    @Published var error: AppError?
    @Published var hasNextPage: Bool = false

    private var currentPage: Int = 1
    private var autocompleteTask: Task<Void, Never>?

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
        } catch _ as AppError {
            currentPage -= 1
            // 페이지네이션 에러는 사용자에게 표시하지 않고 조용히 처리
            // (이미 일부 결과가 표시 중이므로 중단하지 않음)
        } catch {
            currentPage -= 1
            // 예상치 못한 에러 타입
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

    private func updateAutocompleteSuggestions() {
        // 이전 태스크 취소
        autocompleteTask?.cancel()

        autocompleteTask = Task { @MainActor in
            // 300ms 디바운스
            try? await Task.sleep(nanoseconds: 300_000_000)

            // 태스크가 취소되었는지 확인
            guard !Task.isCancelled else { return }

            let trimmedQuery = self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

            // 1글자 이상일 때만 자동완성 표시
            guard trimmedQuery.count >= 1 else {
                self.autocompleteSuggestions = []
                return
            }

            // 이미 검색 중이거나 결과가 표시 중이면 자동완성 숨김
            guard !self.hasSearched else {
                self.autocompleteSuggestions = []
                return
            }

            // 최근 검색어에서 필터링 (대소문자 무시, 검색어 포함)
            let queryLower = trimmedQuery.lowercased()
            let filtered = self.recentSearches.filter { item in
                item.query.lowercased().contains(queryLower)
            }

            // 최신순으로 정렬하고 최대 5개만 표시
            self.autocompleteSuggestions = Array(filtered.prefix(5))
        }
    }
}
