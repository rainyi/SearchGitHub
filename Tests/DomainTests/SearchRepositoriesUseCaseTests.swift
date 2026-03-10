import XCTest
@testable import GitHubSearch

/// SearchRepositoriesUseCase 단위 테스트
@MainActor
final class SearchRepositoriesUseCaseTests: XCTestCase {

    private var sut: DefaultSearchRepositoriesUseCase!
    private var mockRepository: MockGitHubRepositoryRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockGitHubRepositoryRepository()
        sut = DefaultSearchRepositoriesUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Input Validation Tests

    func testExecute_WhenKeywordIsEmpty_ThenThrowsEmptyQueryError() async {
        // Given
        let emptyKeyword = ""

        // When/Then
        do {
            _ = try await sut.execute(keyword: emptyKeyword, page: 1)
            XCTFail("Expected emptyQuery error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.emptyQuery)
        } catch {
            XCTFail("Expected AppError.emptyQuery, got \(error)")
        }
    }

    func testExecute_WhenKeywordIsWhitespaceOnly_ThenThrowsEmptyQueryError() async {
        // Given
        let whitespaceKeyword = "   "

        // When/Then
        do {
            _ = try await sut.execute(keyword: whitespaceKeyword, page: 1)
            XCTFail("Expected emptyQuery error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, AppError.emptyQuery)
        } catch {
            XCTFail("Expected AppError.emptyQuery, got \(error)")
        }
    }

    func testExecute_WhenPageIsZero_ThenThrowsInvalidParameterError() async {
        // Given
        let keyword = "swift"
        let page = 0

        // When/Then
        do {
            _ = try await sut.execute(keyword: keyword, page: page)
            XCTFail("Expected invalidParameter error to be thrown")
        } catch let error as AppError {
            if case .invalidParameter = error {
                // Expected
            } else {
                XCTFail("Expected AppError.invalidParameter, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.invalidParameter, got \(error)")
        }
    }

    func testExecute_WhenPageIsNegative_ThenThrowsInvalidParameterError() async {
        // Given
        let keyword = "swift"
        let page = -1

        // When/Then
        do {
            _ = try await sut.execute(keyword: keyword, page: page)
            XCTFail("Expected invalidParameter error to be thrown")
        } catch let error as AppError {
            if case .invalidParameter = error {
                // Expected
            } else {
                XCTFail("Expected AppError.invalidParameter, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.invalidParameter, got \(error)")
        }
    }

    // MARK: - Successful Execution Tests

    func testExecute_WhenValidInput_ThenCallsRepositoryWithTrimmedKeyword() async throws {
        // Given
        let keyword = "  swift  "
        let page = 1
        mockRepository.stubResult = SearchResult(
            repositories: [GitHubRepository.sample],
            totalCount: 1,
            hasNextPage: false
        )

        // When
        _ = try await sut.execute(keyword: keyword, page: page)

        // Then
        XCTAssertEqual(mockRepository.capturedKeyword, "swift")
        XCTAssertEqual(mockRepository.capturedPage, 1)
    }

    func testExecute_WhenValidInput_ThenReturnsSearchResult() async throws {
        // Given
        let keyword = "swift"
        let page = 1
        let expectedResult = SearchResult(
            repositories: [GitHubRepository.sample],
            totalCount: 1,
            hasNextPage: false
        )
        mockRepository.stubResult = expectedResult

        // When
        let result = try await sut.execute(keyword: keyword, page: page)

        // Then
        XCTAssertEqual(result.repositories.count, 1)
        XCTAssertEqual(result.totalCount, 1)
        XCTAssertFalse(result.hasNextPage)
    }

    func testExecute_WhenPageIsGreaterThanOne_ThenCallsRepositoryWithCorrectPage() async throws {
        // Given
        let keyword = "swift"
        let page = 3

        // When
        _ = try await sut.execute(keyword: keyword, page: page)

        // Then
        XCTAssertEqual(mockRepository.capturedPage, 3)
    }

    // MARK: - Error Propagation Tests

    func testExecute_WhenRepositoryThrowsError_ThenPropagatesError() async {
        // Given
        let keyword = "swift"
        let page = 1
        mockRepository.stubError = AppError.network(NSError(domain: "test", code: -1))

        // When/Then
        do {
            _ = try await sut.execute(keyword: keyword, page: page)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }

    func testExecute_WhenRepositoryThrowsRateLimitError_ThenPropagatesError() async {
        // Given
        let keyword = "swift"
        let page = 1
        let resetAt = Date().addingTimeInterval(60)
        mockRepository.stubError = AppError.rateLimit(resetAt: resetAt)

        // When/Then
        do {
            _ = try await sut.execute(keyword: keyword, page: page)
            XCTFail("Expected error to be thrown")
        } catch let error as AppError {
            if case .rateLimit = error {
                // Expected
            } else {
                XCTFail("Expected AppError.rateLimit, got \(error)")
            }
        } catch {
            XCTFail("Expected AppError.rateLimit, got \(error)")
        }
    }

    // MARK: - Edge Cases

    func testExecute_WhenKeywordHasSpecialCharacters_ThenCallsRepositoryWithSameKeyword() async throws {
        // Given
        let keyword = "swift-lang_2.0"
        let page = 1

        // When
        _ = try await sut.execute(keyword: keyword, page: page)

        // Then
        XCTAssertEqual(mockRepository.capturedKeyword, keyword)
    }

    func testExecute_WhenKeywordIsVeryLong_ThenCallsRepositoryWithSameKeyword() async throws {
        // Given
        let keyword = String(repeating: "a", count: 1000)
        let page = 1

        // When
        _ = try await sut.execute(keyword: keyword, page: page)

        // Then
        XCTAssertEqual(mockRepository.capturedKeyword, keyword)
    }
}
