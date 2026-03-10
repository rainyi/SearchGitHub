import XCTest
@testable import GitHubSearch

/// 이미지 캐싱 테스트
final class ImageCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 테스트용 URLCache 설정 (App의 configureURLCache와 동일)
        let cacheSizeMemory = 50 * 1024 * 1024 // 50MB
        let cacheSizeDisk = 100 * 1024 * 1024  // 100MB

        let urlCache = URLCache(
            memoryCapacity: cacheSizeMemory,
            diskCapacity: cacheSizeDisk,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )
        URLCache.shared = urlCache
    }

    override func tearDown() {
        // 테스트 후 캐시 정리
        URLCache.shared.removeAllCachedResponses()
        super.tearDown()
    }

    // MARK: - URLCache Configuration Tests

    func test_urlCacheConfiguration_shouldHaveCorrectCapacity() {
        // Given & When
        let cache = URLCache.shared

        // Then
        XCTAssertGreaterThan(cache.memoryCapacity, 0, "Memory capacity should be set")
        XCTAssertGreaterThan(cache.diskCapacity, 0, "Disk capacity should be set")
    }

    func test_urlCache_shouldStoreAndRetrieveResponse() {
        // Given
        let url = URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/png"]
        )!
        let data = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic numbers

        let cachedResponse = CachedURLResponse(response: response, data: data)

        // When
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
        let retrievedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url))

        // Then
        XCTAssertNotNil(retrievedResponse)
        XCTAssertEqual(retrievedResponse?.data, data)
    }

    func test_urlCache_shouldRespectMemoryCapacity() {
        // Given
        let cache = URLCache.shared

        // When
        let memoryCapacity = cache.memoryCapacity

        // Then - 메모리 캐시 용량이 설정되어 있어야 함 (50MB)
        XCTAssertGreaterThanOrEqual(memoryCapacity, 50 * 1024 * 1024)
    }

    func test_urlCache_shouldRespectDiskCapacity() {
        // Given
        let cache = URLCache.shared

        // When
        let diskCapacity = cache.diskCapacity

        // Then - 디스크 캐시 용량이 설정되어 있어야 함 (100MB)
        XCTAssertGreaterThanOrEqual(diskCapacity, 100 * 1024 * 1024)
    }

    func test_cachedResponse_shouldRespectCacheControlHeaders() {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "image/png",
                "Cache-Control": "max-age=3600" // 1시간 캐싱
            ]
        )!
        let data = Data([0x89, 0x50, 0x4E, 0x47])

        let cachedResponse = CachedURLResponse(response: response, data: data)

        // When
        URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))

        // Then
        let retrieved = URLCache.shared.cachedResponse(for: URLRequest(url: url))
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.response.url, url)
    }

    func test_removeAllCachedResponses_shouldClearCache() {
        // Given
        let url = URL(string: "https://example.com/image.png")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/png"]
        )!
        let data = Data([0x89, 0x50, 0x4E, 0x47])

        URLCache.shared.storeCachedResponse(
            CachedURLResponse(response: response, data: data),
            for: URLRequest(url: url)
        )

        // When
        URLCache.shared.removeAllCachedResponses()

        // Then
        let retrieved = URLCache.shared.cachedResponse(for: URLRequest(url: url))
        XCTAssertNil(retrieved)
    }
}
