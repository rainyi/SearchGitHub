import XCTest
@testable import GitHubSearch

// MARK: - Mocks

private actor MockSearchUseCase: SearchRepositoriesUseCase {
    nonisolated(unsafe) var capturedKeywords: [String] = []
    nonisolated(unsafe) var capturedPages: [Int] = []
    nonisolated(unsafe) var stubResult: SearchResult = SearchResult(repositories: [], totalCount: 0, hasNextPage: false)

    func execute(keyword: String, page: Int) async throws -> SearchResult {
        capturedKeywords.append(keyword)
        capturedPages.append(page)
        return stubResult
    }

    nonisolated func getCallCount() -> Int {
        capturedKeywords.count
    }
}

private actor MockRecentSearchUseCase: RecentSearchUseCase {
    nonisolated(unsafe) var mockItems: [RecentSearchItem] = []
    nonisolated(unsafe) var mockError: Error?
    nonisolated(unsafe) var capturedAddQuery: String?
    nonisolated(unsafe) var capturedDeleteId: UUID?
    nonisolated(unsafe) var clearAllCalled = false

    func getRecentSearches() async throws -> [RecentSearchItem] {
        if let error = mockError { throw error }
        return mockItems
    }

    func addSearch(query: String) async throws {
        if let error = mockError { throw error }
        capturedAddQuery = query
        let item = RecentSearchItem(query: query, searchedAt: Date())
        mockItems.append(item)
    }

    func deleteSearch(id: UUID) async throws {
        if let error = mockError { throw error }
        capturedDeleteId = id
        mockItems.removeAll { $0.id == id }
    }

    func clearAll() async throws {
        if let error = mockError { throw error }
        clearAllCalled = true
        mockItems.removeAll()
    }

    nonisolated func setMockItems(_ items: [RecentSearchItem]) {
        mockItems = items
    }
}

// MARK: - Tests

@MainActor
final class SearchViewModelTests: XCTestCase {

    private var sut: SearchViewModel!
    private var mockSearchUseCase: MockSearchUseCase!
    private var mockRecentUseCase: MockRecentSearchUseCase!
    private var router: AppRouter!

    override func setUp() {
        super.setUp()
        mockSearchUseCase = MockSearchUseCase()
        mockRecentUseCase = MockRecentSearchUseCase()
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

    // MARK: - Initial State Tests

    func testInitialState_ThenEmptyQueryAndNoRecentSearches() {
        // Then
        XCTAssertTrue(sut.searchQuery.isEmpty)
        XCTAssertTrue(sut.recentSearches.isEmpty)
        XCTAssertFalse(sut.isSearching)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isSearchButtonEnabled)
    }

    // MARK: - Search Button Enable Tests

    func testIsSearchButtonEnabled_WhenQueryNotEmpty_ThenTrue() {
        // When
        sut.searchQuery = "swift"

        // Then
        XCTAssertTrue(sut.isSearchButtonEnabled)
    }

    func testIsSearchButtonEnabled_WhenQueryIsWhitespaceOnly_ThenFalse() {
        // When
        sut.searchQuery = "   "

        // Then
        XCTAssertFalse(sut.isSearchButtonEnabled)
    }

    func testIsSearchButtonEnabled_WhenIsSearching_ThenFalse() {
        // Given
        sut.searchQuery = "swift"

        // When
        sut.isSearching = true

        // Then
        XCTAssertFalse(sut.isSearchButtonEnabled)
    }

    // MARK: - Search Tests

    func testSearch_WhenValidQuery_ThenAddsToRecentSearchesAndUpdatesState() async {
        // Given
        sut.searchQuery = "swift"

        // When
        await sut.search()

        // Then
        XCTAssertEqual(mockRecentUseCase.capturedAddQuery, "swift")
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isSearching)
        XCTAssertNil(sut.error)
    }

    func testSearch_WhenEmptyQuery_ThenDoesNothing() async {
        // Given
        sut.searchQuery = "   "

        // When
        await sut.search()

        // Then
        XCTAssertNil(mockRecentUseCase.capturedAddQuery)
        XCTAssertEqual(router.path.count, 0)
    }

    func testSearch_WhenErrorOccurs_ThenSetsError() async {
        // Given
        sut.searchQuery = "swift"
        mockRecentUseCase.mockError = AppError.network(NSError(domain: "test", code: -1))

        // When
        await sut.search()

        // Then
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isSearching)
        XCTAssertEqual(router.path.count, 0)
    }

    // MARK: - onAppear Tests

    func testOnAppear_WhenCalled_ThenLoadsRecentSearches() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)

        // When
        await sut.onAppear()

        // Then
        XCTAssertEqual(sut.recentSearches.count, 2)
        XCTAssertEqual(sut.recentSearches[0].query, "swift")
        XCTAssertEqual(sut.recentSearches[1].query, "ios")
    }

    func testOnAppear_WhenErrorOccurs_ThenRecentSearchesEmpty() async {
        // Given
        mockRecentUseCase.mockError = AppError.decoding(NSError(domain: "test", code: -1))

        // When
        await sut.onAppear()

        // Then
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Select Recent Search Tests

    func testSelectRecentSearch_ThenSetsQueryAndSearches() async {
        // Given
        let item = RecentSearchItem(query: "swift", searchedAt: Date())

        // When
        sut.selectRecentSearch(item)

        // Then (async search completes)
        XCTAssertEqual(sut.searchQuery, "swift")

        // Wait for async task
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        XCTAssertEqual(mockRecentUseCase.capturedAddQuery, "swift")
    }

    // MARK: - Delete Recent Search Tests

    func testDeleteRecentSearch_WhenCalled_ThenDeletesAndReloads() async {
        // Given
        let item = RecentSearchItem(query: "swift", searchedAt: Date())
        mockRecentUseCase.setMockItems([item])
        await sut.onAppear()
        XCTAssertEqual(sut.recentSearches.count, 1)

        // When
        await sut.deleteRecentSearch(id: item.id)

        // Then
        XCTAssertEqual(mockRecentUseCase.capturedDeleteId, item.id)
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Clear All Tests

    func testClearAllRecentSearches_WhenCalled_ThenClearsAndReloads() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()
        XCTAssertEqual(sut.recentSearches.count, 2)

        // When
        await sut.clearAllRecentSearches()

        // Then
        XCTAssertTrue(mockRecentUseCase.clearAllCalled)
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Pull to Refresh Tests

    func testRefresh_WhenCalled_ThenReloadsSearchResults() async {
        // Given
        sut.searchQuery = "swift"
        await sut.search()
        XCTAssertTrue(sut.hasSearched)
        XCTAssertEqual(mockSearchUseCase.getCallCount(), 1)

        // When - refresh는 search()를 다시 호출
        await sut.refresh()

        // Then - searchUseCase.execute가 2번째 호출됨 (새로고침)
        XCTAssertEqual(mockSearchUseCase.getCallCount(), 2)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isSearching)
        XCTAssertNil(sut.error)
    }

    func testRefresh_WhenNoPreviousSearch_ThenDoesNothing() async {
        // Given
        sut.searchQuery = ""
        XCTAssertFalse(sut.hasSearched)

        // When
        await sut.refresh()

        // Then
        XCTAssertFalse(sut.hasSearched)
        XCTAssertNil(mockRecentUseCase.capturedAddQuery)
    }

    // MARK: - Autocomplete Tests

    func testAutocomplete_WhenQuery2CharsAndMatchesExist_ThenShowsSuggestions() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "swiftui", searchedAt: Date().addingTimeInterval(-3600)),
            RecentSearchItem(query: "ios", searchedAt: Date().addingTimeInterval(-7200))
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()

        // When
        sut.searchQuery = "sw"

        // 디바운스 대기 (300ms + 10ms 여유)
        try? await Task.sleep(nanoseconds: 310_000_000)

        // Then
        XCTAssertEqual(sut.autocompleteSuggestions.count, 2)
        XCTAssertEqual(sut.autocompleteSuggestions[0].query, "swift")
        XCTAssertEqual(sut.autocompleteSuggestions[1].query, "swiftui")
    }

    func testAutocomplete_WhenQueryLessThan2Chars_ThenNoSuggestions() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()

        // When
        sut.searchQuery = "s"

        // Then
        XCTAssertTrue(sut.autocompleteSuggestions.isEmpty)
    }

    func testAutocomplete_WhenAlreadySearched_ThenNoSuggestions() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()
        sut.searchQuery = "swift"
        await sut.search()

        // When
        sut.searchQuery = "swi"

        // Then
        XCTAssertTrue(sut.autocompleteSuggestions.isEmpty)
    }

    func testAutocomplete_WhenQueryWithDifferentCase_ThenMatchesCaseInsensitive() async {
        // Given
        let items = [
            RecentSearchItem(query: "Swift", searchedAt: Date()),
            RecentSearchItem(query: "SWIFTUI", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()

        // When
        sut.searchQuery = "sw"

        // 디바운스 대기
        try? await Task.sleep(nanoseconds: 350_000_000)

        // Then
        XCTAssertEqual(sut.autocompleteSuggestions.count, 2)
        XCTAssertEqual(sut.autocompleteSuggestions[0].query, "Swift")
        XCTAssertEqual(sut.autocompleteSuggestions[1].query, "SWIFTUI")
    }

    func testAutocomplete_WhenQueryWithWhitespace_ThenTrimsAndMatches() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date())
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()

        // When
        sut.searchQuery = "  sw  "

        // 디바운스 대기
        try? await Task.sleep(nanoseconds: 350_000_000)

        // Then
        XCTAssertEqual(sut.autocompleteSuggestions.count, 1)
        XCTAssertEqual(sut.autocompleteSuggestions[0].query, "swift")
    }

    func testAutocomplete_WhenMoreThan5Matches_ThenShowsOnly5() async {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "swiftui", searchedAt: Date().addingTimeInterval(-3600)),
            RecentSearchItem(query: "swing", searchedAt: Date().addingTimeInterval(-7200)),
            RecentSearchItem(query: "swell", searchedAt: Date().addingTimeInterval(-10800)),
            RecentSearchItem(query: "sword", searchedAt: Date().addingTimeInterval(-14400)),
            RecentSearchItem(query: "swan", searchedAt: Date().addingTimeInterval(-18000))
        ]
        mockRecentUseCase.setMockItems(items)
        await sut.onAppear()

        // When
        sut.searchQuery = "sw"

        // 디바운스 대기
        try? await Task.sleep(nanoseconds: 350_000_000)

        // Then
        XCTAssertEqual(sut.autocompleteSuggestions.count, 5)
    }
}
