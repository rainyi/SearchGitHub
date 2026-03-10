import Foundation

/// 최근 검색어 아이템
struct RecentSearchItem: Identifiable, Codable, Hashable {
    let id: UUID
    let query: String
    let searchedAt: Date

    init(id: UUID = UUID(), query: String, searchedAt: Date = Date()) {
        self.id = id
        self.query = query
        self.searchedAt = searchedAt
    }
}

// MARK: - Business Logic

extension RecentSearchItem {
    /// 최근 검색어 목록 정렬 (최신순)
    static func sortedByDate(_ items: [RecentSearchItem]) -> [RecentSearchItem] {
        items.sorted { $0.searchedAt > $1.searchedAt }
    }

    /// 중복 제거 후 최신 항목만 유지
    static func deduplicated(_ items: [RecentSearchItem]) -> [RecentSearchItem] {
        var uniqueQueries: Set<String> = []
        return items.filter { item in
            let query = item.query.lowercased()
            if uniqueQueries.contains(query) {
                return false
            }
            uniqueQueries.insert(query)
            return true
        }
    }

    /// 최대 개수 제한
    static func limited(_ items: [RecentSearchItem], maxCount: Int) -> [RecentSearchItem] {
        Array(items.prefix(maxCount))
    }
}

// MARK: - Preview Support

extension RecentSearchItem {
    static var sample: RecentSearchItem {
        RecentSearchItem(
            query: "swift",
            searchedAt: Date()
        )
    }

    static var samples: [RecentSearchItem] {
        [
            RecentSearchItem(query: "swift", searchedAt: Date()),
            RecentSearchItem(query: "ios", searchedAt: Date().addingTimeInterval(-3600)),
            RecentSearchItem(query: "combine", searchedAt: Date().addingTimeInterval(-7200))
        ]
    }
}
