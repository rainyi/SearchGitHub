import XCTest
@testable import GitHubSearch

@MainActor
final class UserDefaultsRecentSearchStoreTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var sut: UserDefaultsRecentSearchStore!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        sut = UserDefaultsRecentSearchStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "test.\(UUID().uuidString)")
        super.tearDown()
    }

    // MARK: - load Tests

    func testLoad_WhenEmpty_ThenReturnsEmptyArray() async throws {
        // When
        let items = try await sut.load()

        // Then
        XCTAssertTrue(items.isEmpty)
    }

    func testLoad_WhenItemsExist_ThenReturnsItems() async throws {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date().addingTimeInterval(-3600))
        ]
        try await sut.save(items)

        // When
        let loaded = try await sut.load()

        // Then
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - save Tests

    func testSave_WhenNewItems_ThenStoresCorrectly() async throws {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date())
        ]

        // When
        try await sut.save(items)
        let loaded = try await sut.load()

        // Then
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].query, "swift")
        XCTAssertEqual(loaded[1].query, "ios")
    }

    func testSave_WhenOverwriting_ThenReplacesExisting() async throws {
        // Given
        let originalItems = [RecentSearchItem(query: "old", searchedAt: Date())]
        try await sut.save(originalItems)

        // When
        let newItems = [RecentSearchItem(query: "new", searchedAt: Date())]
        try await sut.save(newItems)
        let loaded = try await sut.load()

        // Then
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].query, "new")
    }

    // MARK: - delete Tests

    func testDelete_WhenItemExists_ThenRemovesItem() async throws {
        // Given
        let item = RecentSearchItem(query: "swift", searchedAt: Date())
        try await sut.save([item])

        // When
        try await sut.delete(id: item.id)
        let loaded = try await sut.load()

        // Then
        XCTAssertTrue(loaded.isEmpty)
    }

    func testDelete_WhenItemDoesNotExist_ThenDoesNothing() async throws {
        // Given
        let item = RecentSearchItem(query: "swift", searchedAt: Date())
        try await sut.save([item])

        // When: 존재하지 않는 ID로 삭제
        try await sut.delete(id: UUID())
        let loaded = try await sut.load()

        // Then: 기존 아이템 유지
        XCTAssertEqual(loaded.count, 1)
    }

    // MARK: - clear Tests

    func testClear_WhenItemsExist_ThenRemovesAll() async throws {
        // Given
        let items = [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date())
        ]
        try await sut.save(items)

        // When
        try await sut.clear()
        let loaded = try await sut.load()

        // Then
        XCTAssertTrue(loaded.isEmpty)
    }

    func testClear_WhenEmpty_ThenDoesNothing() async throws {
        // When
        try await sut.clear()
        let loaded = try await sut.load()

        // Then
        XCTAssertTrue(loaded.isEmpty)
    }
}
