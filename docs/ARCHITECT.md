# ARCHITECT – GitHubSearch iOS

이 문서는 아키텍처 설계/결정 사항을 정리하는 용도입니다.
Claude에게 "지금은 Architect 역할"이라고 말할 때 이 문서를 함께 보여줍니다.

---

## 1. 설계 목표

- 간결하지만 확장 가능한 구조 (프로젝트 규모에 맞는 Clean Architecture)
- Presentation / Domain / Data 레이어 분리
- 테스트 가능한 구조 (UseCase/Store/Repository를 프로토콜로 추상화)
- 프로젝트 규모에 적합한 수준의 추상화 (과도한 설계 지양)
- Router 패턴으로 네비게이션 로직 분리 (단순화된 구현)

---

## 2. 핵심 설계 결정

### 2.1 기술 스택

| 영역 | 선택 | 이유 |
|:---|:---|:---|
| UI 프레임워크 | SwiftUI | iOS 17+ 타겟 |
| 아키텍처 | MVVM + Clean Architecture + Router | 테스트 용이성 |
| 네비게이션 | NavigationStack + AppRouter | Router로 책임 분리, 단순화된 구현 |
| 비동기 처리 | async/await | Swift Concurrency 표준 |
| 이미지 로딩 | AsyncImage | iOS 15+ 기본 제공, 3rd-party 불필요 |
| 네트워크 | URLSession | 1개 API endpoint, Alamofire 과함 |
| 데이터 저장 | UserDefaults (JSON) | 최근 검색어 10개 저장에 적합 |

### 2.2 Router 패턴 (단순화된 구현)

**결정:** Router 패턴 사용하되, **단순화된 구현**으로 제한

**구현 범위:**
```swift
// AppRoute.swift - 단순 enum
enum AppRoute: Hashable {
    case repositoryDetail(url: URL)
    // resultList 제거 - SearchView에 통합됨
}

// AppRouter.swift - NavigationPath 관리만
@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    // showResults 제거 - 검색 결과는 같은 화면에서 표시

    func showDetail(url: URL) {
        path.append(AppRoute.repositoryDetail(url: url))
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

**네비게이션 구조 변경 (2026-03-10):**
| 단계 | 기존 | 변경 후 |
|:---|:---|:---|
| 화면 구조 | SearchView → ResultListView → WebView | SearchView → WebView |
| 검색 결과 | 별도 화면 (ResultListView) | SearchView에 통합 |
| Router 메서드 | `showResults()`, `showDetail()` | `showDetail()`만 사용 |

**변경 이유:**
- 사용자 경험 개선 (불필요한 화면 전환 제거)
- 검색과 결과를 한 화면에서 확인 가능
- 코드 복잡도 감소

**책임 분리:**
| 컴포넌트 | 책임 |
|:---|:---|
| AppRouter | NavigationPath 상태 관리, 화면 전환 메서드 제공 |
| ViewModel | Router 주입받아 `router.showDetail(url:)` 등 호출 |
| View | `NavigationStack(path: $router.path)` 설정, `.navigationDestination` 분기 |

**제한 사항 (복잡성 방지):**
- Coordinator 패턴 미사용 (복잡함)
- DI Container 미사용 (과함)
- Router 낭부에 UseCase 호출 로직 없음 (오직 네비게이션만)

### 2.3 3rd-party 라이브러리 불사용 결정

**결정:** 모든 3rd-party 라이브러리 **사용하지 않음**

**대체 방안:**

| 필요 기능 | 대안 | 이유 |
|:---|:---|:---|
| 이미지 로딩/캐싱 | AsyncImage + URLCache | Kingfisher/SDWebImage 불필요 |
| HTTP 통신 | URLSession | Alamofire 불필요 (1개 endpoint) |
| JSON 파싱 | Codable | 기본 제공 |
| 비동기 | async/await | Combine/RxSwift 불필요 |

**장점:**
- 의존성 관리 단순화
- 빌드 시간 단축
- 기본기 중심의 구현

### 2.4 GitHub API Rate Limit 처리 전략

**제한:** Unauthenticated 요청 기준 10 requests/minute

**처리 전략:**

```
1. 요청 전: Rate Limit 상태 확인 (선택적)
2. 429 응답 시:
   - X-RateLimit-Reset 헤더 파싱
   - 사용자에게 "잠시 후 다시 시도" 메시지
   - 남은 시간 타이머 표시 (선택적)
3. 예방:
   - 페이지네이션 시 연속 호출 방지 (debounce)
   - 검색어 입력 후 일정 시간 대기 (debounce)
```

**에러 타입:**
```swift
enum AppError {
    case rateLimit(resetAt: Date)
    case network
    case invalidResponse(statusCode: Int)
    // ...
}
```

### 2.5 에러 처리 아키텍처

**레이어별 책임:**

```
Data Layer (GitHubAPIClient)
  ↓ HTTP 에러 발생
  ↓ AppError로 변환
Domain Layer (UseCase/Repository)
  ↓ 특별한 처리 없이 전달 (투명성)
Presentation Layer (ViewModel)
  ↓ 에러 타입에 따른 상태 변환
  ↓ @Published var errorMessage: String?
Presentation Layer (View)
  ↓ errorMessage 표시 (Alert 또는 화면 내)
```

**에러 상태 UI:**

| 에러 타입 | UI 표시 | 사용자 액션 |
|:---|:---|:---|
| `emptyQuery` | 입력 필드 하단 메시지 | 재입력 |
| `network` | 화면 중앙 + 재시도 버튼 | 수동 재시도 |
| `rateLimit` | 화면 중앙 + 남은 시간 표시 | 자동 해제 대기 |
| `emptyResult` | 화면 중앙 안내 메시지 | - |
| 기타 | 화면 중앙 + 재시도 버튼 | 수동 재시도 |

---

## 3. 레이어별 책임

### 3.1 Presentation Layer

**View:**
- 화면 레이아웃, 스타일링
- 사용자 입력 처리 (onSubmit, onTap)
- NavigationStack 설정 (`path: $router.path`)
- `.navigationDestination(for: AppRoute.self)` 분기
- Loading/Error/Empty 상태 표시

**ViewModel:**
- `@Published` 상태 관리
- UseCase 호출 (비즈니스 로직 위임)
- Router를 통한 네비게이션 트리거
- 에러 → 사용자 메시지 변환

**Router:**
- `AppRouter`: NavigationPath 상태 관리
- 화면 전환 메서드 제공 (`showDetail`, `pop`)
- ViewModel에 주입되어 사용

**컴포넌트:**
- `RepositoryListCell`: 썸네일 + 제목 + 설명
- `LoadingView`: ProgressView 래퍼
- `ErrorView`: 메시지 + 재시도 버튼
- `EmptyView`: 안내 메시지

### 3.2 Domain Layer

**Entities:**
- `GitHubRepository`: id, name, owner, htmlUrl 등
- `RecentSearchItem`: query, searchedAt

**UseCases:**
- `SearchRepositoriesUseCase`: 키워드 → [GitHubRepository]
- `RecentSearchUseCase`: CRUD + 정렬 + 중복 제거

**Repository Interfaces:**
- `GitHubRepositoryRepository`: search(keyword:page:)
- `RecentSearchStore`: save, load, delete, clear

**Errors:**
- `AppError`: 도메인 관점 에러 타입

### 3.3 Data Layer

**API:**
- `GitHubAPIClient`: URLSession 기반 HTTP 통신
  - timeout: 30초
  - HTTP 상태 코드 처리
  - Rate Limit 헤더 파싱
- `GitHubDTOs`: Codable 준수 DTO

**Repositories:**
- `GitHubRepositoryRepositoryImpl`: DTO → Entity 매핑

**Storage:**
- `UserDefaultsRecentSearchStore`: JSON 인코딩/디코딩
- `InMemoryRecentSearchStore`: 테스트용

---

## 4. 데이터 흐름

### 4.1 검색 플로우

```
[User] 검색어 입력 → Enter
    ↓
[SearchViewModel] search(query)
    ↓
[SearchRepositoriesUseCase] execute(query, page: 1)
    ↓
[GitHubRepositoryRepositoryImpl] search(keyword:page:)
    ↓
[GitHubAPIClient] GET /search/repositories
    ↓
[GitHub API] HTTP Response
    ↓
[GitHubAPIClient] DTO 디코딩 → 에러 처리
    ↓
[GitHubRepositoryRepositoryImpl] DTO → Entity 매핑
    ↓
[SearchRepositoriesUseCase] 결과 반환
    ↓
[RecentSearchUseCase] 최근 검색어 저장
    ↓
[SearchViewModel] 검색 결과 상태 업데이트
    ↓
[SearchView] 같은 화면에서 결과 표시 (ScrollView + LazyVStack)
```

### 4.2 페이지네이션 플로우

```
[SearchView] 스크롤 (마지막에서 3번째 셀)
    ↓
[SearchViewModel] hasMorePages 확인
    ↓
[SearchRepositoriesUseCase] execute(query, page: nextPage)
    ↓
[GitHubAPIClient] 다음 페이지 요청
    ↓
[SearchViewModel] 기존 결과 + 새 결과 병합
    ↓
[SearchView] 리스트 업데이트
```

### 4.3 상세 화면 이동 플로우

```
[User] 셀 탭
    ↓
[SearchViewModel] repository 선택
    ↓
[SearchViewModel] router.showDetail(url: repo.htmlUrl) 호출
    ↓
[AppRouter] path.append(.repositoryDetail(url: url))
    ↓
[SearchView] NavigationStack → RepositoryWebView 표시
```

---

## 5. 테스트 전략

### 5.1 테스트 피라미드

```
    /\
   /  \
  / E2E\     (선택적) UI 테스트
 /______\
 /        \
/ Integration\  (권장) UseCase + Mock Repository
/____________\
/              \
/   Unit Tests   \  (필수) Store, UseCase, ViewModel
/__________________\
```

### 5.2 테스트 우선순위

| 우선순위 | 대상 | 방법 |
|:---|:---|:---|
| 1 | RecentSearchStore | UserDefaults/InMemory 구현 테스트 |
| 2 | RecentSearchUseCase | 비즈니스 로직 (정렬, 중복 제거 등) |
| 3 | SearchRepositoriesUseCase | Mock Repository 주입 테스트 |
| 4 | ViewModel | 상태 변화, 에러 처리 테스트 |
| 5 | GitHubAPIClient | URLProtocol Mock 테스트 |
| 6 | Router | Mock Router 주입 테스트 |

### 5.3 Mock/Stub 전략

```swift
// 테스트용 InMemory Store
final class InMemoryRecentSearchStore: RecentSearchStore { ... }

// 테스트용 Mock Repository
final class MockGitHubRepositoryRepository: GitHubRepositoryRepository {
    var stubResult: [GitHubRepository] = []
    var stubError: Error?
}

// 테스트용 Mock Router
final class MockAppRouter: AppRouter {
    var lastRoute: AppRoute?

    override func showDetail(url: URL) {
        lastRoute = .repositoryDetail(url: url)
    }
}

// API 테스트용 URLProtocol
final class MockURLProtocol: URLProtocol { ... }
```

---

## 6. 논의/검토가 필요한 지점 (해결됨)

| 지점 | 결정 사항 | 근거 |
|:---|:---|:---|
| Router 범위 | **단순화된 구현 사용** | NavigationPath 래핑만, Coordinator는 과함 |
| 3rd-party 라이브러리 | **사용하지 않음** | 기본기 중심 구현 |
| 이미지 캐싱 | **URLCache + AsyncImage** | Kingfisher 불필요 |
| 에러 처리 수준 | **6가지 에러 타입** | 요구사항 충족 |
| 페이지네이션 트리거 | **마지막에서 3번째 셀** | 미리 호출 구현 |
| 검색 결과 표시 | **SearchView에 통합** | UX 개선, 불필요한 화면 전환 제거 |
| 페이지네이션 구현 | **ScrollView + LazyVStack** | List 대신 더 유연한 레이아웃 |

---

## 7. Architect 역할에게 요청할 것 (Claude용 안내)

- 이 문서와 Planning.md를 기반으로:
  - 누락된 설계 포인트가 있으면 지적해 달라.
  - 레이어 경계/의존 방향이 어색한 부분이 있으면 수정 제안해 달라.
  - 프로젝트 규모에서 불필요하게 복잡한 부분이 있으면 단순화 제안해 달라.
- 최종적으로:
  - Domain/Data/Presentation 각 레이어의 파일 목록 + 책임을 한 번 더 정리해 달라.

---

## 8. 파일 목록 (최종)

### Domain Layer
- `Sources/Domain/Entities/GitHubRepository.swift`
- `Sources/Domain/Entities/RecentSearchItem.swift`
- `Sources/Domain/Errors/AppError.swift`
- `Sources/Domain/Repositories/GitHubRepositoryRepository.swift`
- `Sources/Domain/UseCases/SearchRepositoriesUseCase.swift`
- `Sources/Domain/UseCases/RecentSearchUseCase.swift`

### Data Layer
- `Sources/Data/API/GitHubAPIClient.swift`
- `Sources/Data/API/GitHubDTOs.swift`
- `Sources/Data/Repositories/GitHubRepositoryRepositoryImpl.swift`
- `Sources/Data/Storage/RecentSearchStore.swift`
- `Sources/Data/Storage/UserDefaultsRecentSearchStore.swift`
- `Sources/Data/Storage/InMemoryRecentSearchStore.swift`

### Presentation Layer
- `Sources/Presentation/Router/AppRoute.swift`
- `Sources/Presentation/Router/AppRouter.swift`
- `Sources/Presentation/Search/SearchView.swift`
- `Sources/Presentation/Search/SearchViewModel.swift`
- `Sources/Presentation/RepositoryDetail/RepositoryWebView.swift`
- `Sources/Presentation/Components/RepositoryListCell.swift`
- `Sources/Presentation/Components/LoadingView.swift`
- `Sources/Presentation/Components/ErrorView.swift`
- `Sources/Presentation/Components/EmptyView.swift`

### App Layer
- `Sources/App/GitHubSearchApp.swift`
- `Sources/App/AppEnvironment.swift`

### Tests
- `Tests/DomainTests/RecentSearchUseCaseTests.swift`
- `Tests/DomainTests/SearchRepositoriesUseCaseTests.swift`
- `Tests/DataTests/UserDefaultsRecentSearchStoreTests.swift`
- `Tests/DataTests/GitHubAPIClientTests.swift`
- `Tests/DataTests/GitHubDTOsTests.swift`
- `Tests/DataTests/GitHubRepositoryRepositoryImplTests.swift`
- `Tests/PresentationTests/SearchViewModelTests.swift`
- `Tests/PresentationTests/SearchViewModelPaginationTests.swift`
- `Tests/PresentationTests/ImageCacheTests.swift`
- `Tests/UITests/SearchFlowUITests.swift`
