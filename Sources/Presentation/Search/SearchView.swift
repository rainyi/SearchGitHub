import SwiftUI

struct SearchView: View {

    @StateObject private var viewModel: SearchViewModel
    @FocusState private var isSearchFieldFocused: Bool

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            autocompleteList
            content
        }
        .navigationTitle("Search")
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 12) {
            // 회색 검색바 (텍스트 입력 시 줄어듦)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 17))

                TextField("저장소 검색", text: $viewModel.searchQuery)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .accessibilityIdentifier("searchTextField")
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }

                if !viewModel.searchQuery.isEmpty {
                    // X 버튼 - 텍스트 초기화
                    Button {
                        viewModel.searchQuery = ""
                        if viewModel.hasSearched {
                            viewModel.clearSearch()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 20))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)

            // 취소 버튼 - 검색바 바깥 (텍스트 입력 시 나타남)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.clearSearch()
                    isSearchFieldFocused = false
                } label: {
                    Text("취소")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var autocompleteList: some View {
        Group {
            if !viewModel.autocompleteSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("추천 검색어")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    ForEach(viewModel.autocompleteSuggestions) { item in
                        Button {
                            viewModel.selectRecentSearch(item)
                            isSearchFieldFocused = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.query)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(formattedDate(item.searchedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.white)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 40)
                    }
                }
                .background(Color.gray.opacity(0.05))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.shouldShowResults {
            searchResultsView
        } else if viewModel.recentSearches.isEmpty {
            emptyState
        } else {
            recentSearchesList
        }
    }

    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // 결과 개수 헤더
            HStack {
                Text("총 \(viewModel.totalCount)개 결과")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if viewModel.isSearching && viewModel.repositories.isEmpty {
                // 로딩 상태
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            } else if viewModel.shouldShowError {
                // 에러 상태
                Spacer()
                ErrorView(
                    message: viewModel.error?.localizedDescription ?? "오류가 발생했습니다",
                    retryAction: {
                        Task {
                            await viewModel.search()
                        }
                    }
                )
                Spacer()
            } else if viewModel.shouldShowEmptyState {
                // 빈 결과 상태
                Spacer()
                EmptyView(
                    icon: "magnifyingglass",
                    title: "검색 결과가 없습니다",
                    subtitle: "다른 검색어를 입력핵보세요"
                )
                Spacer()
            } else {
                // 검색 결과 리스트
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.repositories.enumerated()), id: \.element.id) { index, repository in
                            RepositoryListCell(repository: repository)
                                .onAppear {
                                    // 마지막 3개 아이템 중 하나가 보이면 다음 페이지 로드
                                    let thresholdIndex = viewModel.repositories.count - 3
                                    if index >= thresholdIndex {
                                        Task {
                                            await viewModel.loadNextPage()
                                        }
                                    }
                                }
                                .onTapGesture {
                                    viewModel.selectRepository(repository)
                                }

                            Divider()
                                .padding(.leading)
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyView(
            icon: "magnifyingglass",
            title: "검색어를 입력해주세요"
        )
    }

    private var recentSearchesList: some View {
        List {
            Section(header: Text("최근 검색")) {
                ForEach(viewModel.recentSearches) { item in
                    HStack(spacing: 0) {
                        // 검색어 영역 - 탭하면 검색
                        Button {
                            viewModel.selectRecentSearch(item)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.query)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(formattedDate(item.searchedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        // X 버튼 - 탭하면 삭제
                        Button {
                            Task {
                                await viewModel.deleteRecentSearch(id: item.id)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }
                }

                // 전체 삭제 버튼 - 마지막 검색어 바로 아래
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await viewModel.clearAllRecentSearches()
                        }
                    } label: {
                        Text("전체 삭제")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helpers

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("검색 전") {
    NavigationStack {
        SearchView(
            viewModel: SearchViewModel(
                searchUseCase: MockSearchRepositoriesUseCase(),
                recentSearchUseCase: MockRecentSearchUseCasePreview(),
                router: AppRouter()
            )
        )
    }
}

#Preview("검색 중 - 텍스트 입력") {
    NavigationStack {
        SearchView(
            viewModel: createSearchViewModelWithText()
        )
    }
}

#Preview("검색 결과") {
    NavigationStack {
        SearchView(
            viewModel: createSearchViewModelWithResults()
        )
    }
}

// MARK: - Preview Helpers

@MainActor
private func createSearchViewModelWithText() -> SearchViewModel {
    let viewModel = SearchViewModel(
        searchUseCase: MockSearchRepositoriesUseCase(),
        recentSearchUseCase: MockRecentSearchUseCasePreview(),
        router: AppRouter()
    )
    viewModel.searchQuery = "swift"
    return viewModel
}

@MainActor
private func createSearchViewModelWithResults() -> SearchViewModel {
    let viewModel = SearchViewModel(
        searchUseCase: MockSearchRepositoriesUseCaseWithResults(),
        recentSearchUseCase: MockRecentSearchUseCasePreview(),
        router: AppRouter()
    )
    viewModel.searchQuery = "swift"
    viewModel.hasSearched = true
    viewModel.totalCount = 100
    viewModel.hasNextPage = true
    viewModel.repositories = (1...10).map { index in
        GitHubRepository(
            id: index,
            name: "repo-\(index)",
            fullName: "user/repo-\(index)",
            owner: RepositoryOwner(
                login: "user",
                avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!
            ),
            htmlUrl: URL(string: "https://github.com/user/repo-\(index)")!,
            description: "Repository \(index)",
            stargazersCount: 100 + index,
            language: "Swift",
            updatedAt: Date()
        )
    }
    return viewModel
}

// MARK: - Preview Mocks

private struct MockSearchRepositoriesUseCase: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        SearchResult(repositories: [], totalCount: 0, hasNextPage: false)
    }
}

private struct MockSearchRepositoriesUseCaseWithResults: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        // 페이지별로 다른 결과 반환하여 페이지네이션 테스트 가능
        let baseId = (page - 1) * 10
        let repositories = (1...10).map { index in
            GitHubRepository(
                id: baseId + index,
                name: "repo-\(baseId + index)",
                fullName: "user/repo-\(baseId + index)",
                owner: RepositoryOwner(
                    login: "user",
                    avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!
                ),
                htmlUrl: URL(string: "https://github.com/user/repo-\(baseId + index)")!,
                description: "Repository \(baseId + index)",
                stargazersCount: 100 + baseId + index,
                language: "Swift",
                updatedAt: Date()
            )
        }
        return SearchResult(
            repositories: repositories,
            totalCount: 100,
            hasNextPage: page < 10
        )
    }
}

private actor MockRecentSearchUseCasePreview: RecentSearchUseCase {
    func getRecentSearches() async throws -> [RecentSearchItem] {
        return [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date().addingTimeInterval(-3600)),
            RecentSearchItem(query: "combine", searchedAt: Date().addingTimeInterval(-7200))
        ]
    }

    func addSearch(query: String) async throws {}
    func deleteSearch(id: UUID) async throws {}
    func clearAll() async throws {}
}
