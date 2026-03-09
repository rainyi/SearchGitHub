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
            content
        }
        .navigationTitle("GitHub 검색")
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("저장소 검색", text: $viewModel.searchQuery)
                .focused($isSearchFieldFocused)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.search()
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("검색")
                }
            }
            .disabled(!viewModel.isSearchButtonEnabled)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.recentSearches.isEmpty {
            emptyState
        } else {
            recentSearchesList
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
            Section {
                ForEach(viewModel.recentSearches) { item in
                    Button {
                        viewModel.selectRecentSearch(item)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.query)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text(formattedDate(item.searchedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            guard viewModel.recentSearches.indices.contains(index) else { continue }
                            let item = viewModel.recentSearches[index]
                            await viewModel.deleteRecentSearch(id: item.id)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("최근 검색")
                    Spacer()
                    Button {
                        Task {
                            await viewModel.clearAllRecentSearches()
                        }
                    } label: {
                        Text("전체 삭제")
                            .font(.caption)
                    }
                }
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

#Preview {
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

// MARK: - Preview Mocks

private struct MockSearchRepositoriesUseCase: SearchRepositoriesUseCase {
    func execute(keyword: String, page: Int) async throws -> SearchResult {
        SearchResult(repositories: [], totalCount: 0, hasNextPage: false)
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
