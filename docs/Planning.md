# Planning – GitHubSearch iOS

## 1. 프로젝트 개요

- 프로젝트: GitHub 저장소 검색 iOS 앱
- 목표:
  - GitHub 저장소 검색 기능 구현
  - 최근 검색어 저장/표시
  - 페이지네이션 및 WebView 상세 보기
  - AI Assist(ChatGPT, Claude, Gemini 등)를 활용한 설계/구현/리뷰

## 2. 요구사항 정리

### 2.1 기능 요구사항

- 검색 화면
  - [x] [필수] 검색어 입력 후 결과 표시
  - [x] [필수] 빈 검색어 시 최근 검색어 10개 표시
  - [x] [필수] 최근 검색어 날짜 기준 내림차순 정렬
  - [x] [필수] 개별/전체 삭제 가능
  - [x] [필수] 앱 재시작 시 유지
  - [x] [필수] 최근 검색어 선택 시 결과 표시
  - [ ] [추가] 입력 시 자동완성 (최근 검색어 기반, 날짜 함께 표시)

- 검색 결과 화면 (SearchView에 통합됨)
  - [x] [필수] List 형태 결과 (ScrollView + LazyVStack 사용)
  - [x] [필수] 총 결과 수 표시
  - [x] [필수] 저장소 정보: Thumbnail(owner.avatar_url), Title(name), Description(owner.login)
  - [x] [필수] 선택 시 WebView 이동
  - [x] [추가] 스크롤 중간에 Next Page 미리 호출
  - [x] [추가] 로딩 상태 표시

### 2.2 비기능 요구사항 ✅ 완료

- [x] 아키텍처: Clean Architecture (Presentation / Domain / Data) + MVVM
- [x] 언어/플랫폼: Swift 5.9, iOS 17+, SwiftUI
- [x] 네비게이션: NavigationStack + Router 패턴 (단순화된 구현)
- [x] 비동기: Swift Concurrency (async/await)
- [x] 이미지: AsyncImage 사용 (3rd-party 라이브러리 미사용)
- [x] 네트워크: URLSession 사용 (Alamofire 미사용)
- [x] 테스트: 비즈니스 로직(UseCase/Store) + Presentation + UI 테스트 (총 76개)

### 2.3 GitHub API 정보

- Endpoint: `GET https://api.github.com/search/repositories?q={keyword}&page={page}`
- Rate Limit: 10 requests per minute (unauthenticated)
- 응답 헤더:
  - `X-RateLimit-Limit`: 분당 최대 요청 수
  - `X-RateLimit-Remaining`: 남은 요청 수
  - `X-RateLimit-Reset`: 제한 해제 시간 (Unix timestamp)

## 3. 아키텍처 개요

- Presentation
  - SwiftUI View, ViewModel
  - AppRouter 기반 네비게이션 (단순화된 구현)
  - Loading/Error/Empty 상태 UI

- Domain
  - Entities (GitHubRepository, RecentSearchItem)
  - UseCases (SearchRepositoriesUseCase, RecentSearchUseCase)
  - Errors (AppError - network, decoding, rateLimit 등)
  - Repository 인터페이스

- Data
  - API (GitHubAPIClient, DTOs)
  - HTTP 상태 코드 처리 (200, 401, 403, 429, 503)
  - Rate Limit 헤더 파싱
  - Repositories 구현체
  - Storage (UserDefaultsRecentSearchStore, InMemoryRecentSearchStore)

## 4. 개발 Phase 계획

### Phase 1 – Domain 레이어 ✅ 완료

- [x] Entities 정의 (GitHubRepository, RecentSearchItem)
- [x] AppError 정의 (network, decoding, rateLimit, emptyQuery 등)
- [x] Repository 인터페이스 정의
- [x] UseCase 프로토콜 + 기본 구현 정의
- [x] Domain 레이어 테스트 (RecentSearchUseCase 15개, SearchRepositoriesUseCase 12개)

**완료 기준:** Domain 레이어 단위 테스트 작성 가능 ✓

### Phase 2 – Data 레이어 ✅ 완료

- [x] GitHub DTO 정의 및 매핑 (snake_case → camelCase)
- [x] GitHubAPIClient 구현
  - [x] URLSession configuration (timeout: 30s)
  - [x] HTTP 상태 코드별 에러 매핑
  - [x] Rate Limit 헤더 파싱 (X-RateLimit-Remaining, X-RateLimit-Reset)
- [x] Repository 구현체 (GitHubRepositoryRepositoryImpl)
- [x] RecentSearchStore 프로토콜 정의
- [x] UserDefaultsRecentSearchStore 구현 (JSON 인코딩/디코딩)
- [x] InMemoryRecentSearchStore 구현 (테스트용)
- [x] Data 레이어 테스트 (APIClient 15개, DTOs 9개, Repository 6개, Store 8개)

**완료 기준:** API 호출 및 저장소 CRUD 테스트 통과 ✓

### Phase 3 – Presentation 레이어 ✅ 완료

- [x] AppRouter, AppRoute 구현 (단순화된 Router 패턴)
- [x] SearchViewModel 구현
  - [x] 검색어 입력 상태 관리
  - [x] 최근 검색어 로드/추가/삭제
  - [x] 검색 실행 및 결과 상태 관리
  - [x] 페이지네이션 로직 (ScrollView + LazyVStack)
- [x] SearchView 구현
  - [x] 검색어 입력 필드 (동적 취소 버튼)
  - [x] 최근 검색어 리스트 (X 버튼 개별 삭제)
  - [x] 검색 결과 리스트 (SearchView에 통합)
  - [x] 총 결과 수 표시
  - [x] 무한 스크롤 (마지막 3개 아이템에서 다음 페이지 로드)
- [x] RepositoryWebView (WebView) 구현
- [x] LoadingView, ErrorView, EmptyView 컴포넌트
- [x] Presentation 레이어 테스트 (SearchViewModel 12개, Router 7개)
- [x] UI 테스트 (SearchFlowUITests 12개)

**완료 기준:** 시뮬레이터에서 검색→결과→WebView 플로우 동작 ✓

**2026-03-10 UI/UX 개선:**
- 검색 결과를 ResultListView에서 SearchView로 통합
- List → ScrollView + LazyVStack 변경
- 검색바 동적 레이아웃 (취소 버튼 빨간색)
- 최근 검색어 아이콘 제거, X 버튼으로 개별 삭제

### Phase 4 – 테스트 및 리팩터링 ✅ 완료

- [x] Domain 테스트
  - [x] RecentSearchUseCase 테스트 (15개)
  - [x] SearchRepositoriesUseCase 테스트 (12개, Mock Repository 사용)
- [x] Data 테스트
  - [x] UserDefaultsRecentSearchStore 테스트 (8개)
  - [x] InMemoryRecentSearchStore 테스트
  - [x] GitHubAPIClient 테스트 (15개, URLProtocol Mock)
  - [x] GitHubDTOs 테스트 (9개)
  - [x] GitHubRepositoryRepositoryImpl 테스트 (6개)
- [x] Presentation 테스트
  - [x] SearchViewModel 테스트 (16개)
  - [x] AppRouter 테스트 (6개)
- [x] UI 테스트
  - [x] SearchFlowUITests (12개)
- [x] 에러 시나리오 테스트
  - [x] 네트워크 실패
  - [x] Rate Limit (429) 응답
  - [x] 빈 결과
  - [x] 잘못된 JSON 응답

**완료 기준:** 핵심 기능 테스트 커버리지 80% 이상 ✓
- 총 76개 테스트 (단위 64개 + UI 12개)
- Domain Layer: 100%
- Data Layer: 100%
- Presentation Layer: 80-90%

### Phase 5 – 추가 구현 (선택) ✅ 완료

- [x] 자동완성 기능 (최근 검색어 기반)
- [x] 스크롤 중 Next Page 미리 호출 (마지막 3개 아이템에서 로드)
- [x] Pull-to-refresh
- [x] 결과 총 개수 표시 (애니메이션 미적용)

## 5. 에러 처리 전략

| 에러 타입 | 발생 상황 | 화면 표시 | 동작 |
|:---|:---|:---|:---|
| `emptyQuery` | 검색어가 비어있음 | 검색 필드 하단 "검색어를 입력해주세요" | 검색 미실행 |
| `network` | 네트워크 연결 실패 | 화면 중앙 "인터넷 연결을 확인해 주세요" + 재시도 버튼 | 수동 재시도 |
| `rateLimit` | 429 응답 | 화면 중앙 "잠시 후 다시 시도해 주세요" | 60초 타이머 표시 |
| `invalidResponse` | 401, 403, 503 등 | 화면 중앙 "오류가 발생했습니다" + 재시도 버튼 | 수동 재시도 |
| `decoding` | JSON 파싱 실패 | 화면 중앙 "데이터를 불러올 수 없습니다" | 수동 재시도 |
| `emptyResult` | 검색 결과 0개 | 화면 중앙 "검색 결과가 없습니다" | - |

## 6. 프로젝트 상태 요약

| 항목 | 상태 | 비고 |
|:---|:---|:---|
| **전체 Phase** | ✅ 완료 | 1~4 Phase + UI/UX 개선 |
| **총 테스트** | 76개 | 단위 64개 + UI 12개 |
| **핵심 기능** | ✅ 완료 | 검색, 페이지네이션, 최근 검색어, WebView |
| **남은 작업** | 0개 | 모두 완료 |

### 완료된 주요 기능
- ✅ GitHub 저장소 검색 (async/await)
- ✅ 페이지네이션 (ScrollView + LazyVStack, 미리 로드)
- ✅ 최근 검색어 저장/표시/삭제 (UserDefaults)
- ✅ WebView 상세 보기 (SafariViewController 래퍼)
- ✅ 로딩/에러/빈 상태 UI
- ✅ 전 계층 테스트 커버리지 80%+

### 남은 선택 기능 (Phase 5)
- 🔄 자동완성 기능 (최근 검색어 기반)
- 🔄 Pull-to-refresh

---

## 7. AI Assist 사용 전략

- 설계 단계:
  - ARCHITECT.md + 이 문서를 기반으로 아키텍처 검토/보완 요청
- 구현 단계:
  - DEV_TASKS.md의 Phase별 항목을 기준으로, 한 번에 1~2 파일 단위로 코드 생성 요청
  - "지금은 Developer 역할이야"로 시작하여 구현 요청
- 코드 리뷰 단계:
  - "지금은 Reviewer 역할이야"로 시작하여 CODE_REVIEW_AND_TESTING.md 기준 리뷰 요청
- 테스트 단계:
  - "지금은 Tester 역할이야"로 시작하여 부족한 테스트 보완 요청

(이 문서는 개발하면서 자유롭게 수정/추가)
