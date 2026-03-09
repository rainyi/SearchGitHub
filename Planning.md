# Planning – GitHubSearch iOS

## 1. 프로젝트 개요

- 과제: 컬리 GitHub 저장소 검색 iOS 앱
- 목표:
  - GitHub 저장소 검색 기능 구현
  - 최근 검색어 저장/표시
  - 페이지네이션 및 WebView 상세 보기
  - AI Assist(ChatGPT, Claude, Gemini 등)를 활용한 설계/구현/리뷰

## 2. 요구사항 정리

### 2.1 기능 요구사항 (과제 명세 기준)

- 검색 화면
  - [필수] 검색어 입력 후 결과 표시
  - [필수] 빈 검색어 시 최근 검색어 10개 표시
  - [필수] 최근 검색어 날짜 기준 내림차순 정렬
  - [필수] 개별/전체 삭제 가능
  - [필수] 앱 재시작 시 유지
  - [필수] 최근 검색어 선택 시 결과 표시
  - [추가] 입력 시 자동완성 (최근 검색어 기반, 날짜 함께 표시)

- 검색 결과 화면
  - [필수] List 형태 결과
  - [필수] 총 결과 수 표시
  - [필수] 저장소 정보: Thumbnail(owner.avatar_url), Title(name), Description(owner.login)
  - [필수] 선택 시 WebView 이동
  - [추가] 스크롤 중간에 Next Page 미리 호출
  - [추가] 로딩 상태 표시

### 2.2 비기능 요구사항

- 아키텍처: Clean Architecture (Presentation / Domain / Data) + MVVM
- 언어/플랫폼: Swift 5.9, iOS 17+, SwiftUI
- 네비게이션: NavigationStack 직접 사용 (Router 패턴 미사용)
- 비동기: Swift Concurrency (async/await)
- 이미지: AsyncImage 사용 (3rd-party 라이브러리 미사용)
- 네트워크: URLSession 사용 (Alamofire 미사용)
- 테스트: 최소한 비즈니스 로직(UseCase/Store) 중심의 유닛 테스트

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

### Phase 1 – Domain 레이어

- [ ] Entities 정의 (GitHubRepository, RecentSearchItem)
- [ ] AppError 정의 (network, decoding, rateLimit, emptyQuery 등)
- [ ] Repository 인터페이스 정의
- [ ] UseCase 프로토콜 + 기본 구현 정의

**완료 기준:** Domain 레이어 단위 테스트 작성 가능

### Phase 2 – Data 레이어

- [ ] GitHub DTO 정의 및 매핑 (snake_case → camelCase)
- [ ] GitHubAPIClient 구현
  - [ ] URLSession configuration (timeout: 30s)
  - [ ] HTTP 상태 코드별 에러 매핑
  - [ ] Rate Limit 헤더 파싱 (X-RateLimit-Remaining, X-RateLimit-Reset)
- [ ] Repository 구현체 (GitHubRepositoryRepositoryImpl)
- [ ] RecentSearchStore 프로토콜 정의
- [ ] UserDefaultsRecentSearchStore 구현 (JSON 인코딩/디코딩)
- [ ] InMemoryRecentSearchStore 구현 (테스트용)

**완료 기준:** API 호출 및 저장소 CRUD 테스트 통과

### Phase 3 – Presentation 레이어

- [ ] SearchViewModel 구현
  - [ ] 검색어 입력 상태 관리
  - [ ] 최근 검색어 로드/추가/삭제
  - [ ] 검색 실행 및 결과 전달
- [ ] SearchView 구현
  - [ ] 검색어 입력 필드
  - [ ] 최근 검색어 리스트 (삭제/전체삭제)
  - [ ] NavigationLink to ResultList
- [ ] ResultListViewModel 구현
  - [ ] 검색 결과 상태 관리
  - [ ] 페이지네이션 로직
  - [ ] Pull-to-refresh
- [ ] ResultListView 구현
  - [ ] 결과 리스트 (AsyncImage thumbnail)
  - [ ] 총 결과 수 표시
  - [ ] 무한 스크롤
  - [ ] 셀 탭 시 WebView
- [ ] RepositoryDetailView (WebView) 구현
- [ ] LoadingView, ErrorView, EmptyView 컴포넌트

**완료 기준:** 시뮬레이터에서 검색→결과→WebView 플로우 동작

### Phase 4 – 테스트 및 리팩터링

- [ ] Domain 테스트
  - [ ] RecentSearchUseCase 테스트
  - [ ] SearchRepositoriesUseCase 테스트 (Mock Repository 사용)
- [ ] Data 테스트
  - [ ] UserDefaultsRecentSearchStore 테스트
  - [ ] InMemoryRecentSearchStore 테스트
  - [ ] GitHubAPIClient 테스트 (URLProtocol Mock)
- [ ] Presentation 테스트
  - [ ] SearchViewModel 테스트
  - [ ] ResultListViewModel 테스트
- [ ] 통합 테스트
  - [ ] 검색→결과→WebView 플로우 테스트
- [ ] 에러 시나리오 테스트
  - [ ] 네트워크 실패
  - [ ] Rate Limit (429) 응답
  - [ ] 빈 결과
  - [ ] 잘못된 JSON 응답

**완료 기준:** 핵심 기능 테스트 커버리지 80% 이상

### Phase 5 – 추가 구현 (선택)

- [ ] 자동완성 기능 (최근 검색어 기반)
- [ ] 스크롤 중 Next Page 미리 호출
- [ ] Pull-to-refresh
- [ ] 결과 총 개수 표시 애니메이션

## 5. 에러 처리 전략

| 에러 타입 | 발생 상황 | 화면 표시 | 동작 |
|:---|:---|:---|:---|
| `emptyQuery` | 검색어가 비어있음 | 검색 필드 하단 "검색어를 입력해주세요" | 검색 미실행 |
| `network` | 네트워크 연결 실패 | 화면 중앙 "인터넷 연결을 확인해 주세요" + 재시도 버튼 | 수동 재시도 |
| `rateLimit` | 429 응답 | 화면 중앙 "잠시 후 다시 시도해 주세요" | 60초 타이머 표시 |
| `invalidResponse` | 401, 403, 503 등 | 화면 중앙 "오류가 발생했습니다" + 재시도 버튼 | 수동 재시도 |
| `decoding` | JSON 파싱 실패 | 화면 중앙 "데이터를 불러올 수 없습니다" | 수동 재시도 |
| `emptyResult` | 검색 결과 0개 | 화면 중앙 "검색 결과가 없습니다" | - |

## 6. AI Assist 사용 전략

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
