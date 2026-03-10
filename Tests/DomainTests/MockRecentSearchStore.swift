import Foundation
@testable import GitHubSearchApp

/// 테스트용 InMemory RecentSearchStore
@MainActor
final class MockRecentSearchStore: RecentSearchStore {
    private var items: [RecentSearchItem] = []
    var shouldThrowError: Error?

    func load() async throws -> [RecentSearchItem] {
        if let error = shouldThrowError {
            throw error
        }
        return items
    }

    func save(_ items: [RecentSearchItem]) async throws {
        if let error = shouldThrowError {
            throw error
        }
        self.items = items
    }

    func delete(id: UUID) async throws {
        if let error = shouldThrowError {
            throw error
        }
        items.removeAll { $0.id == id }
    }

    func clear() async throws {
        if let error = shouldThrowError {
            throw error
        }
        items.removeAll()
    }

    // 테스트 헬퍼
    func setItems(_ items: [RecentSearchItem]) {
        self.items = items
    }
}
