import Foundation

// MARK: - API Client Protocol

protocol GitHubAPIClient: Sendable {
    /// GitHub 저장소 검색
    /// - Parameters:
    ///   - query: 검색어
    ///   - page: 페이지 번호 (1부터 시작)
    /// - Returns: 검색 결과 (저장소 배열 + 총 개수)
    /// - Throws: AppError
    func searchRepositories(query: String, page: Int) async throws -> (repositories: [GitHubRepository], totalCount: Int)
}

// MARK: - Implementation

/// GitHub API 클라이언트 기본 구현
final class DefaultGitHubAPIClient: GitHubAPIClient {

    // MARK: - Properties

    private let session: URLSession
    private let baseURL: URL
    private let timeoutInterval: TimeInterval = 30
    private let defaultPerPage = 30
    private let decoder: JSONDecoder

    // MARK: - Constants

    /// GitHub API base URL - guaranteed valid constant
    private static let gitHubBaseURLString = "https://api.github.com"

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
        // Force unwrap is safe here because the URL string is a compile-time constant
        self.baseURL = URL(string: Self.gitHubBaseURLString)!
        self.decoder = JSONDecoder()
    }

    // MARK: - Search

    func searchRepositories(query: String, page: Int) async throws -> (repositories: [GitHubRepository], totalCount: Int) {
        let request = try buildSearchRequest(query: query, page: page)

        let data: Data
        let response: HTTPURLResponse

        do {
            let result = try await session.data(for: request)
            data = result.0

            guard let httpResponse = result.1 as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }
            response = httpResponse
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(error)
        }

        try handleHTTPStatus(response: response)

        return try parseSearchResponse(data: data)
    }

    // MARK: - Private Helpers

    /// 검색 요청 구성
    private func buildSearchRequest(query: String, page: Int) throws -> URLRequest {
        let searchURL = baseURL.appendingPathComponent("search/repositories")
        var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)

        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(defaultPerPage))
        ]

        guard let url = components?.url else {
            throw AppError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        return request
    }

    /// HTTP 상태 코드에 따른 에러 처리
    private func handleHTTPStatus(response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return

        case 401:
            throw AppError.unauthorized

        case 403:
            if let resetAt = parseRateLimitReset(from: response) {
                throw AppError.rateLimit(resetAt: resetAt)
            }
            throw AppError.forbidden

        case 429:
            let resetAt = parseRateLimitReset(from: response)
                ?? Date().addingTimeInterval(60)
            throw AppError.rateLimit(resetAt: resetAt)

        case 500...599:
            throw AppError.serverError(response.statusCode)

        default:
            throw AppError.invalidResponse
        }
    }

    /// Rate Limit 해제 시간 파싱
    private func parseRateLimitReset(from response: HTTPURLResponse) -> Date? {
        guard let resetString = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
              let resetTimestamp = TimeInterval(resetString) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimestamp)
    }

    /// 검색 응답 파싱
    private func parseSearchResponse(data: Data) throws -> (repositories: [GitHubRepository], totalCount: Int) {
        do {
            let searchResponse = try decoder.decode(GitHubSearchResponseDTO.self, from: data)
            return (repositories: searchResponse.toEntities(), totalCount: searchResponse.totalCount)
        } catch {
            throw AppError.decoding(error)
        }
    }
}
