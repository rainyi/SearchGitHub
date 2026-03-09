import Foundation

/// UserDefaults 기반 최근 검색어 저장소
actor UserDefaultsRecentSearchStore: RecentSearchStore {

    // MARK: - Constants

    private enum Constants {
        static let storageKey = "recent_search_items"
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - RecentSearchStore

    func load() async throws -> [RecentSearchItem] {
        guard let data = userDefaults.data(forKey: Constants.storageKey) else {
            return []
        }

        do {
            let items = try decoder.decode([RecentSearchItem].self, from: data)
            return items
        } catch {
            throw AppError.decoding(error)
        }
    }

    func save(_ items: [RecentSearchItem]) async throws {
        do {
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: Constants.storageKey)
        } catch {
            throw AppError.decoding(error)
        }
    }

    func delete(id: UUID) async throws {
        var items = try await load()
        items.removeAll { $0.id == id }
        try await save(items)
    }

    func clear() async throws {
        userDefaults.removeObject(forKey: Constants.storageKey)
    }
}
