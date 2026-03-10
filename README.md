# GitHubSearch iOS

컬리 사전 과제로 구현한 GitHub 저장소 검색 iOS 앱입니다.
GitHub 저장소를 검색하고, 최근 검색어를 관리하며, 결과를 WebView로 확인할 수 있습니다.

---

## 1. 개요

| 항목 | 내용 |
|------|------|
| 과제 | GitHub 저장소 검색 iOS 앱 |
| 플랫폼 | iOS 17+ |
| 언어/프레임워크 | Swift 5.9, SwiftUI |
| 아키텍처 | Clean Architecture (Presentation / Domain / Data) + MVVM + Router |
| 의존성 관리 | Swift Package Manager |
| 테스트 | 85개 테스트 (단위 71개 + UI 12개), 비즈니스 로직 100% 커버리지 |
| 개발 환경 | Xcode 16.0+, macOS 14+ |

---

## 2. 주요 기능

### ✅ 검색 화면 (통합)
- 검색어 입력 후 GitHub 저장소 검색
- **같은 화면에서 검색 결과 표시** (별도 화면 전환 없음)
- 검색바 동적 레이아웃: 텍스트 입력 시 검색바가 줄어들며 취소 버튼 표시
- 취소 버튼으로 검색 초기화 및 키보드 내림
- 최근 검색어 표시 (최신 순, 중복 제거)
- 최근 검색어 개별 삭제 (X 버튼) / 전체 삭제
- 앱 재시작 후에도 최근 검색어 유지 (UserDefaults)
- 최근 검색어 탭 시 해당 검색어로 재검색
- 자동완성 기능 (최근 검색어 기반)

### ✅ 검색 결과 (SearchView에 통합)
- 같은 화면에서 검색 결과 리스트 표시
- 각 셀에 저장소 이름, Owner 이름, 별 개수, 언어 정보 표시
- AsyncImage로 Owner 아바타 표시
- 스크롤 시 다음 페이지 자동 로드 (페이지네이션)
- Pull-to-Refresh 지원
- 셀 탭 시 GitHub 저장소를 WebView로 오픈

### ✅ 저장소 상세 화면
- WKWebView로 GitHub 저장소 페이지 표시
- NavigationStack 기반 뒤로가기 지원

---

## 3. 프로젝트 구조

```
GitHubSearch-iOS/
├── Package.swift                       # SPM 패키지 정의
├── Sources/                            # GitHubSearch 라이브러리
│   ├── Domain/                         # 비즈니스 로직, 엔티티, 유즈케이스
│   │   ├── Entities/
│   │   ├── UseCases/
│   │   ├── Repositories/
│   │   └── Errors/
│   ├── Data/                           # 네트워크, 저장소 구현
│   │   ├── API/
│   │   ├── Repositories/
│   │   └── Storage/
│   └── Presentation/                   # UI 로직, ViewModel, Router
│       ├── Router/
│       ├── Search/
│       ├── Components/
│       └── AppEnvironment.swift
├── Tests/                              # 85개 테스트
└── README.md                           # 실행 방법 문서
```

### 레이어 의존 방향
```
┌─────────────────────────────────────────┐
│  Presentation Layer (SwiftUI)           │
│  - SearchView, ViewModel                │
│  - AppRouter (Navigation)               │
├─────────────────────────────────────────┤
│  Domain Layer                           │
│  - UseCases (비즈니스 로직)              │
│  - Entities (GitHubRepository 등)       │
│  - Repository Interfaces                │
├─────────────────────────────────────────┤
│  Data Layer                             │
│  - Repository Implementations           │
│  - APIClient (GitHub API)               │
│  - Storage (UserDefaults)               │
└─────────────────────────────────────────┘
```

---

## 4. 실행 방법

### 요구사항
- **Xcode**: 16.0 이상
- **iOS**: 17.0 이상
- **macOS**: 14.0 (Sonoma) 이상

### 방법 1: Xcode에서 Package.swift 열기 (권장)

```bash
# 저장소 클론
git clone https://github.com/your-id/GitHubSearch-iOS.git
cd GitHubSearch-iOS

# Xcode에서 Package.swift 열기
open Package.swift
```

Xcode가 자동으로 SPM 프로젝트를 로드합니다. 그 후:

1. **Xcode가 Package.swift를 로드하면 자동으로 Swift 패키지가 인식됨**

2. **iOS 앱 타겟 추가**:
   - `File > New > Target...`
   - `iOS` → `App` 선택
   - Product Name: `GitHubSearchApp`
   - Team: None (또는 자신의 팀)
   - Organization Identifier: `com.kurly`
   - Interface: `SwiftUI` (또는 Storyboard)
   - Language: `Swift`

3. **SPM 패키지 의존성 추가**:
   - 프로젝트 네비게이터에서 `GitHubSearchApp` 타겟 선택
   - `Build Phases` → `Link Binary With Libraries`
   - `+` 버튼 클릭 → `GitHubSearch` 선택

4. **앱 소스 코드 작성**:

   `GitHubSearchApp.swift` (또는 `AppDelegate.swift` / `SceneDelegate.swift`):
   ```swift
   import SwiftUI
   import GitHubSearch

   @main
   struct GitHubSearchApp: App {
       @StateObject private var router = AppRouter()

       var body: some Scene {
           WindowGroup {
               NavigationStack(path: $router.path) {
                   SearchView(
                       viewModel: SearchViewModel(
                           searchUseCase: AppEnvironment.shared.searchUseCase,
                           recentSearchUseCase: AppEnvironment.shared.recentSearchUseCase,
                           router: router
                       )
                   )
                   .navigationDestination(for: AppRoute.self) { route in
                       switch route {
                       case .repositoryDetail(let url):
                           RepositoryWebView(url: url)
                       default:
                           EmptyView()
                       }
                   }
               }
               .environmentObject(router)
           }
       }
   }
   ```

5. **빌드 및 실행**:
   - iPhone 16 시뮬레이터 선택 (iOS 17.0+)
   - `Cmd + R` 로 앱 빌드 및 실행

### 방법 2: Swift Package Manager만으로 테스트 실행

```bash
# 전체 테스트 실행 (단위 테스트만, iOS 시뮬레이터 불필요)
swift test

# 특정 테스트 실행
swift test --filter DomainTests
swift test --filter DataTests
swift test --filter PresentationTests

# 커버리지 리포트
swift test --enable-code-coverage
```

---

## 5. 테스트

### 테스트 현황

| 레이어 | 테스트 파일 | 개수 | 주요 내용 |
|--------|------------|------|----------|
| Domain | RecentSearchUseCaseTests | 12 | 저장/조회/삭제, 중복, 순서, 에러 |
| Domain | SearchRepositoriesUseCaseTests | 11 | 검색 성공/실패, 에러 변환 |
| Data | GitHubAPIClientTests | 15 | API 호출, HTTP 상태, Rate Limit |
| Data | GitHubDTOsTests | 9 | DTO 매핑, Date 파싱 |
| Data | GitHubRepositoryRepositoryImplTests | 6 | Repository 패턴, hasNextPage 계산 |
| Data | UserDefaultsRecentSearchStoreTests | 8 | 저장/로드/삭제, UserDefaults |
| Presentation | SearchViewModelTests | 16 | 검색, 최근 검색어, 자동완성, 네비게이션 |
| Presentation | AppRouterTests | 6 | push, pop, popToRoot |
| Presentation | ResultListViewModelTests | 9 | 페이지네이션, 새로고침, 에러 |
| UI | SearchFlowUITests | 12 | 검색 흐름, 최근 검색어, 네비게이션 |

**총 85개 테스트** (단위 71개 + UI 12개)

### 테스트 실행

```bash
# SPM 테스트
swift test

# Xcode에서 테스트
# Package.swift를 Xcode에서 연 후 Cmd + U
```

---

## 6. 아키텍처 / 설계

### Clean Architecture 레이어

```
┌─────────────────────────────────────────┐
│  Presentation Layer (SwiftUI)           │
│  - SearchView, ResultListView           │
│  - SearchViewModel, ResultListViewModel │
│  - AppRouter (Navigation)               │
├─────────────────────────────────────────┤
│  Domain Layer                           │
│  - UseCases (비즈니스 로직)              │
│  - Entities (GitHubRepository 등)       │
│  - Repository Interfaces                │
├─────────────────────────────────────────┤
│  Data Layer                             │
│  - Repository Implementations           │
│  - APIClient (GitHub API)               │
│  - Storage (UserDefaults)               │
└─────────────────────────────────────────┘
```

### 네비게이션 (Router 패턴)

- `AppRoute`: 화면 목적지를 enum으로 정의 (`repositoryDetail(url:)`)
- `AppRouter`: `NavigationPath`를 관리하며 push/pop 메서드 제공
- ViewModel은 Router를 통해 네비게이션 트리거

### 비즈니스 로직

- **검색**: `SearchRepositoriesUseCase` → `GitHubRepositoryRepository` → `GitHubAPIClient`
- **검색 결과**: SearchViewModel에서 상태 관리 (`repositories`, `totalCount`, `hasNextPage`)
- **최근 검색**: `RecentSearchUseCase` → `RecentSearchStore` (UserDefaults)

### 에러 처리

- `AppError` enum으로 공통 에러 타입 정의
- Network, Decoding, RateLimit, InvalidParameter, Unknown 케이스
- localizedDescription 제공

---

## 7. GitHub API 연동

### 사용하는 API

```
GET https://api.github.com/search/repositories?q={keyword}&page={page}&per_page=30
```

### 주의사항

- GitHub API는 **Rate Limit**가 있습니다 (인증 없이 60요청/시간)
- `X-RateLimit-Remaining`, `X-RateLimit-Reset` 헤더 확인
- 과도한 검색은 403 Forbidden 반환 가능

---

## 8. AI Assist 활용

이 프로젝트에서는 Claude를 활용하여 다음과 같이 개발했습니다:

| 역할 | 활용 내용 |
|------|----------|
| Architect | Clean Architecture 설계, 폴더 구조 정의 |
| Developer | DTO, Repository, UseCase, Store, ViewModel, View 구현 |
| Reviewer | 코드 리뷰, /simplify 자동 검증 |
| Tester | 테스트 코드 작성, 커버리지 분석 |

**구체적인 프롬프트와 AI의 기여 내용**: [AI_ASSIST.md](AI_ASSIST.md) 참조

---

## 9. 향후 개선 아이디어

- [ ] 검색 결과 정렬 / 필터 기능 (Stars, Updated 등)
- [ ] GitHub Personal Access Token 설정으로 Rate Limit 증가
- [ ] 즐겨찾기(Starred) 저장소 관리
- [ ] 다국어(Localization) 지원
- [ ] 다크모드 지원

---

## 10. 라이선스

MIT License
