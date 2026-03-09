import Foundation

// MARK: - GitHub API Response DTOs

/// GitHub Search API 응답의 최상위 구조체
struct GitHubSearchResponseDTO: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubRepositoryDTO]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}

/// GitHub 저장소 정보 DTO
struct GitHubRepositoryDTO: Decodable {
    let id: Int
    let name: String
    let fullName: String
    let owner: GitHubOwnerDTO
    let description: String?
    let htmlUrl: String
    let stargazersCount: Int
    let language: String?
    let forksCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, owner, description, language
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
    }
}

/// 저장소 소유자 정보 DTO
struct GitHubOwnerDTO: Decodable {
    let login: String
    let avatarUrl: String

    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Mapping to Domain Entities

extension GitHubRepositoryDTO {
    /// DTO를 Domain Entity로 변환
    func toEntity() -> GitHubRepository? {
        guard let htmlURL = URL(string: htmlUrl),
              let avatarURL = URL(string: owner.avatarUrl) else {
            return nil
        }

        return GitHubRepository(
            id: id,
            name: name,
            fullName: fullName,
            owner: RepositoryOwner(
                login: owner.login,
                avatarUrl: avatarURL
            ),
            htmlUrl: htmlURL,
            description: description,
            stargazersCount: stargazersCount,
            language: language,
            updatedAt: nil
        )
    }
}

extension GitHubSearchResponseDTO {
    /// 검색 응답 DTO를 Domain Entity 배열로 변환
    func toEntities() -> [GitHubRepository] {
        return items.compactMap { $0.toEntity() }
    }
}
