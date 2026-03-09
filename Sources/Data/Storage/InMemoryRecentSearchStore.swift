import Foundation

/// 메모리 기반 최근 검색어 저장소 (테스트용)
actor InMemoryRecentSearchStore: RecentSearchStore {

    // MARK: - Properties

    private var items: [RecentSearchItem] = []

    // MARK: - Initialization

    init(initialItems: [RecentSearchItem] = []) {
        self.items = initialItems
    }

    // MARK: - RecentSearchStore

    func load() async throws -> [RecentSearchItem] {
        return items
    }

    func save(_ items: [RecentSearchItem]) async throws {
        self.items = items
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func clear() async throws {
        items.removeAll()
    }

    // MARK: - Test Helpers

    /// 현재 저장된 아이템 수
    var count: Int { items.count }

    /// 특정 검색어가 존재하는지 확인
    func contains(query: String) -> Bool {
        items.contains { $0.query.lowercased() == query.lowercased() }
    }

    /// 특정 ID의 아이템 조회
    func item(id: UUID) -> RecentSearchItem? {
        items.first { $0.id == id }
    }
}
