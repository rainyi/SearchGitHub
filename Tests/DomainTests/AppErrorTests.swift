import XCTest
@testable import GitHubSearchApp

/// AppError 단위 테스트
final class AppErrorTests: XCTestCase {

    // MARK: - Error Description Tests (사용자 친화적 메시지 검증)

    func test_emptyQuery_errorDescription_shouldBeUserFriendly() {
        // Given
        let error = AppError.emptyQuery

        // Then
        XCTAssertEqual(error.errorDescription, "검색어를 입력해주세요")
    }

    func test_network_errorDescription_shouldSuggestCheckingConnection() {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let error = AppError.network(networkError)

        // Then
        XCTAssertEqual(error.errorDescription, "인터넷 연결을 확인해 주세요")
    }

    func test_rateLimit_errorDescription_shouldSuggestRetry() {
        // Given
        let resetAt = Date().addingTimeInterval(60)
        let error = AppError.rateLimit(resetAt: resetAt)

        // Then
        XCTAssertEqual(error.errorDescription, "잠시 후 다시 시도해 주세요")
    }

    func test_unauthorized_errorDescription_shouldBeUserFriendly() {
        // Given
        let error = AppError.unauthorized

        // Then
        XCTAssertEqual(error.errorDescription, "인증에 실패했습니다")
    }

    func test_forbidden_errorDescription_shouldBeUserFriendly() {
        // Given
        let error = AppError.forbidden

        // Then
        XCTAssertEqual(error.errorDescription, "접근이 거부되었습니다")
    }

    func test_emptyResult_errorDescription_shouldBeUserFriendly() {
        // Given
        let error = AppError.emptyResult

        // Then
        XCTAssertEqual(error.errorDescription, "검색 결과가 없습니다")
    }

    func test_serverError_errorDescription_shouldIncludeStatusCode() {
        // Given
        let error = AppError.serverError(500)

        // Then
        XCTAssertEqual(error.errorDescription, "서버 오류가 발생했습니다 (500)")
    }

    func test_decoding_errorDescription_shouldBeUserFriendly() {
        // Given
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        let error = AppError.decoding(decodingError)

        // Then
        XCTAssertEqual(error.errorDescription, "데이터를 불러올 수 없습니다")
    }

    func test_invalidResponse_errorDescription_shouldBeUserFriendly() {
        // Given
        let error = AppError.invalidResponse

        // Then
        XCTAssertEqual(error.errorDescription, "오류가 발생했습니다")
    }

    func test_unknown_errorDescription_shouldBeUserFriendly() {
        // Given
        let unknownError = NSError(domain: "Unknown", code: -1)
        let error = AppError.unknown(unknownError)

        // Then
        XCTAssertEqual(error.errorDescription, "오류가 발생했습니다")
    }

    // MARK: - Recovery Suggestion Tests

    func test_network_recoverySuggestion_shouldSuggestRetry() {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let error = AppError.network(networkError)

        // Then
        XCTAssertEqual(error.recoverySuggestion, "잠시 후 다시 시도해주세요")
    }

    func test_emptyResult_recoverySuggestion_shouldSuggestDifferentQuery() {
        // Given
        let error = AppError.emptyResult

        // Then
        XCTAssertEqual(error.recoverySuggestion, "다른 검색어를 입력하거나 철자를 확인해주세요")
    }

    func test_rateLimit_recoverySuggestion_shouldIncludeWaitTime() {
        // Given
        let error = AppError.rateLimit(resetAt: Date())

        // Then
        XCTAssertEqual(error.recoverySuggestion, "1분 후에 다시 시도해주세요")
    }

    // MARK: - Equatable Tests

    func test_sameErrorTypes_shouldBeEqual() {
        // Given & Then
        XCTAssertEqual(AppError.emptyQuery, AppError.emptyQuery)
        XCTAssertEqual(AppError.unauthorized, AppError.unauthorized)
        XCTAssertEqual(AppError.forbidden, AppError.forbidden)
        XCTAssertEqual(AppError.invalidResponse, AppError.invalidResponse)
        XCTAssertEqual(AppError.emptyResult, AppError.emptyResult)
    }

    func test_differentErrorTypes_shouldNotBeEqual() {
        // Given & Then
        XCTAssertNotEqual(AppError.emptyQuery, AppError.unauthorized)
        XCTAssertNotEqual(AppError.network(NSError()), AppError.serverError(500))
    }

    func test_serverError_withSameStatusCode_shouldBeEqual() {
        // Given
        let error1 = AppError.serverError(404)
        let error2 = AppError.serverError(404)

        // Then
        XCTAssertEqual(error1, error2)
    }

    func test_serverError_withDifferentStatusCode_shouldNotBeEqual() {
        // Given
        let error1 = AppError.serverError(404)
        let error2 = AppError.serverError(500)

        // Then
        XCTAssertNotEqual(error1, error2)
    }

    // MARK: - Rate Limit Tests

    func test_rateLimitRemainingSeconds_withFutureDate_shouldReturnNonNegative() {
        // Given
        let futureDate = Date().addingTimeInterval(300) // 5분 후
        let error = AppError.rateLimit(resetAt: futureDate)

        // When
        let remaining = error.rateLimitRemainingSeconds

        // Then - 0 이상이어야 함 (시간 지날 수 있음)
        XCTAssertNotNil(remaining)
        XCTAssertGreaterThanOrEqual(remaining!, 0)
    }

    func test_rateLimitRemainingSeconds_withPastDate_shouldReturnZeroOrPositive() {
        // Given
        let pastDate = Date().addingTimeInterval(-60) // 1분 전
        let error = AppError.rateLimit(resetAt: pastDate)

        // When
        let remaining = error.rateLimitRemainingSeconds

        // Then - max(0, ...) 로직으로 인해 0 또는 작은 양수
        XCTAssertNotNil(remaining)
        XCTAssertGreaterThanOrEqual(remaining!, 0)
    }

    // MARK: - Is Retryable Tests

    func test_retryableErrors_shouldReturnTrue() {
        // Given & Then
        XCTAssertTrue(AppError.network(NSError()).isRetryable)
        XCTAssertTrue(AppError.invalidResponse.isRetryable)
        XCTAssertTrue(AppError.rateLimit(resetAt: Date()).isRetryable)
        XCTAssertTrue(AppError.serverError(500).isRetryable)

        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        XCTAssertTrue(AppError.decoding(decodingError).isRetryable)

        let encodingError = EncodingError.invalidValue("", .init(codingPath: [], debugDescription: ""))
        XCTAssertTrue(AppError.encoding(encodingError).isRetryable)
    }

    func test_nonRetryableErrors_shouldReturnFalse() {
        // Given & Then
        XCTAssertFalse(AppError.emptyQuery.isRetryable)
        XCTAssertFalse(AppError.emptyResult.isRetryable)
        XCTAssertFalse(AppError.unauthorized.isRetryable)
        XCTAssertFalse(AppError.forbidden.isRetryable)
        XCTAssertFalse(AppError.invalidParameter("test").isRetryable)
        XCTAssertFalse(AppError.unknown(NSError()).isRetryable)
    }
}
