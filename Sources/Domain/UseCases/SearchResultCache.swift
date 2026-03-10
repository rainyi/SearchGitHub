import Foundation

/// 검색 결과 캐시 엔트리
final class CacheEntry {
    let result: SearchResult
    let timestamp: Date

    init(result: SearchResult, timestamp: Date = Date()) {
        self.result = result
        self.timestamp = timestamp
    }
}

/// 검색 결과 메모리 캐시 매니저
@MainActor
final class SearchResultCache {
    static let shared = SearchResultCache()

    private let cache = NSCache<NSString, CacheEntry>()
    private let expirationInterval: TimeInterval = 300 // 5분

    private init() {
        // 메모리 경고 시 캐시 비우기
        cache.countLimit = 50 // 최대 50개 항목
    }

    /// 캐시에서 검색 결과 조회
    func get(keyword: String, page: Int) -> SearchResult? {
        let key = makeKey(keyword: keyword, page: page)
        guard let entry = cache.object(forKey: key) else {
            return nil
        }

        // 캐시 만료 확인
        if Date().timeIntervalSince(entry.timestamp) > expirationInterval {
            cache.removeObject(forKey: key)
            return nil
        }

        return entry.result
    }

    /// 검색 결과를 캐시에 저장
    func set(keyword: String, page: Int, result: SearchResult) {
        let key = makeKey(keyword: keyword, page: page)
        let entry = CacheEntry(result: result)
        cache.setObject(entry, forKey: key)
    }

    /// 특정 키워드의 모든 페이지 캐시 삭제
    func invalidate(keyword: String) {
        // NSCache는 전체 순회가 어려워서 개별 키로만 삭제 가능
        // 새로운 검색 시 첫 페이지만 삭제 (나머지는 자연 만료 대기)
        let key = makeKey(keyword: keyword, page: 1)
        cache.removeObject(forKey: key)
    }

    /// 전체 캐시 비우기
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - Private Methods

    private func makeKey(keyword: String, page: Int) -> NSString {
        return "\(keyword)_\(page)" as NSString
    }
}
