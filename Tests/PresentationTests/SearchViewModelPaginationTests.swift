import XCTest
@testable import GitHubSearchApp

// MARK: - Mocks

@MainActor
private final class MockSearchUseCaseForPagination: SearchRepositoriesUseCase {
    var capturedKeywords: [String] = []
    var capturedPages: [Int] = []
    var stubResults: [Int: SearchResult] = [:]
    var stubError: Error?
    var invalidateCacheCalled = false
    var invalidatedKeyword: String?

    func execute(keyword: String, page: Int) async throws -> SearchResult {
        capturedKeywords.append(keyword)
        capturedPages.append(page)

        if let error = stubError {
            throw error
        }

        return stubResults[page] ?? SearchResult(repositories: [], totalCount: 0, hasNextPage: false)
    }

    func invalidateCache(for keyword: String) {
        invalidateCacheCalled = true
        invalidatedKeyword = keyword
    }
}

@MainActor
private final class MockRecentSearchUseCaseForPagination: RecentSearchUseCase {
    var mockItems: [RecentSearchItem] = []

    func getRecentSearches() async throws -> [RecentSearchItem] {
        return mockItems
    }

    func addSearch(query: String) async throws {}
    func deleteSearch(id: UUID) async throws {}
    func clearAll() async throws {}
}

// MARK: - Tests

@MainActor
final class SearchViewModelPaginationTests: XCTestCase {

    private var sut: SearchViewModel!
    private var mockSearchUseCase: MockSearchUseCaseForPagination!
    private var mockRecentUseCase: MockRecentSearchUseCaseForPagination!
    private var router: AppRouter!

    override func setUp() {
        super.setUp()
        mockSearchUseCase = MockSearchUseCaseForPagination()
        mockRecentUseCase = MockRecentSearchUseCaseForPagination()
        router = AppRouter()
        sut = SearchViewModel(
            searchUseCase: mockSearchUseCase,
            recentSearchUseCase: mockRecentUseCase,
            router: router
        )
    }

    override func tearDown() {
        sut = nil
        mockSearchUseCase = nil
        mockRecentUseCase = nil
        router = nil
        super.tearDown()
    }

    // MARK: - Load Next Page Tests

    func testLoadNextPage_WhenHasNextPage_ThenLoadsNextPage() async {
        // Given
        sut.searchQuery = "swift"

        // First page result
        mockSearchUseCase.stubResults[1] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1, name: "repo1", fullName: "user/repo1",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil, stargazersCount: 100, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 3,
            hasNextPage: true
        )

        // Second page result
        mockSearchUseCase.stubResults[2] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 2, name: "repo2", fullName: "user/repo2",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo2")!,
                    description: nil, stargazersCount: 50, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 3,
            hasNextPage: true
        )

        // Initial search
        await sut.search()
        XCTAssertEqual(sut.repositories.count, 1)
        XCTAssertEqual(sut.repositories.first?.id, 1)
        XCTAssertTrue(sut.hasNextPage)

        // When - Load next page
        await sut.loadNextPage()

        // Then
        XCTAssertEqual(sut.repositories.count, 2)
        XCTAssertEqual(sut.repositories[0].id, 1)
        XCTAssertEqual(sut.repositories[1].id, 2)
        XCTAssertEqual(mockSearchUseCase.capturedPages, [1, 2])
    }

    func testLoadNextPage_WhenNoNextPage_ThenDoesNothing() async {
        // Given
        sut.searchQuery = "swift"

        mockSearchUseCase.stubResults[1] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1, name: "repo1", fullName: "user/repo1",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil, stargazersCount: 100, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 1,
            hasNextPage: false
        )

        // Initial search
        await sut.search()
        XCTAssertEqual(sut.repositories.count, 1)
        XCTAssertFalse(sut.hasNextPage)

        // When - Try to load next page
        await sut.loadNextPage()

        // Then - Should not call repository again
        XCTAssertEqual(mockSearchUseCase.capturedPages, [1])
        XCTAssertEqual(sut.repositories.count, 1)
    }

    func testLoadNextPage_WhenAlreadyLoading_ThenDoesNothing() async {
        // Given
        sut.searchQuery = "swift"

        mockSearchUseCase.stubResults[1] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1, name: "repo1", fullName: "user/repo1",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil, stargazersCount: 100, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 3,
            hasNextPage: true
        )

        mockSearchUseCase.stubResults[2] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 2, name: "repo2", fullName: "user/repo2",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo2")!,
                    description: nil, stargazersCount: 50, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 3,
            hasNextPage: true
        )

        // Initial search
        await sut.search()
        XCTAssertEqual(mockSearchUseCase.capturedPages, [1])

        // When - Call loadNextPage twice concurrently
        async let first: () = sut.loadNextPage()
        async let second: () = sut.loadNextPage()
        _ = await (first, second)

        // Then - Should only call page 2 once
        let page2CallCount = mockSearchUseCase.capturedPages.filter { $0 == 2 }.count
        XCTAssertEqual(page2CallCount, 1)
    }

    func testLoadNextPage_WhenErrorOccurs_ThenRevertsPageIncrement() async {
        // Given
        sut.searchQuery = "swift"

        mockSearchUseCase.stubResults[1] = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1, name: "repo1", fullName: "user/repo1",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil, stargazersCount: 100, language: "Swift", updatedAt: Date()
                )
            ],
            totalCount: 3,
            hasNextPage: true
        )

        // Second page will throw error
        mockSearchUseCase.stubError = AppError.network(NSError(domain: "test", code: -1))

        // Initial search
        await sut.search()
        XCTAssertEqual(sut.repositories.count, 1)

        // When - Try to load next page (will fail)
        await sut.loadNextPage()

        // Then - Should keep original results
        XCTAssertEqual(sut.repositories.count, 1)
        XCTAssertTrue(sut.hasNextPage) // Still has next page
    }

    func testLoadNextPage_WhenEmptyQuery_ThenDoesNothing() async {
        // Given
        sut.searchQuery = ""

        // When
        await sut.loadNextPage()

        // Then
        XCTAssertTrue(mockSearchUseCase.capturedKeywords.isEmpty)
    }

    func testLoadNextPage_MultiplePages_ThenAccumulatesResults() async {
        // Given
        sut.searchQuery = "swift"

        // Page 1: 2 results, has next
        mockSearchUseCase.stubResults[1] = SearchResult(
            repositories: [
                GitHubRepository(id: 1, name: "repo1", fullName: "user/repo1",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil, stargazersCount: 100, language: "Swift", updatedAt: Date()),
                GitHubRepository(id: 2, name: "repo2", fullName: "user/repo2",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo2")!,
                    description: nil, stargazersCount: 90, language: "Swift", updatedAt: Date())
            ],
            totalCount: 5,
            hasNextPage: true
        )

        // Page 2: 2 results, has next
        mockSearchUseCase.stubResults[2] = SearchResult(
            repositories: [
                GitHubRepository(id: 3, name: "repo3", fullName: "user/repo3",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo3")!,
                    description: nil, stargazersCount: 80, language: "Swift", updatedAt: Date()),
                GitHubRepository(id: 4, name: "repo4", fullName: "user/repo4",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo4")!,
                    description: nil, stargazersCount: 70, language: "Swift", updatedAt: Date())
            ],
            totalCount: 5,
            hasNextPage: true
        )

        // Page 3: 1 result, no next
        mockSearchUseCase.stubResults[3] = SearchResult(
            repositories: [
                GitHubRepository(id: 5, name: "repo5", fullName: "user/repo5",
                    owner: RepositoryOwner(login: "user", avatarUrl: URL(string: "https://example.com/avatar.png")!),
                    htmlUrl: URL(string: "https://github.com/user/repo5")!,
                    description: nil, stargazersCount: 60, language: "Swift", updatedAt: Date())
            ],
            totalCount: 5,
            hasNextPage: false
        )

        // When - Initial search + load 2 more pages
        await sut.search()
        XCTAssertEqual(sut.repositories.count, 2)

        await sut.loadNextPage()
        XCTAssertEqual(sut.repositories.count, 4)
        XCTAssertTrue(sut.hasNextPage)

        await sut.loadNextPage()

        // Then
        XCTAssertEqual(sut.repositories.count, 5)
        XCTAssertEqual(sut.repositories.map { $0.id }, [1, 2, 3, 4, 5])
        XCTAssertFalse(sut.hasNextPage)
    }
}
