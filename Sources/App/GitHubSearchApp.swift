import SwiftUI

@main
struct GitHubSearchApp: App {
    @StateObject private var router = AppRouter()
    private let environment = AppEnvironment.shared

    init() {
        configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                SearchView(
                    viewModel: SearchViewModel(
                        searchUseCase: environment.searchUseCase,
                        recentSearchUseCase: environment.recentSearchUseCase,
                        router: router
                    )
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .repositoryDetail(let url):
                        RepositoryWebView(url: url)
                    }
                }
            }
            .environmentObject(router)
        }
    }

    private func configureURLCache() {
        // 이미지 캐싱을 위한 URLCache 설정
        // 메모리: 50MB, 디스크: 100MB
        let cacheSizeMemory = 50 * 1024 * 1024 // 50MB
        let cacheSizeDisk = 100 * 1024 * 1024  // 100MB

        let urlCache = URLCache(
            memoryCapacity: cacheSizeMemory,
            diskCapacity: cacheSizeDisk,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )

        URLCache.shared = urlCache
    }
}
