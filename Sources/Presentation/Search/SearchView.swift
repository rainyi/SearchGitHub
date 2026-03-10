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

                                Text(item.query)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(formattedDate(item.searchedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                    subtitle: "다른 검색어를 입력해보세요"
                )
                Spacer()
            } else {
                // 검색 결과 리스트
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.repositories.enumerated()), id: \.element.id) { index, repository in
                            VStack(spacing: 0) {
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
                                    .padding(.horizontal)

                                Divider()
                                    .padding(.horizontal)
                            }
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
            Section(header:
                HStack(spacing: 0) {
                    Text("최근 검색")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .textCase(nil)
                .listRowInsets(EdgeInsets())
            ) {
                ForEach(viewModel.recentSearches) { item in
                    HStack(spacing: 0) {
                        // 검색어 + X 버튼을 하나의 HStack으로 묶음
                        HStack(spacing: 8) {
                            // 검색어 영역 - 탭하면 검색
                            Button {
                                viewModel.selectRecentSearch(item)
                            } label: {
                                Text(item.query)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)

                            // X 버튼 - 탭하면 삭제 (동그라미 안에 X)
                            Button {
                                Task {
                                    await viewModel.deleteRecentSearch(id: item.id)
                                }
                            } label: {
                                ZStack {
                                    // 배경 (회색 원)
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray.opacity(0.3))
                                    // X (검정색)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                // 전체 삭제 버튼과 경계선
                VStack(spacing: 0) {
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
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helpers

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        // 24시간 이내인지 확인
        if let hoursAgo = calendar.dateComponents([.hour], from: date, to: now).hour, hoursAgo < 24 {
            return Self.relativeFormatter.localizedString(for: date, relativeTo: now)
        } else {
            return Self.dateFormatter.string(from: date)
        }
    }
}
