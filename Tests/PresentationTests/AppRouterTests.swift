import XCTest
@testable import GitHubSearchApp

@MainActor
final class AppRouterTests: XCTestCase {

    private var router: AppRouter!

    override func setUp() {
        super.setUp()
        router = AppRouter()
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_initialState_pathIsEmpty() {
        XCTAssertTrue(router.path.isEmpty)
    }

    func test_showDetail_addsRouteToPath() {
        // Given
        let url = URL(string: "https://github.com/test/repo")!

        // When
        router.showDetail(url: url)

        // Then
        XCTAssertEqual(router.path.count, 1)
    }

    func test_pop_removesLastRoute() {
        // Given
        let url = URL(string: "https://github.com/test/repo")!
        router.showDetail(url: url)
        XCTAssertEqual(router.path.count, 1)

        // When
        router.pop()

        // Then
        XCTAssertTrue(router.path.isEmpty)
    }

    func test_pop_whenPathIsEmpty_doesNothing() {
        // When
        router.pop()

        // Then
        XCTAssertTrue(router.path.isEmpty)
    }

    func test_popToRoot_removesAllRoutes() {
        // Given
        let url1 = URL(string: "https://github.com/test/repo1")!
        let url2 = URL(string: "https://github.com/test/repo2")!
        router.showDetail(url: url1)
        router.showDetail(url: url2)
        XCTAssertEqual(router.path.count, 2)

        // When
        router.popToRoot()

        // Then
        XCTAssertTrue(router.path.isEmpty)
    }

    func test_popToRoot_whenPathIsEmpty_doesNothing() {
        // When
        router.popToRoot()

        // Then
        XCTAssertTrue(router.path.isEmpty)
    }
}
