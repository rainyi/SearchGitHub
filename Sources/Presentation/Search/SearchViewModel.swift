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
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    // MARK: - Computed Properties

    var isSearchButtonEnabled: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
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

        isLoading = true
        error = nil

        do {
            try await recentSearchUseCase.addSearch(query: trimmedQuery)
            router.showResults(for: trimmedQuery)
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = .unknown(error)
        }

        isLoading = false
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

    // MARK: - Private Methods

    private func loadRecentSearches() async {
        do {
            recentSearches = try await recentSearchUseCase.getRecentSearches()
        } catch {
            recentSearches = []
        }
    }
}
