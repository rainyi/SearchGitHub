import Foundation

/// 앱 전반의 에러 타입
enum AppError: Error, Equatable {
    // MARK: - 입력 검증

    /// 빈 검색어
    case emptyQuery

    /// 잘못된 파라미터
    case invalidParameter(String)

    // MARK: - 네트워크

    /// 네트워크 연결 실패
    case network(Error)

    /// GitHub API Rate Limit (429)
    case rateLimit(resetAt: Date)

    /// 인증 실패 (401)
    case unauthorized

    /// 접근 금지 (403)
    case forbidden

    /// 잘못된 HTTP 응답
    case invalidResponse

    /// 서버 에러 (5xx)
    case serverError(Int)

    // MARK: - 데이터

    /// JSON 디코딩 실패
    case decoding(Error)

    /// 데이터 없음
    case emptyResult

    // MARK: - 기타

    /// 알 수 없는 에러
    case unknown(Error)

    // MARK: - Equatable

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyQuery, .emptyQuery):
            return true
        case (.invalidParameter, .invalidParameter):
            return true
        case let (.network(lhsError), .network(rhsError)):
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            return lhsNSError.domain == rhsNSError.domain &&
                   lhsNSError.code == rhsNSError.code
        case let (.rateLimit(lhsDate), .rateLimit(rhsDate)):
            return lhsDate == rhsDate
        case (.unauthorized, .unauthorized):
            return true
        case (.forbidden, .forbidden):
            return true
        case (.invalidResponse, .invalidResponse):
            return true
        case let (.serverError(lhsCode), .serverError(rhsCode)):
            return lhsCode == rhsCode
        case let (.decoding(lhsError), .decoding(rhsError)):
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            return lhsNSError.domain == rhsNSError.domain &&
                   lhsNSError.code == rhsNSError.code
        case (.emptyResult, .emptyResult):
            return true
        case let (.unknown(lhsError), .unknown(rhsError)):
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            return lhsNSError.domain == rhsNSError.domain &&
                   lhsNSError.code == rhsNSError.code
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "검색어를 입력해주세요"

        case .invalidParameter:
            return "잘못된 입력입니다"

        case .network:
            return "인터넷 연결을 확인해 주세요"

        case .rateLimit:
            return "잠시 후 다시 시도해 주세요"

        case .unauthorized:
            return "인증에 실패했습니다"

        case .forbidden:
            return "접근이 거부되었습니다"

        case .invalidResponse:
            return "오류가 발생했습니다"

        case .serverError(let statusCode):
            return "서버 오류가 발생했습니다 (\(statusCode))"

        case .decoding:
            return "데이터를 불러올 수 없습니다"

        case .emptyResult:
            return "검색 결과가 없습니다"

        case .unknown:
            return "오류가 발생했습니다"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyQuery:
            return "검색어를 입력하고 다시 시도해주세요"

        case .invalidParameter:
            return "입력값을 확인하고 다시 시도해주세요"

        case .network, .invalidResponse, .decoding, .unknown, .serverError:
            return "잠시 후 다시 시도해주세요"

        case .unauthorized, .forbidden:
            return "관리자에게 문의해주세요"

        case .rateLimit:
            return "1분 후에 다시 시도해주세요"

        case .emptyResult:
            return "다른 검색어를 입력하거나 철자를 확인해주세요"
        }
    }
}

// MARK: - User Info

extension AppError {
    /// Rate Limit 남은 시간 (초)
    var rateLimitRemainingSeconds: Int? {
        guard case .rateLimit(let resetAt) = self else {
            return nil
        }
        let remaining = Int(-resetAt.timeIntervalSinceNow)
        return max(0, remaining)
    }

    /// 재시도 가능 여부
    var isRetryable: Bool {
        switch self {
        case .network, .invalidResponse, .decoding, .rateLimit, .serverError:
            return true
        case .emptyQuery, .emptyResult, .unknown, .unauthorized, .forbidden:
            return false
        }
    }
}
