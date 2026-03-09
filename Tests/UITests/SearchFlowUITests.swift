import XCTest

/// 검색 화면 UI 흐름 테스트
/// - Note: 이 테스트들은 실제 앱을 실행하고 사용자 인터랙션을 시뮬레이션합니다
final class SearchFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 테스트 시작 전 UserDefaults 초기화 (최근 검색어 클리어)
        app.launchArguments = ["--uitesting", "--reset-search-history"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Search Flow Tests

    /// 검색어 입력 → 검색 결과 표시 흐름 테스트
    func testSearch_WhenEnterQueryAndSearch_ThenShowsResults() throws {
        // Given: 검색 화면이 표시됨
        let searchField = app.textFields["저장소 검색"]
        XCTAssertTrue(searchField.exists, "검색 필드가 존재해야 함")

        // When: 검색어 입력 및 검색 실행
        searchField.tap()
        searchField.typeText("swift")

        let searchButton = app.buttons["검색"]
        XCTAssertTrue(searchButton.exists, "검색 버튼이 존재해야 함")
        searchButton.tap()

        // Then: 결과 화면으로 이동
        let resultNavigationTitle = app.navigationBars["swift"]
        XCTAssertTrue(resultNavigationTitle.waitForExistence(timeout: 5), "검색어가 타이틀로 표시되어야 함")

        // And: 결과 리스트가 표시됨
        let resultList = app.collectionViews.firstMatch
        XCTAssertTrue(resultList.waitForExistence(timeout: 5), "결과 리스트가 표시되어야 함")
    }

    /// 검색 결과 셀 탭 → WebView 표시 흐름 테스트
    func testTapResultCell_WhenCellTapped_ThenShowsWebView() throws {
        // Given: 검색 결과가 표시됨
        performSearch(query: "swift")

        // When: 첫 번째 셀 탭
        let firstCell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "첫 번째 셀이 존재해야 함")
        firstCell.tap()

        // Then: WebView 화면으로 이동
        let webViewNavigation = app.navigationBars["저장소 상세"]
        XCTAssertTrue(webViewNavigation.waitForExistence(timeout: 5), "WebView 타이틀이 표시되어야 함")
    }

    /// 뒤로 가기 버튼 테스트
    func testBackButton_WhenTapped_ThenReturnsToSearchView() throws {
        // Given: 검색 결과 화면
        performSearch(query: "swift")

        // When: 뒤로 가기 버튼 탭
        let backButton = app.buttons["뒤로"]
        if backButton.exists {
            backButton.tap()
        } else {
            // iOS 17+에서 뒤로 가기 스와이프
            app.swipeRight()
        }

        // Then: 검색 화면으로 돌아옴
        let searchNavigation = app.navigationBars["GitHub 검색"]
        XCTAssertTrue(searchNavigation.waitForExistence(timeout: 3), "검색 화면으로 돌아와야 함")
    }

    // MARK: - Recent Searches Tests

    /// 최근 검색어 저장 및 표시 테스트
    func testRecentSearches_WhenSearchPerformed_ThenShowsInRecentList() throws {
        // Given: 검색 수행
        performSearch(query: "swift")

        // 뒤로 가기
        goBack()

        // Then: 최근 검색어에 "swift" 표시됨
        let recentSearchCell = app.buttons["swift"]
        XCTAssertTrue(recentSearchCell.waitForExistence(timeout: 3), "최근 검색어에 표시되어야 함")
    }

    /// 최근 검색어 탭 → 해당 검색어로 재검색
    func testTapRecentSearch_WhenTapped_ThenPerformsSearch() throws {
        // Given: 이전 검색으로 최근 검색어에 항목 추가
        performSearch(query: "swift")
        goBack()

        // When: 최근 검색어 탭
        let recentSearchCell = app.buttons["swift"]
        XCTAssertTrue(recentSearchCell.waitForExistence(timeout: 3))
        recentSearchCell.tap()

        // Then: 검색 결과 화면으로 이동
        let resultNavigationTitle = app.navigationBars["swift"]
        XCTAssertTrue(resultNavigationTitle.waitForExistence(timeout: 5), "검색 결과가 표시되어야 함")
    }

    /// 전체 삭제 버튼 테스트
    func testClearAllRecentSearches_WhenTapped_ThenClearsAll() throws {
        // Given: 여러 검색어 추가
        performSearch(query: "swift")
        goBack()
        performSearch(query: "ios")
        goBack()

        // 최근 검색어가 표시되는 것 확인
        let swiftCell = app.buttons["swift"]
        XCTAssertTrue(swiftCell.waitForExistence(timeout: 3))

        // When: 전체 삭제 버튼 탭
        let clearAllButton = app.buttons["전체 삭제"]
        XCTAssertTrue(clearAllButton.exists, "전체 삭제 버튼이 존재해야 함")
        clearAllButton.tap()

        // Then: 최근 검색어가 비어있음 (빈 상태 UI 표시)
        XCTAssertFalse(swiftCell.exists, "최근 검색어가 삭제되어야 함")
    }

    /// 검색어 입력 시 X 버튼으로 클리어 테스트
    func testClearButton_WhenSearchQueryNotEmpty_ThenShowsClearButton() throws {
        // Given: 검색어 입력
        let searchField = app.textFields["저장소 검색"]
        searchField.tap()
        searchField.typeText("swift")

        // When: X 버튼 탭
        let clearButton = app.buttons["xmark.circle.fill"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 2), "클리어 버튼이 표시되어야 함")
        clearButton.tap()

        // Then: 검색어가 비어있음
        XCTAssertEqual(searchField.value as? String, "", "검색어가 클리어되어야 함")
    }

    // MARK: - Pull to Refresh Test

    /// Pull to Refresh 테스트
    func testPullToRefresh_WhenTriggered_ThenReloadsResults() throws {
        // Given: 검색 결과 화면
        performSearch(query: "swift")

        // When: Pull to Refresh 수행
        let resultList = app.collectionViews.firstMatch
        XCTAssertTrue(resultList.waitForExistence(timeout: 5))
        resultList.pullToRefresh()

        // Then: 로딩 인디케이터가 표시되었다가 사라짐
        let progressIndicator = app.progressIndicators.firstMatch
        XCTAssertTrue(progressIndicator.waitForExistence(timeout: 3))
        XCTAssertTrue(progressIndicator.waitForNonExistence(timeout: 5))
    }

    // MARK: - Empty States

    /// 빈 검색어로 검색 시 아무 일도 일어나지 않음
    func testEmptySearch_WhenQueryIsEmpty_ThenStaysOnSearchView() throws {
        // When: 빈 검색어로 검색 시도
        let searchField = app.textFields["저장소 검색"]
        searchField.tap()

        let searchButton = app.buttons["검색"]
        searchButton.tap()

        // Then: 여전히 검색 화면에 머무름
        let searchNavigation = app.navigationBars["GitHub 검색"]
        XCTAssertTrue(searchNavigation.exists, "검색 화면에 머물러 있어야 함")
    }

    /// 검색 결과 없음 표시 테스트
    func testEmptyResults_WhenNoResults_ThenShowsEmptyState() throws {
        // Given: 존재하지 않을 검색어
        performSearch(query: "xyzabc123nonexistent")

        // Then: 빈 결과 화면 표시
        let emptyStateText = app.staticTexts["검색 결과가 없습니다"]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5), "빈 결과 메시지가 표시되어야 함")
    }

    // MARK: - Helper Methods

    private func performSearch(query: String) {
        let searchField = app.textFields["저장소 검색"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText(query)

        let searchButton = app.buttons["검색"]
        searchButton.tap()
    }

    private func goBack() {
        let backButton = app.buttons["뒤로"]
        if backButton.exists {
            backButton.tap()
        } else {
            app.swipeRight()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// 요소가 존재하지 않을 때까지 대기
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    /// Pull to Refresh 수행
    func pullToRefresh() {
        let start = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
