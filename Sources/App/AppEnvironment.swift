import Foundation

/// 앱의 의존성 주입을 관리하는 Environment
@MainActor
final class AppEnvironment: ObservableObject {

    // MARK: - Router

    let router = AppRouter()

    // MARK: - UseCases

    lazy var searchUseCase: SearchRepositoriesUseCase = {
        DefaultSearchRepositoriesUseCase(repository: gitHubRepositoryRepository)
    }()

    lazy var recentSearchUseCase: RecentSearchUseCase = {
        DefaultRecentSearchUseCase(store: recentSearchStore)
    }()

    // MARK: - Repositories

    private lazy var gitHubRepositoryRepository: GitHubRepositoryRepository = {
        GitHubRepositoryRepositoryImpl(apiClient: gitHubAPIClient)
    }()

    // MARK: - Stores

    private lazy var recentSearchStore: RecentSearchStore = {
        UserDefaultsRecentSearchStore()
    }()

    // MARK: - API Clients

    private lazy var gitHubAPIClient: GitHubAPIClient = {
        DefaultGitHubAPIClient()
    }()

    // MARK: - Singleton

    static let shared = AppEnvironment()

    private init() {}
}
