import Foundation

/// GitHub 저장소 엔티티
struct GitHubRepository: Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let owner: RepositoryOwner
    let htmlUrl: URL
    let description: String?
    let stargazersCount: Int
    let language: String?
    let updatedAt: Date?
}

/// 저장소 소유자 정보
struct RepositoryOwner: Hashable {
    let login: String
    let avatarUrl: URL
}

// MARK: - Preview Support

extension GitHubRepository {
    static var sample: GitHubRepository {
        GitHubRepository(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: RepositoryOwner(
                login: "apple",
                avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/10639145?v=4")!
            ),
            htmlUrl: URL(string: "https://github.com/apple/swift")!,
            description: "The Swift Programming Language",
            stargazersCount: 65000,
            language: "Swift",
            updatedAt: Date()
        )
    }
}
