import SwiftUI

struct ResultListView: View {

    @StateObject private var viewModel: ResultListViewModel

    init(viewModel: ResultListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .navigationTitle(viewModel.query)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.back()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("뒤로")
                }
            }
        }
        #endif
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("총 \(viewModel.totalCount)개 결과")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.repositories.isEmpty {
            loadingView
        } else if viewModel.shouldShowError {
            errorView
        } else if viewModel.shouldShowEmptyState {
            emptyView
        } else {
            repositoryList
        }
    }

    private var repositoryList: some View {
        List {
            ForEach(viewModel.repositories) { repository in
                RepositoryListCell(repository: repository)
                    .onAppear {
                        if repository.id == viewModel.repositories.last?.id {
                            Task {
                                await viewModel.loadNextPage()
                            }
                        }
                    }
                    .onTapGesture {
                        viewModel.selectRepository(repository)
                    }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var loadingView: some View {
        LoadingView(message: "검색 중...")
    }

    private var errorView: some View {
        ErrorView(
            message: viewModel.error?.localizedDescription ?? "오류가 발생했습니다",
            retryAction: {
                Task {
                    await viewModel.loadFirstPage()
                }
            }
        )
    }

    private var emptyView: some View {
        EmptyView(
            icon: "magnifyingglass",
            title: "검색 결과가 없습니다",
            subtitle: "다른 검색어를 입력해보세요"
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResultListView(
            viewModel: ResultListViewModel(
                query: "swift",
                searchUseCase: MockSearchUseCaseForPreview(),
                router: AppRouter()
            )
        )
    }
}

// MARK: - Preview Mocks

private struct MockSearchUseCaseForPreview: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        let repositories = [
            GitHubRepository.sample,
            GitHubRepository(
                id: 2,
                name: "swiftui",
                fullName: "apple/swiftui",
                owner: RepositoryOwner(
                    login: "apple",
                    avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/10639145?v=4")!
                ),
                htmlUrl: URL(string: "https://github.com/apple/swiftui")!,
                description: "SwiftUI framework",
                stargazersCount: 5000,
                language: "Swift",
                updatedAt: Date()
            )
        ]
        return SearchResult(
            repositories: repositories,
            totalCount: 2,
            hasNextPage: false
        )
    }
}
