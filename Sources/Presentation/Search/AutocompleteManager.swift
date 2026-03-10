import Foundation

/// 자동완성 제안을 관리하는 매니저
final class AutocompleteManager {
    private var task: Task<Void, Never>?
    private let debounceInterval: UInt64
    private let minQueryLength: Int
    private let maxSuggestions: Int

    init(
        debounceInterval: UInt64 = 300_000_000, // 300ms
        minQueryLength: Int = 1,
        maxSuggestions: Int = 5
    ) {
        self.debounceInterval = debounceInterval
        self.minQueryLength = minQueryLength
        self.maxSuggestions = maxSuggestions
    }

    /// 이전 태스크 취소
    func cancel() {
        task?.cancel()
        task = nil
    }

    /// 자동완성 제안 업데이트
    /// - Parameters:
    ///   - query: 현재 입력된 검색어
    ///   - recentSearches: 최근 검색어 목록
    ///   - hasSearched: 이미 검색 결과가 표시 중인지 여부
    ///   - completion: 완료 콜백 (메인 스레드에서 호출)
    func updateSuggestions(
        query: String,
        recentSearches: [RecentSearchItem],
        hasSearched: Bool,
        completion: @escaping ([RecentSearchItem]) -> Void
    ) {
        // 이전 태스크 취소
        cancel()

        task = Task { @MainActor in
            // 디바운스 대기
            try? await Task.sleep(nanoseconds: debounceInterval)

            // 태스크 취소 확인
            guard !Task.isCancelled else { return }

            let suggestions = self.computeSuggestions(
                query: query,
                recentSearches: recentSearches,
                hasSearched: hasSearched
            )

            completion(suggestions)
        }
    }

    // MARK: - Private Methods

    private func computeSuggestions(
        query: String,
        recentSearches: [RecentSearchItem],
        hasSearched: Bool
    ) -> [RecentSearchItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // 최소 길이 체크
        guard trimmedQuery.count >= minQueryLength else {
            return []
        }

        // 이미 검색 결과가 표시 중이면 자동완성 숨김
        guard !hasSearched else {
            return []
        }

        // 최근 검색어에서 필터링
        let queryLower = trimmedQuery.lowercased()
        let filtered = recentSearches.filter { item in
            item.query.lowercased().contains(queryLower)
        }

        // 최신순으로 정렬하고 최대 개수 제한
        return Array(filtered.prefix(maxSuggestions))
    }
}
