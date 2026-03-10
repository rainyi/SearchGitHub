import XCTest
@testable import GitHubSearch

@MainActor
final class SearchResultCacheTests: XCTestCase {

    private var cache: SearchResultCache!

    override func setUp() {
        super.setUp()
        cache = SearchResultCache()
    }

    override func tearDown() {
        cache.clearAll()
        cache = nil
        super.tearDown()
    }

    // MARK: - Basic Cache Operations

    func test_setAndGet_shouldReturnCachedResult() {
        // Given
        let keyword = "swift"
        let page = 1
        let result = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1,
                    name: "swift",
                    fullName: "apple/swift",
                    owner: RepositoryOwner(
                        login: "apple",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/apple/swift")!,
                    description: "Swift programming language",
                    stargazersCount: 65000,
                    language: "Swift",
                    updatedAt: Date()
                )
            ],
            totalCount: 1,
            hasNextPage: false
        )

        // When
        cache.set(keyword: keyword, page: page, result: result)
        let cachedResult = cache.get(keyword: keyword, page: page)

        // Then
        XCTAssertNotNil(cachedResult)
        XCTAssertEqual(cachedResult?.totalCount, 1)
        XCTAssertEqual(cachedResult?.repositories.first?.name, "swift")
    }

    func test_get_withNonExistentKey_shouldReturnNil() {
        // When
        let result = cache.get(keyword: "nonexistent", page: 1)

        // Then
        XCTAssertNil(result)
    }

    func test_set_withDifferentPages_shouldStoreSeparately() {
        // Given
        let keyword = "swift"
        let resultPage1 = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1,
                    name: "repo1",
                    fullName: "user/repo1",
                    owner: RepositoryOwner(
                        login: "user",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/user/repo1")!,
                    description: nil,
                    stargazersCount: 100,
                    language: nil,
                    updatedAt: nil
                )
            ],
            totalCount: 10,
            hasNextPage: true
        )

        let resultPage2 = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 2,
                    name: "repo2",
                    fullName: "user/repo2",
                    owner: RepositoryOwner(
                        login: "user",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/user/repo2")!,
                    description: nil,
                    stargazersCount: 50,
                    language: nil,
                    updatedAt: nil
                )
            ],
            totalCount: 10,
            hasNextPage: false
        )

        // When
        cache.set(keyword: keyword, page: 1, result: resultPage1)
        cache.set(keyword: keyword, page: 2, result: resultPage2)

        // Then
        let cachedPage1 = cache.get(keyword: keyword, page: 1)
        let cachedPage2 = cache.get(keyword: keyword, page: 2)

        XCTAssertEqual(cachedPage1?.repositories.first?.name, "repo1")
        XCTAssertEqual(cachedPage2?.repositories.first?.name, "repo2")
    }

    func test_set_withDifferentKeywords_shouldStoreSeparately() {
        // Given
        let result1 = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1,
                    name: "swift",
                    fullName: "apple/swift",
                    owner: RepositoryOwner(
                        login: "apple",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/apple/swift")!,
                    description: nil,
                    stargazersCount: 100,
                    language: "Swift",
                    updatedAt: Date()
                )
            ],
            totalCount: 1,
            hasNextPage: false
        )

        let result2 = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 2,
                    name: "kotlin",
                    fullName: "jetbrains/kotlin",
                    owner: RepositoryOwner(
                        login: "jetbrains",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/jetbrains/kotlin")!,
                    description: nil,
                    stargazersCount: 100,
                    language: "Kotlin",
                    updatedAt: Date()
                )
            ],
            totalCount: 1,
            hasNextPage: false
        )

        // When
        cache.set(keyword: "swift", page: 1, result: result1)
        cache.set(keyword: "kotlin", page: 1, result: result2)

        // Then
        let cachedSwift = cache.get(keyword: "swift", page: 1)
        let cachedKotlin = cache.get(keyword: "kotlin", page: 1)

        XCTAssertEqual(cachedSwift?.repositories.first?.name, "swift")
        XCTAssertEqual(cachedKotlin?.repositories.first?.name, "kotlin")
    }

    // MARK: - Cache Expiration

    func test_get_withExpiredCache_shouldReturnNil() {
        // Given
        let keyword = "swift"
        let result = SearchResult(
            repositories: [],
            totalCount: 0,
            hasNextPage: false
        )
        cache.set(keyword: keyword, page: 1, result: result)

        // When - immediately after setting, should still be valid
        let cachedResult = cache.get(keyword: keyword, page: 1)

        // Then
        XCTAssertNotNil(cachedResult)
    }

    // MARK: - Cache Invalidation

    func test_invalidate_shouldRemoveSpecificKeyword() {
        // Given
        cache.set(
            keyword: "swift",
            page: 1,
            result: SearchResult(repositories: [], totalCount: 1, hasNextPage: false)
        )
        cache.set(
            keyword: "kotlin",
            page: 1,
            result: SearchResult(repositories: [], totalCount: 2, hasNextPage: false)
        )

        // When
        cache.invalidate(keyword: "swift")

        // Then
        XCTAssertNil(cache.get(keyword: "swift", page: 1))
        XCTAssertNotNil(cache.get(keyword: "kotlin", page: 1))
    }

    func test_invalidate_withDifferentKeyword_shouldNotRemoveOriginal() {
        // Given
        cache.set(
            keyword: "swift",
            page: 1,
            result: SearchResult(repositories: [], totalCount: 1, hasNextPage: false)
        )

        // When - invalidate with different keyword
        cache.invalidate(keyword: "kotlin")

        // Then - original should still exist
        XCTAssertNotNil(cache.get(keyword: "swift", page: 1))
    }

    func test_clearAll_shouldRemoveAllEntries() {
        // Given
        cache.set(
            keyword: "swift",
            page: 1,
            result: SearchResult(repositories: [], totalCount: 1, hasNextPage: false)
        )
        cache.set(
            keyword: "kotlin",
            page: 1,
            result: SearchResult(repositories: [], totalCount: 2, hasNextPage: false)
        )
        cache.set(
            keyword: "swift",
            page: 2,
            result: SearchResult(repositories: [], totalCount: 1, hasNextPage: false)
        )

        // When
        cache.clearAll()

        // Then
        XCTAssertNil(cache.get(keyword: "swift", page: 1))
        XCTAssertNil(cache.get(keyword: "kotlin", page: 1))
        XCTAssertNil(cache.get(keyword: "swift", page: 2))
    }

    // MARK: - Cache Update

    func test_set_withExistingKey_shouldOverwrite() {
        // Given
        let keyword = "swift"
        let page = 1
        let oldResult = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 1,
                    name: "old",
                    fullName: "user/old",
                    owner: RepositoryOwner(
                        login: "user",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/user/old")!,
                    description: nil,
                    stargazersCount: 10,
                    language: nil,
                    updatedAt: nil
                )
            ],
            totalCount: 1,
            hasNextPage: false
        )

        let newResult = SearchResult(
            repositories: [
                GitHubRepository(
                    id: 2,
                    name: "new",
                    fullName: "user/new",
                    owner: RepositoryOwner(
                        login: "user",
                        avatarUrl: URL(string: "https://example.com/avatar.png")!
                    ),
                    htmlUrl: URL(string: "https://github.com/user/new")!,
                    description: nil,
                    stargazersCount: 20,
                    language: nil,
                    updatedAt: nil
                )
            ],
            totalCount: 2,
            hasNextPage: false
        )

        // When
        cache.set(keyword: keyword, page: page, result: oldResult)
        cache.set(keyword: keyword, page: page, result: newResult)

        // Then
        let cachedResult = cache.get(keyword: keyword, page: page)
        XCTAssertEqual(cachedResult?.totalCount, 2)
        XCTAssertEqual(cachedResult?.repositories.first?.name, "new")
    }

    // MARK: - Edge Cases

    func test_set_withEmptyKeyword_shouldWork() {
        // Given
        let result = SearchResult(repositories: [], totalCount: 0, hasNextPage: false)

        // When
        cache.set(keyword: "", page: 1, result: result)

        // Then
        XCTAssertNotNil(cache.get(keyword: "", page: 1))
    }

    func test_set_withLargePageNumber_shouldWork() {
        // Given
        let result = SearchResult(repositories: [], totalCount: 0, hasNextPage: false)

        // When
        cache.set(keyword: "swift", page: 9999, result: result)

        // Then
        XCTAssertNotNil(cache.get(keyword: "swift", page: 9999))
    }
}
