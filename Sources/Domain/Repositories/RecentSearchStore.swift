import Foundation

/// 최근 검색어 저장소 인터페이스
protocol RecentSearchStore {
    /// 최근 검색어 목록 로드
    func load() async throws -> [RecentSearchItem]

    /// 최근 검색어 저장
    /// - Note: 중복 제거 및 최대 개수 제한은 UseCase에서 처리
    func save(_ items: [RecentSearchItem]) async throws

    /// 특정 검색어 삭제
    func delete(id: UUID) async throws

    /// 전체 삭제
    func clear() async throws
}
