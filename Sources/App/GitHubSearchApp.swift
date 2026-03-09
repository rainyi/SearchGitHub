import SwiftUI

@main
struct GitHubSearchApp: App {

    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                SearchView(
                    viewModel: SearchViewModel(
                        searchUseCase: AppEnvironment.shared.searchUseCase,
                        recentSearchUseCase: AppEnvironment.shared.recentSearchUseCase,
                        router: router
                    )
                )
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
            }
            .environmentObject(router)
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .resultList(let query):
            ResultListView(
                viewModel: ResultListViewModel(
                    query: query,
                    searchUseCase: AppEnvironment.shared.searchUseCase,
                    router: router
                )
            )

        case .repositoryDetail(let url):
            RepositoryWebView(url: url)
        }
    }
}
