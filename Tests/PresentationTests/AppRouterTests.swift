import XCTest
@testable import GitHubSearch

@MainActor
final class AppRouterTests: XCTestCase {

    private var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Navigation Tests

    func testShowResults_WhenCalled_ThenAppendsResultListToPath() {
        // When
        sut.showResults(for: "swift")

        // Then
        XCTAssertEqual(sut.path.count, 1)
    }

    func testShowDetail_WhenCalled_ThenAppendsRepositoryDetailToPath() {
        // Given
        let url = URL(string: "https://github.com/apple/swift")!

        // When
        sut.showDetail(url: url)

        // Then
        XCTAssertEqual(sut.path.count, 1)
    }

    func testPop_WhenPathNotEmpty_ThenRemovesLast() {
        // Given
        sut.showResults(for: "swift")
        XCTAssertEqual(sut.path.count, 1)

        // When
        sut.pop()

        // Then
        XCTAssertEqual(sut.path.count, 0)
    }

    func testPop_WhenPathEmpty_ThenDoesNothing() {
        // When
        sut.pop()

        // Then
        XCTAssertEqual(sut.path.count, 0)
    }

    func testPopToRoot_WhenMultipleRoutes_ThenClearsAll() {
        // Given
        sut.showResults(for: "swift")
        sut.showDetail(url: URL(string: "https://github.com/apple/swift")!)
        sut.showResults(for: "ios")
        XCTAssertEqual(sut.path.count, 3)

        // When
        sut.popToRoot()

        // Then
        XCTAssertEqual(sut.path.count, 0)
    }

    func testPopToRoot_WhenEmptyPath_ThenDoesNothing() {
        // When
        sut.popToRoot()

        // Then
        XCTAssertEqual(sut.path.count, 0)
    }

    // MARK: - Navigation Sequence Tests

    func testNavigationSequence_MultiplePushesAndPop() {
        // Given: push 3 routes
        sut.showResults(for: "swift")
        sut.showResults(for: "ios")
        sut.showResults(for: "combine")
        XCTAssertEqual(sut.path.count, 3)

        // When: pop 1
        sut.pop()

        // Then
        XCTAssertEqual(sut.path.count, 2)

        // When: push 1 more
        sut.showDetail(url: URL(string: "https://example.com")!)

        // Then
        XCTAssertEqual(sut.path.count, 3)

        // When: pop to root
        sut.popToRoot()

        // Then
        XCTAssertEqual(sut.path.count, 0)
    }
}
