import XCTest
@testable import GitHubSearch

/// RecentSearchUseCase 단위 테스트
@MainActor
final class RecentSearchUseCaseTests: XCTestCase {

    private var sut: DefaultRecentSearchUseCase!
    private var mockStore: MockRecentSearchStore!

    override func setUp() {
        super.setUp()
        mockStore = MockRecentSearchStore()
        sut = DefaultRecentSearchUseCase(store: mockStore, maxCount: 10)
    }

    override func tearDown() {
        sut = nil
        mockStore = nil
        super.tearDown()
    }

    // MARK: - getRecentSearches Tests

    func testGetRecentSearches_WhenStoreIsEmpty_ThenReturnsEmptyArray() async throws {
        // Given
        mockStore.setItems([])

        // When
        let result = try await sut.getRecentSearches()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRecentSearches_WhenMultipleItemsExist_ThenReturnsSortedByDate() async throws {
        // Given
        let oldItem = RecentSearchItem(query: "old", searchedAt: Date().addingTimeInterval(-3600))
        let newItem = RecentSearchItem(query: "new", searchedAt: Date())
        mockStore.setItems([oldItem, newItem])

        // When
        let result = try await sut.getRecentSearches()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].query, "new")
        XCTAssertEqual(result[1].query, "old")
    }

    // MARK: - addSearch Tests

    func testAddSearch_WhenQueryIsEmpty_ThenDoesNotSave() async throws {
        // Given
        mockStore.setItems([])

        // When
        try await sut.addSearch(query: "   ")

        // Then
        let result = try await mockStore.load()
        XCTAssertTrue(result.isEmpty)
    }

    func testAddSearch_WhenQueryIsValid_ThenSavesTrimmedQuery() async throws {
        // Given
        mockStore.setItems([])

        // When
        try await sut.addSearch(query: "  swift  ")

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].query, "swift")
    }

    func testAddSearch_WhenDuplicateQueryExists_ThenRemovesOldAndAddsNew() async throws {
        // Given
        let existingItem = RecentSearchItem(query: "swift", searchedAt: Date().addingTimeInterval(-3600))
        mockStore.setItems([existingItem])

        // When
        try await sut.addSearch(query: "swift")

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].query, "swift")
        XCTAssertGreaterThan(result[0].searchedAt, existingItem.searchedAt)
    }

    func testAddSearch_WhenCaseInsensitiveDuplicate_ThenRemovesOldAndAddsNew() async throws {
        // Given
        let existingItem = RecentSearchItem(query: "Swift", searchedAt: Date().addingTimeInterval(-3600))
        mockStore.setItems([existingItem])

        // When
        try await sut.addSearch(query: "SWIFT")

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].query, "SWIFT")
    }

    func testAddSearch_WhenExceedsMaxCount_ThenKeepsOnlyMaxItems() async throws {
        // Given
        let useCase = DefaultRecentSearchUseCase(store: mockStore, maxCount: 3)
        try await useCase.addSearch(query: "first")
        try await useCase.addSearch(query: "second")
        try await useCase.addSearch(query: "third")

        // When
        try await useCase.addSearch(query: "fourth")

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].query, "fourth")
    }

    func testAddSearch_WhenNewItemAdded_ThenInsertsAtBeginning() async throws {
        // Given
        let existingItem = RecentSearchItem(query: "existing", searchedAt: Date().addingTimeInterval(-3600))
        mockStore.setItems([existingItem])

        // When
        try await sut.addSearch(query: "new")

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].query, "new")
        XCTAssertEqual(result[1].query, "existing")
    }

    // MARK: - deleteSearch Tests

    func testDeleteSearch_WhenItemExists_ThenRemovesItem() async throws {
        // Given
        let item = RecentSearchItem(query: "swift")
        mockStore.setItems([item])

        // When
        try await sut.deleteSearch(id: item.id)

        // Then
        let result = try await mockStore.load()
        XCTAssertTrue(result.isEmpty)
    }

    func testDeleteSearch_WhenItemDoesNotExist_ThenDoesNothing() async throws {
        // Given
        let item = RecentSearchItem(query: "swift")
        mockStore.setItems([item])
        let nonExistentId = UUID()

        // When
        try await sut.deleteSearch(id: nonExistentId)

        // Then
        let result = try await mockStore.load()
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - clearAll Tests

    func testClearAll_WhenItemsExist_ThenRemovesAll() async throws {
        // Given
        mockStore.setItems([
            RecentSearchItem(query: "first"),
            RecentSearchItem(query: "second")
        ])

        // When
        try await sut.clearAll()

        // Then
        let result = try await mockStore.load()
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Error Handling Tests

    func testGetRecentSearches_WhenStoreThrowsError_ThenPropagatesError() async {
        // Given
        mockStore.shouldThrowError = NSError(domain: "Test", code: 1)

        // When/Then
        do {
            _ = try await sut.getRecentSearches()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
