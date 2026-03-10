import SwiftUI

@main
struct GitHubSearchApp: App {
    @StateObject private var router = AppRouter()
    private let environment = AppEnvironment.shared

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
                    case .resultList(let query):
                        ResultListView(
                            viewModel: ResultListViewModel(
                                query: query,
                                searchUseCase: environment.searchUseCase,
                                router: router
                            )
                        )
                    case .repositoryDetail(let url):
                        RepositoryWebView(url: url)
                    }
                }
            }
            .environmentObject(router)
        }
    }
}
