# Claude Guide – GitHubSearch iOS Project

이 문서는 GitHub 저장소 검색 iOS 과제에서 Claude(및 다른 AI Assist)가 어떻게 동작해야 하는지 정의하는 가이드입니다.

---

## 0. 핵심 원칙 (Core Principles)

이 프로젝트에서 Claude는 반드시 다음 4가지 원칙을 준수합니다.

### ① Think Before Coding — 모류면 추측하지 말고 물어봐
- 불확실한 요구사항이나 모호한 부분이 있으면 추측하지 말고 즉시 질문한다.
- "이 부분은 ~로 이해했는데 맞나요?" 형태로 확인 후 진행한다.

### ② Simplicity First — 요청한 것만 만들어. 200줄이 50줄로 되면 다시 써
- 과잉 설계(over-engineering)를 금한다. 요청된 기능만 구현한다.
- 코드는 간결하게. 200줄로 된 코드가 50줄로 줄일 수 있다면 다시 작성한다.
- 미래를 대비한 추상화, 불필요한 확장성은 만들지 않는다.

### ③ Surgical Changes — 옆 코드 "개선"하지 마. 변경된 모든 줄이 요청으로 추적 가능해야 함
- 요청받은 부분만 수정한다. 주변 코드를 "보이면서" 개선하지 않는다.
- 모든 변경은 사용자의 명시적 요청과 1:1로 매핑되어야 한다.
- 리팩토링은 별도 요청으로 받거나, 먼저 제안하고 동의를 얻은 후 진행한다.

### ④ Goal-Driven Execution — "버그 고쳐" 대신 "버그 재현 테스트 쓰고 통과시켜"
| 잘못된 요청 | 올바른 접근 |
|------------|-----------|
| "유효성 검사 추가" | "잘못된 입력에 대한 테스트를 작성한 다음, 해당 테스트가 통과하도록 만드세요." |
| "버그를 수정하세요" | "문제를 재현하는 테스트를 작성하고, 그 테스트가 통과하도록 만드세요." |
| "X를 리팩토링" | "테스트를 먼저 작성한 후 리팩토링하고, 테스트가 반드시 통과하도록 하십시오." |

- 작업 시작 전, 완료 기준(Definition of Done)을 명확히 한다.
- 버그 수정/리팩토링 시 테스트를 먼저 작성하고, 테스트가 통과하는 것을 목표로 한다.

### ⑤ Multi-Step Planning — 여러 단계를 거치는 작업은 간략한 계획을 제시한다
복잡한 작업(3단계 이상)을 수행할 때는 다음 형식으로 계획을 먼저 제시한다:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

**예시:**
```
1. UserDefaultsRecentSearchStore 구현 → verify: RecentSearchStore 프로토콜 준수
2. SearchViewModel에 저장 로직 연결 → verify: 검색 시 자동 저장 확인
3. UI에 최근 검색어 리스트 추가 → verify: 화면에 정상 표시 및 탭 시 검색
```

- 사용자 확인 후에 다음 단계로 진행하거나, 전체 진행 후 결과를 보고한다.

---

## 1. 프로젝트 개요

- 목적: GitHub 저장소 검색 iOS 앱 (컬리 사전 과제)
- 플랫폼: iOS 17+, Swift 5.9, SwiftUI
- 아키텍처: Clean Architecture (Presentation / Domain / Data) + MVVM + Router
- 주요 기능:
  - 검색 화면: 검색어 입력, 최근 검색어 표시/삭제/저장, 검색 결과 표시
  - 검색 결과: 같은 화면에서 리스트로 표시, 페이지네이션
  - 상세 화면: 저장소 WebView 오픈

**2026-03-10 UI/UX 개선:**
- 검색 결과를 별도 화면(ResultListView)이 아닌 SearchView에 통합
- 네비게이션 구조: SearchView → RepositoryWebView (간소화)
- 검색바: 텍스트 입력 시 동적으로 줄어들며 취소 버튼 표시
- 취소 버튼: 빨간색으로 변경
- 최근 검색어: 시계/화살표 아이콘 제거, X 버튼으로 개별 삭제
- 페이지네이션: List → ScrollView + LazyVStack 변경

이 파일에 적힌 내용을 항상 우선순위 높게 반영해서 답변해 주세요.

---

## 2. 폴더 / 레이어 구조

현재(또는 목표) 프로젝트 구조는 다음과 같습니다.

```text
Sources/
  App/
    GitHubSearchApp.swift

  Presentation/
    Router/
      AppRoute.swift
      AppRouter.swift
    Search/
      SearchView.swift
      SearchViewModel.swift
    ResultList/
      ResultListView.swift
      ResultListViewModel.swift
    Components/
      RepositoryListCell.swift
      LoadingView.swift
      ErrorView.swift

  Domain/
    Entities/
      GitHubRepository.swift
      RecentSearchItem.swift
    UseCases/
      SearchRepositoriesUseCase.swift
      RecentSearchUseCase.swift
    Errors/
      AppError.swift
    Repositories/
      GitHubRepositoryRepository.swift

  Data/
    API/
      GitHubAPIClient.swift
      GitHubDTOs.swift
    Repositories/
      GitHubRepositoryRepositoryImpl.swift
    Storage/
      RecentSearchStore.swift
      UserDefaultsRecentSearchStore.swift
      InMemoryRecentSearchStore.swift

  Common/
    Extensions/
    Utils/

Tests/
  DomainTests/
  DataTests/
  PresentationTests/

README.md
Claude.md
Planning.md
AI_ASSIST.md
ARCHITECT.md
DEV_TASKS.md
CODE_REVIEW_AND_TESTING.md

코드를 제안할 때는 반드시 위 구조 중 어디에 들어갈 파일인지 먼저 명시하고, 그 위치에 맞는 스타일로 작성해 주세요.

## 3. 아키텍처 / 네비게이션 원칙

1. 레이어 분리
   - Presentation / Domain / Data 레이어 분리를 유지한다.
   - View → ViewModel → UseCase → Repository → API/Storage 방향의 의존을 허용한다.

2. Router를 통한 네비게이션 분리
   - SwiftUI NavigationStack을 사용하되, AppRouter가 NavigationPath를 관리한다.
   - ViewModel은 Router를 통해 네비게이션을 트리거하며, NavigationStack 직접 제어는 하지 않는다.
   - Router는 단순화된 구현: NavigationPath 래핑만 담당

3. 기존 폴터 구조를 우선한다
   - 새로운 타입/파일이 필요하면 위 구조 안에서 자연스러운 위치를 먼저 제안한다.
   - 구조를 크게 바꾸고 싶을 때는, 먼저 이유와 장단점을 짧게 설명한 뒤 내 동의를 구한다.

4. 작은 단위로 제안한다
   - 한 번에 너무 많은 파일/코드를 생성하지 말고, 1~2 파일 단위로 제안한다.
   - 예: "이번 답변에서는 DTO + APIClient만 다루겠습니다"처럼 범위를 명시한다.

5. 테스트 가능성을 유지한다
   - UseCase, Repository, Store는 항상 프로토콜을 우선으로 설계한다.
   - ViewModel은 의존성을 생성자 주입 받도록 작성한다.

6. 과제 요구사항을 우선한다
   - 과제 범위를 벗어나는 기능(즐겨찾기, 다크모드 등)은 먼저 제안만 하고, 내가 허용했을 때만 실제 코드로 작성한다.

7. 코드 스타일을 일관되게 유지한다
   - Swift API 디자인 가이드라인을 따르고, iOS 개발자스러운 네이밍을 사용한다.
   - 비동기는 Swift Concurrency(async/await)을 사용한다.
   - 에러는 `AppError`로 래핑하고, 필요 시 case를 추가한다.

## 4. 네비게이션(Router) 규칙

- Router
  - `@MainActor final class AppRouter: ObservableObject`
  - `@Published var path = NavigationPath()`를 가지고,
    `showDetail(url:)`, `pop()`, `popToRoot()` 메서드로 경로 변경
  - showResults(for:)는 검색 결과가 SearchView에 통합되어 제거됨
  - 단순한 구현: NavigationPath 래핑만 담당, 복잡한 Coordinator 로직은 포함하지 않음

- Route
  - `enum AppRoute: Hashable { case repositoryDetail(url: URL) }`
  - resultList는 SearchView에 통합되어 별도 Route 없음
  - 연관값을 통해 필요한 정보 전달

- RootView
  - `NavigationStack(path: $router.path)`를 사용하고,
  - `navigationDestination(for: AppRoute.self)`에서 route에 따라 화면 분기

- ViewModel
  - ViewModel은 Router를 생성자 주입받아 사용
  - "사용자 액션" → "Router 메서드 호출" 로 네비게이션 트리거
  - 예: `router.showResults(for: searchQuery)`

## 5. 네가 도와줄 수 있는 일의 범위

### 5.1. OK (도움을 적극적으로 요청하는 영역)

- Domain
  - Entities, UseCases, Repositories 인터페이스/구현 초안
- Data
  - GitHub API DTO, APIClient, Repository 구현 초안
  - RecentSearchStore(UserDefaults/InMemory) 구현 초안
  - HTTP 상태 코드 처리 및 Rate Limit 대응 로직
- Presentation
  - ViewModel 골격 코드, 페이지네이션/상태 관리 로직
  - SwiftUI View 레이아웃 기본구조
  - Loading/Error/Empty 상태 UI
  - AppRouter/AppRoute 간단한 구현
- Tests
  - UseCase/Store/Repository/ViewModel에 대한 XCTest 예제 작성
- Refactoring / Review
  - 내가 쓴 코드를 보여주면, 개선 포인트/리팩터링 아이디어를 제안

### 5.2. NOT OK (먼저 하지 말 것)

- 내 동의 없이:
  - 전체 아키텍처를 다른 패턴으로 교체하는 제안
  - 3rd-party 라이브러리 도입 제안 (Kingfisher, Alamofire 등)
  - 과제 요구사항과 동떨어진 기능(알림, 로그인 등) 추가

## 6. 코드 제안 시 형식

코드나 설계를 제안할 때는 반드시 아래 형식을 따른다.

1. 어떤 파일/위치를 대상으로 하는지 명시
2. 전체 코드 블록
3. 내가 손봐야 할 포인트를 Bullet로 요약

예시:

> 예상 프롬프트
> `Sources/Data/API/GitHubAPIClient.swift`에 들어갈 GitHub API 클라이언트 초안을 작성해줘.

이때 답변 형식:

```markdown
### File: Sources/Data/API/GitHubAPIClient.swift

```swift
// 전체 코드
final class DefaultGitHubAPIClient: GitHubAPIClient {
    // ...
}
```

- 체크 포인트:
  - 에러 타입(AppError) 정의와 맞는지 확인 필요
  - GitHub API rate limit 관련 처리가 필요한지 검토

이 형식을 항상 유지해 달라.

## 7. 역할 기반 사용 방식

이 프로젝트에서는 나(사용자)가 다음 4가지 역할을 번갈아 수행한다.

- Architect: 아키텍처 설계와 의사결정
- Developer: 실제 구현
- Reviewer: 코드 리뷰 및 리팩터링 제안
- Tester: 테스트 전략 수립 및 테스트 코드 보완

너(Claude)는 내가 어떤 역할로 질문하느냐에 따라 답변 스타일을 바꿔야 한다.

### 워크플로우 프로세스 (필수)

각 Phase/작업은 다음 순서로 진행한다:

```
┌─────────────────┐
│  1. Developer   │  ← "지금은 Developer 역할이야"로 시작
│    (개발)       │     - 1~2 파일 단위로 구현
└────────┬────────┘
         ↓
┌─────────────────┐
│  2. Reviewer    │  ← 개발 완료 후 "지금은 Reviewer 역할이야"로 전환
│   (코드 리뷰)    │     - CODE_REVIEW_AND_TESTING.md 기준 검토
└────────┬────────┘
         ↓
┌─────────────────┐
│ 3. /simplify    │  ← 리뷰 완료 후 /simplify 명령 실행
│  (자동 리뷰)    │     - 재사용성, 품질, 효율성 검증
└────────┬────────┘
         ↓
┌─────────────────┐
│   4. Tester     │  ← "지금은 Tester 역할이야"로 전환
│    (테스트)     │     - CODE_REVIEW_AND_TESTING.md 기준 테스트 작성
└────────┬────────┘
         ↓
┌─────────────────┐
│ 5. AI_ASSIST.md │  ← 모든 과정 완료 후 AI_ASSIST.md 업데이트
│    (기록)       │     - 프롬프트/답변/결정사항 요약 기록
└─────────────────┘
```

**규칙:**
- 한 Phase가 완료되기 전(리뷰→simplify→테스트 완료 전)에는 다음 Phase로 넘어가지 않는다.
- 커밋은 반드시 Reviewer 리뷰 및 /simplify 검증 완료 후 진행한다.
- AI_ASSIST.md는 각 Phase 완료 후 반드시 업데이트한다.

### 7.1. Architect 역할일 때

내가 "지금은 Architect 역할이야"라고 말하면:

- 설계 대안을 2~3개 제시하고, 장단점을 비교해 준다.
- 코드는 최소화하고, 구조/의존 방향/레이어링/경계에 집중한다.
- 필요하면 Planning.md, ARCHITECT.md 내용을 참고해
  누락된 요구사항이나 위험 요소를 지적한다.

### 7.2. Developer 역할일 때

내가 "지금은 Developer 역할이야"라고 말하면:

- 내가 지정한 파일 경로에 맞춰 전체 코드를 제안한다.
- 한 번에 1~2 파일 정도만 다루고, 해당 Phase/작업에 집중한다.
- 답변 마지막에 "내가 수동으로 확인해야 할 포인트"를 짧게 Bullet로 정리한다.

### 7.3. Reviewer 역할일 때

내가 "지금은 Reviewer 역할이야"라고 말하면:

- CODE_REVIEW_AND_TESTING.md 기준으로 문제점을 지적한다.
- 구조, 에러 처리, 네이밍, 테스트, 유지보수 관점에서 코멘트를 단다.
- 필요하면 작은 리팩터링 패치(함수 단위, 파일 단위)를 제안하되,
  전체 구조를 갈아엎기보다는 "점진적 개선"에 초점을 둔다.

### 7.4. Tester 역할일 때

내가 "지금은 Tester 역할이야"라고 말하면:

- CODE_REVIEW_AND_TESTING.md 기준으로 어떤 테스트가 부족한지 알려준다.
- 우선순위가 높은 테스트(도메인 로직, 에러/엣지케이스)를 먼저 제안한다.
- 구체적인 XCTest 코드 예제를 작성해 주고,
  어떤 케이스를 더 추가하면 좋은지도 함께 제안한다.

## 8. 연관 문서

프로젝트 루트에는 다음 문서들이 있다.

- Claude.md: 공통 규칙과 아키텍처/역할 원칙.
- Planning.md: 요구사항 정리, 작업 Phase/TODO 리스트.
- ARCHITECT.md: 아키텍처 설계용 상세 메모.
- DEV_TASKS.md: 구현 단계별 작업 목록.
- CODE_REVIEW_AND_TESTING.md: 코드 리뷰 기준과 테스트 전략.
- UI_SPEC.md: 과제에서 요구하는 UI/UX 스펙.
- AI_ASSIST.md: AI Assist 사용 로그.

내가 대화에서 이들 문서 내용을 붙여 넣으면,
해당 문서의 규칙과 컨텍스트를 최우선으로 따라야 한다.

## 9. 구체적인 스타일 가이드

- 이름
  - UseCase: `SearchRepositoriesUseCase`, 구현체: `DefaultSearchRepositoriesUseCase`
  - Repository: `GitHubRepositoryRepository`, 구현체: `GitHubRepositoryRepositoryImpl`
  - Store: `UserDefaultsRecentSearchStore`, `InMemoryRecentSearchStore`
  - Router: `AppRouter`, Route enum: `AppRoute`
  - View: `SearchView`, `ResultListView`
  - Component: `RepositoryListCell`, `LoadingView`, `ErrorView`

- 에러
  - 공통: `enum AppError: Error { ... }`
  - Network/Decoding 등은 `AppError.network`, `AppError.decoding`으로 래핑
  - GitHub Rate Limit: `AppError.rateLimit(resetAt: Date)` 추가 고려

- SwiftUI / ViewModel
  - ViewModel: `@MainActor final class XXXViewModel: ObservableObject`
  - 상태: `@Published` 프로퍼티 사용
  - 의존성: 생성자 인젝션 (UseCase, Router 등)
  - 이미지: `AsyncImage` 사용 (3rd-party 라이브러리 사용하지 않음)

- Router
  - 단순화된 구현: NavigationPath 래핑만 담당
  - `@Published var path = NavigationPath()`
  - 명시적 메서드: `showDetail(url:)`, `pop()`
  - showResults(for:)는 제거됨 (검색 결과가 SearchView에 통합)
  - 복잡한 Coordinator 패턴, DI Container는 사용하지 않음

- API Client
  - URLSession 사용 (Alamofire 등 외부 라이브러리 사용하지 않음)
  - timeout: 30초 기본
  - HTTP 상태 코드: 200, 401, 403, 429, 503 등 명시적 처리
  - Rate Limit 헤더 파싱: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

- 테스트
  - 네이밍 예시: `RecentSearchUseCaseTests`, `UserDefaultsRecentSearchStoreTests`, `SearchViewModelTests`
  - Given-When-Then 패턴에 맞춰 명확한 테스트 이름 사용

## 10. 답변의 우선순위

1. 정확한 아키텍처/레이어링
2. Router를 통한 깔끔한 네비게이션 책임 분리
3. 읽기 좋은 코드와 테스트 용이성
4. 과제 요구사항 충족 (GitHub API 연동, 최근 검색어, 페이지네이션 등)
5. 에러 처리 (네트워크, Rate Limit, 빈 결과 등)
6. 그 다음이 최적화/추가 기능

최대한 "시니어 iOS 개발자와 페어 프로그래밍한다"는 느낌으로,
내 설계를 존중하면서 빠르게 초안을 만들어 주는 역할을 해 달라.
