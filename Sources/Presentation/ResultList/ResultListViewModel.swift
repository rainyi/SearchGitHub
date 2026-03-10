import Foundation

@MainActor
final class ResultListViewModel: ObservableObject {

    // MARK: - Dependencies

    private let searchUseCase: SearchRepositoriesUseCase
    private let router: AppRouter
    let query: String

    // MARK: - State

    @Published var repositories: [GitHubRepository] = []
    @Published var totalCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var error: AppError?
    @Published var hasNextPage: Bool = false

    // MARK: - Private State

    private var currentPage: Int = 1

    // MARK: - Computed Properties

    var shouldShowEmptyState: Bool {
        !isLoading && repositories.isEmpty && error == nil
    }

    var shouldShowError: Bool {
        error != nil && repositories.isEmpty
    }

    // MARK: - Initialization

    init(
        query: String,
        searchUseCase: SearchRepositoriesUseCase,
        router: AppRouter
    ) {
        self.query = query
        self.searchUseCase = searchUseCase
        self.router = router
    }

    // MARK: - Lifecycle

    func onAppear() async {
        guard repositories.isEmpty && !isLoading else { return }
        await loadFirstPage()
    }

    // MARK: - Actions

    func loadFirstPage() async {
        isLoading = true
        error = nil
        currentPage = 1

        do {
            let result = try await searchUseCase.execute(keyword: query, page: 1)
            repositories = result.repositories
            totalCount = result.totalCount
            hasNextPage = result.hasNextPage
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = .unknown(error)
        }

        isLoading = false
    }

    func loadNextPage() async {
        guard hasNextPage && !isLoadingMore else { return }

        isLoadingMore = true
        let nextPage = currentPage + 1

        do {
            let result = try await searchUseCase.execute(keyword: query, page: nextPage)
            repositories.append(contentsOf: result.repositories)
            hasNextPage = result.hasNextPage
            currentPage = nextPage
        } catch is AppError {
            // Append 에러는 무시하고 hasNextPage만 false로 설정
            hasNextPage = false
        } catch {
            hasNextPage = false
        }

        isLoadingMore = false
    }

    func refresh() async {
        await loadFirstPage()
    }

    func selectRepository(_ repository: GitHubRepository) {
        router.showDetail(url: repository.htmlUrl)
    }

    func back() {
        router.pop()
    }
}
