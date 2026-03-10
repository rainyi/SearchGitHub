import Foundation

/// 최근 검색어 UseCase 프로토콜
@MainActor
protocol RecentSearchUseCase {
    /// 최근 검색어 목록 조회
    func getRecentSearches() async throws -> [RecentSearchItem]

    /// 검색어 추가
    /// - Note: 중복 제거 후 최신순으로 정렬, 최대 10개 유지
    func addSearch(query: String) async throws

    /// 특정 검색어 삭제
    func deleteSearch(id: UUID) async throws

    /// 전체 삭제
    func clearAll() async throws
}

// MARK: - Default Implementation

@MainActor
final class DefaultRecentSearchUseCase: RecentSearchUseCase {
    private let store: RecentSearchStore
    private let maxCount: Int

    init(store: RecentSearchStore, maxCount: Int = 10) {
        self.store = store
        self.maxCount = maxCount
    }

    func getRecentSearches() async throws -> [RecentSearchItem] {
        let items = try await store.load()
        return RecentSearchItem.sortedByDate(items)
    }

    func addSearch(query: String) async throws {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        var items = try await store.load()

        // 동일 검색어 제거 후 맨 앞에 추가
        let lowercasedQuery = trimmedQuery.lowercased()
        items.removeAll { $0.query.lowercased() == lowercasedQuery }

        let newItem = RecentSearchItem(query: trimmedQuery)
        items.insert(newItem, at: 0)

        // 최대 개수 제한
        items = RecentSearchItem.limited(items, maxCount: maxCount)

        try await store.save(items)
    }

    func deleteSearch(id: UUID) async throws {
        var items = try await store.load()
        items.removeAll { $0.id == id }
        try await store.save(items)
    }

    func clearAll() async throws {
        try await store.clear()
    }
}
