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
| 테스트 | 64개 테스트, 비즈니스 로직 100% 커버리지 |

---

## 2. 주요 기능

### ✅ 검색 화면
- 검색어 입력 후 GitHub 저장소 검색
- 최근 검색어 표시 (최신 순, 중복 제거)
- 최근 검색어 개별 삭제 (스와이프) / 전체 삭제
- 앱 재시작 후에도 최근 검색어 유지 (UserDefaults)
- 최근 검색어 탭 시 해당 검색어로 재검색

### ✅ 검색 결과 / 상세
- 검색 결과 리스트 표시
- 각 셀에 저장소 이름, Owner 이름, 별 개수, 언어 정보 표시
- AsyncImage로 Owner 아바타 표시
- 리스트 스크롤 시 다음 페이지 자동 로드 (페이지네이션)
- Pull-to-Refresh 지원
- 셀 탭 시 GitHub 저장소를 WebView로 오픈

---

## 3. 프로젝트 구조

```
Sources/
  App/
    GitHubSearchApp.swift          # 앱 엔트리 포인트 (@main)
    AppEnvironment.swift           # DI 컨테이너 (Singleton)

  Presentation/
    Router/
      AppRoute.swift               # 화면 전환 목적지 정의 (enum)
      AppRouter.swift              # NavigationPath 관리
    Search/
      SearchView.swift             # 검색 화면 UI
      SearchViewModel.swift        # 검색/최근 검색 상태 관리
    ResultList/
      ResultListView.swift         # 검색 결과 리스트 UI
      ResultListViewModel.swift    # 페이지네이션, 로딩 상태 관리
    RepositoryDetail/
      RepositoryWebView.swift      # WKWebView 기반 상세 화면
    Components/
      RepositoryListCell.swift     # 저장소 리스트 셀
      LoadingView.swift            # 로딩 상태 공통 컴포넌트
      ErrorView.swift              # 에러 상태 공통 컴포넌트
      EmptyView.swift              # 빈 상태 공통 컴포넌트

  Domain/
    Entities/
      GitHubRepository.swift       # 저장소 도메인 모델
      RecentSearchItem.swift       # 최근 검색어 도메인 모델
      RepositoryOwner.swift        # 저장소 소유자 모델
      SearchResult.swift           # 검색 결과 모델
    UseCases/
      SearchRepositoriesUseCase.swift    # 저장소 검색 유즈케이스
      RecentSearchUseCase.swift          # 최근 검색어 관리 유즈케이스
    Errors/
      AppError.swift               # 공통 에러 타입 (Network, Decoding, RateLimit 등)
    Repositories/
      GitHubRepositoryRepository.swift   # Repository 인터페이스

  Data/
    API/
      GitHubAPIClient.swift        # GitHub API 호출 (async/await)
      GitHubDTOs.swift             # API 응답 DTO 및 매핑 로직
    Repositories/
      GitHubRepositoryRepositoryImpl.swift  # Repository 구현체
    Storage/
      RecentSearchStore.swift            # Store 프로토콜
      UserDefaultsRecentSearchStore.swift # UserDefaults 구현체
      InMemoryRecentSearchStore.swift     # 메모리 구현체 (테스트용)

Tests/
  DomainTests/
    RecentSearchUseCaseTests.swift       # 12개 테스트
    SearchRepositoriesUseCaseTests.swift # 11개 테스트
  DataTests/
    GitHubAPIClientTests.swift           # 15개 테스트
    GitHubDTOsTests.swift                # 9개 테스트
    GitHubRepositoryRepositoryImplTests.swift # 6개 테스트
    UserDefaultsRecentSearchStoreTests.swift  # 8개 테스트
  PresentationTests/
    SearchViewModelTests.swift           # 12개 테스트
    AppRouterTests.swift                 # 7개 테스트
    ResultListViewModelTests.swift       # 9개 테스트
```

### 레이어 의존 방향
```
Presentation (View → ViewModel)
       ↓
Domain (UseCase → Repository Interface)
       ↓
Data (Repository Implementation → API/Storage)
```

---

## 4. 빌드 및 실행 방법

### Swift Package Manager (권장)

```bash
# 1. 리포지토리 클론
git clone https://github.com/your-id/GitHubSearch-iOS.git
cd GitHubSearch-iOS

# 2. 빌드
swift build

# 3. 테스트
swift test

# 4. 커버리지 포함 테스트
swift test --enable-code-coverage
```

### Xcode

```bash
# Xcode 프로젝트 생성 (Package.swift 기반)
open Package.swift
```

또는

```bash
# Xcode에서 직접 열기
xed .
```

**참고**: iOS 앱을 실제로 빌드하려면 `Sources/App/GitHubSearchApp.swift`에서 `@main` 주석을 해제해야 합니다. (SPM 테스트와의 충돌 방지를 위해 현재는 주석 처리됨)

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
| Presentation | SearchViewModelTests | 12 | 검색, 최근 검색어, 네비게이션 |
| Presentation | AppRouterTests | 7 | push, pop, popToRoot |
| Presentation | ResultListViewModelTests | 9 | 페이지네이션, 새로고침, 에러 |

**총 64개 테스트 통과**

### 코드 커버리지

| 레이어 | 주요 컴포넌트 | 커버리지 |
|--------|-------------|----------|
| Domain | UseCases | **100%** |
| Data | Repository | **100%** |
| Data | Store | **88%** |
| Presentation | ViewModels | **80-90%** |
| Presentation | Router | **100%** |

### 테스트 실행

```bash
# 전체 테스트
swift test

# 특정 테스트 타겟
swift test --filter DomainTests
swift test --filter DataTests
swift test --filter PresentationTests

# 커버리지 리포트 생성
swift test --enable-code-coverage
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

- `AppRoute`: 화면 목적지를 enum으로 정의 (`resultList(query:)`, `repositoryDetail(url:)`)
- `AppRouter`: `NavigationPath`를 관리하며 push/pop 메서드 제공
- ViewModel은 Router를 통해 네비게이션 트리거

### 비즈니스 로직

- **검색**: `SearchRepositoriesUseCase` → `GitHubRepositoryRepository` → `GitHubAPIClient`
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
- [ ] SwiftUI UI 테스트 추가

---

## 10. 라이선스

MIT License
