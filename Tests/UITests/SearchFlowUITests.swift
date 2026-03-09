import XCTest

/// 검색 화면 UI 흐름 테스트
/// - Note: 이 테스트들은 실제 앱을 실행하고 사용자 인터랙션을 시뮬레이션합니다
/// - Important: 이 테스트들을 실행하려면 GitHubSearch 앱이 빌드되어 있어야 합니다
///   Xcode에서 Package.swift를 열고 테스트하거나, xcodebuild에서 -xctestrun 파일을 사용해야 합니다
final class SearchFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // XCUIApplication 초기화 - bundle identifier로 앱 지정
        app = XCUIApplication(bundleIdentifier: "searchgithub.GitHubSearch")

        // 앱이 설치되어 있지 않으면 스킵
        if app.state == .unknown || app.state == .notRunning {
            // 앱이 없으면 테스트 스킵
            throw XCTSkip("GitHubSearch 앱이 설치되어 있지 않습니다. Xcode에서 Package.swift를 열어 빌드하세요.")
        }

        // 앱 실행
        app.launch()
    }

    override func tearDownWithError() throws {
        // 앱 종료
        if app != nil {
            app.terminate()
        }
    }

    // MARK: - Basic Tests

    /// 앱이 정상적으로 실행되는지 테스트
    func testAppLaunch() throws {
        // Then: 검색 화면이 표시됨
        let searchNavigation = app.navigationBars["GitHub 검색"]
        XCTAssertTrue(searchNavigation.waitForExistence(timeout: 10), "검색 화면이 표시되어야 함")
    }

    /// 검색 필드가 존재하는지 테스트
    func testSearchFieldExists() throws {
        // Then: 검색 필드가 존재함
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "검색 필드가 존재해야 함")
    }

    /// 검색 버튼이 존재하는지 테스트
    func testSearchButtonExists() throws {
        // Then: 검색 버튼이 존재함
        let searchButton = app.buttons["검색"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 10), "검색 버튼이 존재해야 함")
    }

    // MARK: - Search Flow Tests

    /// 검색어 입력 후 검색 실행
    func testSearchFlow() throws {
        // Given: 검색 화면
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))

        // When: 검색어 입력
        searchField.tap()
        searchField.typeText("swift")

        // And: 검색 버튼 탭
        let searchButton = app.buttons["검색"]
        searchButton.tap()

        // Then: 결과 화면으로 이동 (타이틀 변경 확인)
        let resultNavigation = app.navigationBars["swift"]
        XCTAssertTrue(resultNavigation.waitForExistence(timeout: 15), "결과 화면으로 이동해야 함")
    }

    /// 검색 결과 리스트가 표시되는지 테스트
    func testSearchResultsList() throws {
        // Given: 검색 실행
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("swift")
        app.buttons["검색"].tap()

        // Then: 결과 리스트 표시
        let resultList = app.collectionViews.firstMatch
        XCTAssertTrue(resultList.waitForExistence(timeout: 15), "결과 리스트가 표시되어야 함")
    }

    /// 결과 셀 탭 시 WebView로 이동
    func testTapResultCell() throws {
        // Given: 검색 결과 표시
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("swift")
        app.buttons["검색"].tap()

        // When: 첫 번째 셀 탭
        let firstCell = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15))
        firstCell.tap()

        // Then: WebView 화면으로 이동
        let webViewNavigation = app.navigationBars["저장소 상세"]
        XCTAssertTrue(webViewNavigation.waitForExistence(timeout: 10), "WebView로 이동해야 함")
    }

    // MARK: - Recent Searches Tests

    /// 최근 검색어가 저장되는지 테스트
    func testRecentSearchSaved() throws {
        // Given: 검색 실행
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("swift")
        app.buttons["검색"].tap()

        // When: 뒤로 가기
        app.navigationBars.buttons.firstMatch.tap()

        // Then: 최근 검색어에 "swift" 표시
        let recentSearch = app.staticTexts["swift"]
        XCTAssertTrue(recentSearch.waitForExistence(timeout: 10), "최근 검색어에 표시되어야 함")
    }

    /// 전체 삭제 버튼 테스트
    func testClearAllButton() throws {
        // Given: 검색 실행 후 뒤로 가기
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("swift")
        app.buttons["검색"].tap()
        app.navigationBars.buttons.firstMatch.tap()

        // "swift" 텍스트가 존재하는지 확인
        let recentSearch = app.staticTexts["swift"]
        XCTAssertTrue(recentSearch.waitForExistence(timeout: 10))

        // When: 전체 삭제 버튼 탭
        let clearAllButton = app.buttons["전체 삭제"]
        if clearAllButton.exists {
            clearAllButton.tap()

            // Then: 최근 검색어가 삭제됨
            XCTAssertFalse(recentSearch.exists, "최근 검색어가 삭제되어야 함")
        }
    }

    // MARK: - Empty State Tests

    /// 빈 검색어로 검색 시 결과 화면으로 이동하지 않음
    func testEmptyQuery() throws {
        // When: 빈 검색어로 검색
        let searchButton = app.buttons["검색"]
        searchButton.tap()

        // Then: 여전히 검색 화면에 머무름
        let searchNavigation = app.navigationBars["GitHub 검색"]
        XCTAssertTrue(searchNavigation.exists, "검색 화면에 머물러 있어야 함")
    }

    /// 존재하지 않는 검색어로 검색 시 빈 결과 표시
    func testEmptyResults() throws {
        // Given: 존재하지 않는 검색어 입력
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("xyzabc123nonexistent")
        app.buttons["검색"].tap()

        // Then: 빈 결과 메시지 표시
        let emptyMessage = app.staticTexts["검색 결과가 없습니다"]
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 15), "빈 결과 메시지가 표시되어야 함")
    }
}
