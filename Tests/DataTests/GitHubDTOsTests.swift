import XCTest
@testable import GitHubSearch

/// GitHub DTOs 단위 테스트
final class GitHubDTOsTests: XCTestCase {

    // MARK: - toEntity Tests

    func testToEntity_WhenValidDTO_ThenReturnsEntity() {
        // Given
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: "The Swift Programming Language",
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 65000,
            language: "Swift",
            forksCount: 10000,
            updatedAt: nil
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNotNil(entity)
        XCTAssertEqual(entity?.id, 1)
        XCTAssertEqual(entity?.name, "swift")
        XCTAssertEqual(entity?.fullName, "apple/swift")
        XCTAssertEqual(entity?.owner.login, "apple")
        XCTAssertEqual(entity?.stargazersCount, 65000)
        XCTAssertEqual(entity?.language, "Swift")
        XCTAssertNil(entity?.updatedAt)
    }

    func testToEntity_WhenInvalidHtmlUrl_ThenReturnsNil() {
        // Given
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: nil,
            htmlUrl: "not a valid url",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: nil
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNil(entity)
    }

    func testToEntity_WhenInvalidAvatarUrl_ThenReturnsNil() {
        // Given
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "not a valid url"),
            description: nil,
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: nil
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNil(entity)
    }

    // MARK: - ISO8601 Date Parsing Tests

    func testToEntity_WhenUpdatedAtWithFractionalSeconds_ThenParsesDate() {
        // Given
        let dateString = "2024-03-10T15:30:45.123Z"
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: nil,
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: dateString
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNotNil(entity)
        XCTAssertNotNil(entity?.updatedAt)

        // Verify the date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entity!.updatedAt!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 45)
    }

    func testToEntity_WhenUpdatedAtWithoutFractionalSeconds_ThenParsesDate() {
        // Given
        let dateString = "2024-03-10T15:30:45Z"
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: nil,
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: dateString
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNotNil(entity)
        XCTAssertNotNil(entity?.updatedAt)

        // Verify the date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entity!.updatedAt!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 15)
        XCTAssertEqual(components.minute, 30)
        XCTAssertEqual(components.second, 45)
    }

    func testToEntity_WhenUpdatedAtIsInvalid_ThenReturnsNilDate() {
        // Given
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: nil,
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: "not a valid date"
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNotNil(entity)
        XCTAssertNil(entity?.updatedAt)
    }

    func testToEntity_WhenUpdatedAtIsNil_ThenReturnsNilDate() {
        // Given
        let dto = GitHubRepositoryDTO(
            id: 1,
            name: "swift",
            fullName: "apple/swift",
            owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
            description: nil,
            htmlUrl: "https://github.com/apple/swift",
            stargazersCount: 0,
            language: nil,
            forksCount: 0,
            updatedAt: nil
        )

        // When
        let entity = dto.toEntity()

        // Then
        XCTAssertNotNil(entity)
        XCTAssertNil(entity?.updatedAt)
    }

    // MARK: - toEntities Tests

    func testToEntities_WhenMultipleItems_ThenReturnsAllEntities() {
        // Given
        let response = GitHubSearchResponseDTO(
            totalCount: 2,
            incompleteResults: false,
            items: [
                GitHubRepositoryDTO(
                    id: 1,
                    name: "swift",
                    fullName: "apple/swift",
                    owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
                    description: "Swift language",
                    htmlUrl: "https://github.com/apple/swift",
                    stargazersCount: 100,
                    language: "Swift",
                    forksCount: 10,
                    updatedAt: "2024-03-10T10:00:00Z"
                ),
                GitHubRepositoryDTO(
                    id: 2,
                    name: "kotlin",
                    fullName: "jetbrains/kotlin",
                    owner: GitHubOwnerDTO(login: "jetbrains", avatarUrl: "https://avatars.githubusercontent.com/u/2?v=4"),
                    description: "Kotlin language",
                    htmlUrl: "https://github.com/jetbrains/kotlin",
                    stargazersCount: 200,
                    language: "Kotlin",
                    forksCount: 20,
                    updatedAt: "2024-03-11T11:00:00.000Z"
                )
            ]
        )

        // When
        let entities = response.toEntities()

        // Then
        XCTAssertEqual(entities.count, 2)
        XCTAssertEqual(entities[0].name, "swift")
        XCTAssertEqual(entities[1].name, "kotlin")
        XCTAssertNotNil(entities[0].updatedAt)
        XCTAssertNotNil(entities[1].updatedAt)
    }

    func testToEntities_WhenSomeItemsInvalid_ThenReturnsValidEntitiesOnly() {
        // Given
        let response = GitHubSearchResponseDTO(
            totalCount: 2,
            incompleteResults: false,
            items: [
                GitHubRepositoryDTO(
                    id: 1,
                    name: "swift",
                    fullName: "apple/swift",
                    owner: GitHubOwnerDTO(login: "apple", avatarUrl: "https://avatars.githubusercontent.com/u/1?v=4"),
                    description: nil,
                    htmlUrl: "https://github.com/apple/swift",
                    stargazersCount: 100,
                    language: nil,
                    forksCount: 0,
                    updatedAt: nil
                ),
                GitHubRepositoryDTO(
                    id: 2,
                    name: "invalid",
                    fullName: "user/invalid",
                    owner: GitHubOwnerDTO(login: "user", avatarUrl: "not valid"),
                    description: nil,
                    htmlUrl: "https://github.com/user/invalid",
                    stargazersCount: 0,
                    language: nil,
                    forksCount: 0,
                    updatedAt: nil
                )
            ]
        )

        // When
        let entities = response.toEntities()

        // Then
        XCTAssertEqual(entities.count, 1)
        XCTAssertEqual(entities[0].name, "swift")
    }

    func testToEntities_WhenEmptyItems_ThenReturnsEmptyArray() {
        // Given
        let response = GitHubSearchResponseDTO(
            totalCount: 0,
            incompleteResults: false,
            items: []
        )

        // When
        let entities = response.toEntities()

        // Then
        XCTAssertTrue(entities.isEmpty)
    }
}
