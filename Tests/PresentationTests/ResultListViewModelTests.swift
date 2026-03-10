import XCTest
@testable import GitHubSearch

@MainActor
final class ResultListViewModelTests: XCTestCase {

    // MARK: - Mocks

    private final class MockSearchUseCase: SearchRepositoriesUseCase {
        var mockResult: SearchResult?
        var mockError: Error?

        init(mockResult: SearchResult? = nil, mockError: Error? = nil) {
            self.mockResult = mockResult
            self.mockError = mockError
        }

        func execute(keyword: String, page: Int) async throws -> SearchResult {
            if let error = mockError {
                throw error
            }
            return mockResult ?? SearchResult(repositories: [], totalCount: 0, hasNextPage: false)
        }
    }

    // MARK: - Tests

    func testInitialState_ThenEmptyRepositoriesAndNotLoading() {
        // Given
        let viewModel = createViewModel()

        // Then
        XCTAssertTrue(viewModel.repositories.isEmpty)
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.hasNextPage)
        XCTAssertTrue(viewModel.shouldShowEmptyState)
        XCTAssertFalse(viewModel.shouldShowError)
    }

    func testLoadFirstPage_WhenSuccess_ThenUpdatesRepositories() async {
        // Given
        let mockRepositories = [
            GitHubRepository.sample,
            GitHubRepository(
                id: 2,
                name: "test",
                fullName: "user/test",
                owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                htmlUrl: URL(string: "https://github.com/user/test")!,
                description: "Test repo",
                stargazersCount: 100,
                language: "Swift",
                updatedAt: Date()
            )
        ]
        let mockResult = SearchResult(
            repositories: mockRepositories,
            totalCount: 2,
            hasNextPage: true
        )
        let viewModel = createViewModel(searchUseCase: MockSearchUseCase(mockResult: mockResult))

        // When
        await viewModel.loadFirstPage()

        // Then
        XCTAssertEqual(viewModel.repositories.count, 2)
        XCTAssertEqual(viewModel.totalCount, 2)
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadFirstPage_WhenError_ThenSetsError() async {
        // Given
        let viewModel = createViewModel(searchUseCase: MockSearchUseCase(mockError: TestError.mockError))

        // When
        await viewModel.loadFirstPage()

        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.repositories.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.shouldShowError)
    }

    func testLoadNextPage_WhenHasNextPage_ThenAppendsRepositories() async {
        // Given
        let firstPageRepos = [GitHubRepository.sample]
        let secondPageRepos = [
            GitHubRepository(
                id: 2,
                name: "second",
                fullName: "user/second",
                owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                htmlUrl: URL(string: "https://github.com/user/second")!,
                description: "Second repo",
                stargazersCount: 50,
                language: "Kotlin",
                updatedAt: Date()
            )
        ]

        let mockUseCase = MockSearchUseCase(
            mockResult: SearchResult(repositories: firstPageRepos, totalCount: 2, hasNextPage: true)
        )
        let viewModel = createViewModel(searchUseCase: mockUseCase)

        // First page load
        await viewModel.loadFirstPage()
        XCTAssertEqual(viewModel.repositories.count, 1)

        // Change result for second page
        mockUseCase.mockResult = SearchResult(repositories: secondPageRepos, totalCount: 2, hasNextPage: false)

        // When - Load second page
        await viewModel.loadNextPage()

        // Then
        XCTAssertEqual(viewModel.repositories.count, 2)
        XCTAssertEqual(viewModel.repositories[1].name, "second")
        XCTAssertFalse(viewModel.hasNextPage)
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    func testLoadNextPage_WhenNoNextPage_ThenDoesNothing() async {
        // Given
        let mockResult = SearchResult(
            repositories: [GitHubRepository.sample],
            totalCount: 1,
            hasNextPage: false
        )
        let viewModel = createViewModel(searchUseCase: MockSearchUseCase(mockResult: mockResult))

        // Load first page
        await viewModel.loadFirstPage()
        XCTAssertEqual(viewModel.repositories.count, 1)

        // When - Try to load next page when hasNextPage is false
        await viewModel.loadNextPage()

        // Then - Should still have only 1 repository
        XCTAssertEqual(viewModel.repositories.count, 1)
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    func testRefresh_WhenCalled_ThenReloadsFirstPage() async {
        // Given
        let mockResult = SearchResult(
            repositories: [GitHubRepository.sample],
            totalCount: 1,
            hasNextPage: false
        )
        let viewModel = createViewModel(searchUseCase: MockSearchUseCase(mockResult: mockResult))

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.repositories.count, 1)
        XCTAssertEqual(viewModel.totalCount, 1)
    }

    func testSelectRepository_ThenNavigatesToDetail() {
        // Given
        let router = AppRouter()
        let viewModel = createViewModel(router: router)
        let repository = GitHubRepository.sample

        // When
        viewModel.selectRepository(repository)

        // Then - Router path should have 1 item (repositoryDetail route)
        XCTAssertEqual(router.path.count, 1)
    }

    func testBack_ThenPopsFromNavigation() {
        // Given
        let router = AppRouter()
        // First push something
        router.showDetail(url: URL(string: "https://github.com/test/repo")!)
        XCTAssertEqual(router.path.count, 1)

        let viewModel = createViewModel(router: router)

        // When
        viewModel.back()

        // Then
        XCTAssertEqual(router.path.count, 0)
    }

    // MARK: - Helpers

    private func createViewModel(
        query: String = "swift",
        searchUseCase: SearchRepositoriesUseCase? = nil,
        router: AppRouter? = nil
    ) -> ResultListViewModel {
        ResultListViewModel(
            query: query,
            searchUseCase: searchUseCase ?? MockSearchUseCase(),
            router: router ?? AppRouter()
        )
    }

    private enum TestError: Error {
        case mockError
    }
}
