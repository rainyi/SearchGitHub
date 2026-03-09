# AI Assist Log – GitHubSearch iOS

이 문서는 컬리 GitHub 검색 iOS 과제를 진행하면서  
ChatGPT / Claude / Gemini 등의 AI Assist를 어떻게 활용했는지 기록합니다.

---

## 2026-03-09 – 프로젝트 문서/아키텍처 기초 설계

- 사용 도구 / 역할  
  - Perplexity (Architect 역할처럼 사용)

- 목적  
  - 컬리 사전 과제 설명을 바탕으로  
    프로젝트 구조와 AI 활용 방식을 전체적으로 설계하고,  
    Claude.md / Planning.md / ARCHITECT.md / DEV_TASKS.md / README.md / UI_SPEC.md의 초안을 만든다.

- 주요 프롬프트 (요약)  
  - "과제 링크에 있는 요구사항을 기준으로,  
     Clean Architecture + MVVM + Router 기반 iOS 앱 구조를 잡고 싶다.  
     Claude.md와 기타 md 파일을 어떻게 만들고, 어떤 역할 분리(Architect/Developer/Reviewer/Tester)로  
     오케스트레이션하면 좋을지 구체적으로 정리해 달라."

- AI가 도와준 내용  
  - Presentation / Domain / Data 레이어 구조와 폴더 구조 제안  
  - Claude.md 초안 (역할, Router, 아키텍처 원칙 포함) 작성  
  - Planning.md, ARCHITECT.md, DEV_TASKS.md, CODE_REVIEW_AND_TESTING.md, README.md, UI_SPEC.md 템플릿 제공  
  - 단일 에이전트 오케스트레이션(Architect/Developer/Reviewer/Tester 역할 스위치) 전략 설명

- 내가 직접 결정/수정한 내용  
  - 실제 파일 이름: ARCHITECT.md, DEV_TASKS.md, CODE_REVIEW_AND_TESTING.md 등으로 확정  
  - Router는 풀 Coordinator가 아니라, NavigationStack 위의 얇은 AppRouter로 제한  
  - CODE_REVIEW와 TESTING은 한 파일(CODE_REVIEW_AND_TESTING.md)로 통합  
  - 과제 요구사항의 UI/기능 스펙을 기준으로  
    README와 UI_SPEC.md의 내용/섹션 구조를 내 스타일에 맞게 정리

- 관련 파일
  - Claude.md
  - Planning.md
  - ARCHITECT.md
  - DEV_TASKS.md
  - CODE_REVIEW_AND_TESTING.md
  - README.md
  - UI_SPEC.md

---

## 2026-03-09 – Architect 역할: 문서 검토 및 설계 결정

- 사용 도구 / 역할
  - Claude Code (Claude) / Architect 역할

- 목적
  - 과제 설명서와 기존 문서들 검토
  - 과한/부족한 설계 포인트 식별
  - Router 패턴 포함 여부 등 아키텍처 결정

- 주요 프롬프트 (실제)

  ```
  지금은 Architect 역할이야.
  컬리 GitHub 저장소 검색 iOS 사전과제를 진행하려고 해.

  https://forms.greetinghr.com/forms/ko/r/CWy0Sn3MJQ

  @Claude.md @Planning.md @ARCHITECT.md @UI_SPEC.md

  위 과제 설명과 문서들을 한 번에 검토해줘.
  -. 이 과제 규모에서 과하거나 부족한 설계 포인트가 있으면 정리해 주고,
  -. Domain / Data / Presentation 레이어별로 빠진 부분이 있다면 알려줘.
  -. ARCHITECT.md와 Planning.md를 어떻게 수정하면 더 명확해질지도 제안해줘.
  ```

- AI가 도와준 내용
  - 과한 설계: Router 패턴이 2개 화면에 과함하나 과제 특성상 유지 권장
  - 누락 포인트: GitHub API Rate Limit(429) 처리, 에러 상태 UI, 이미지 캐싱 전략 등
  - 레이어별 부족 부분: HTTP 상태 코드 처리, JSONDecoder 전략, Loading/Empty/Error 상태
  - 문서 수정 제안: 에러 처리 전략 테이블, Rate Limit 처리 문서화

- 내가 직접 결정/수정한 내용
  - Router 패턴: 제거 → 단순화하여 유지 (NavigationPath 래핑만)
    - 이유: "아키텍처 평가" 과제 특성상 패턴 이해를 보여주는 것이 유리
  - 3rd-party 라이브러리: 명시적 불사용 결정 (Alamofire, Kingfisher 등)
  - 에러 처리: 6가지 타입으로 세분화 (emptyQuery, network, rateLimit, emptyResult 등)
  - 문서 3종 업데이트: Claude.md, Planning.md, ARCHITECT.md 일괄 수정

- 추가 프롬프트 및 피드백

  ```
  Claude.md와 Planning.md 수정 버전을 작성해줘
  ```

  이후 Router 제거에 대한 재검토 요청:
  ```
  Router 패턴은 간단하게나마 넣어놓는 것이 좋지 않을까?
  ```

  → Claude가 단순화된 Router 설계안 제안, 이를 반영하여 문서 업데이트

- 관련 파일
  - Claude.md (수정)
  - Planning.md (수정)
  - ARCHITECT.md (수정)
  - AI_ASSIST.md (본 파일)

---

## 프롬프트 팁 및 학습

### 효과적이었던 프롬프트 패턴

1. 역할 명시: "지금은 Architect 역할이야"
   - Claude가 해당 역할 관점에서 대안 제시

2. 문서 참조: "@Claude.md @Planning.md ..."
   - 컨텍스트 제공으로 일관된 답변 유도

3. 구체적 요청: "어떻게 수정하면 더 명확해질지도 제안해줘"
   - 단순 검토가 아닌 개선 방향 제시 요청

4. 피드백 반영: "Router 패턴은 간단하게나마 넣어놓는 것이 좋지 않을까?"
   - 초안 검토 후 의견 제시하여 설계 개선

### AI 활용 효과

- 시간 절약: 문서 구조화 및 전문 용어 사용에 도움
- 누락 포인트 발견: Rate Limit 처리, 에러 상태 UI 등 놓친 부분 보완
- 일관성 유지: 3개 문서간 용어/구조 통일

### 설계 결정 변경 이력

| 항목 | 초안 | 최종 결정 | 근거 |
|:---|:---|:---|:---|
| Router 패턴 | 제거 권장 | 단순화하여 유지 | 아키텍처 평가 과제 특성 |
| 3rd-party | 미정의 | 명시적 불사용 | 기본기 평가, 과제 규모 |
| 이미지 로딩 | 미정의 | AsyncImage | Kingfisher 불필요 |
| HTTP 클라이언트 | 미정의 | URLSession | Alamofire 불필요 |

---

## 2026-03-09 – Architect 역할: UI_SPEC.md 업데이트

- 사용 도구 / 역할
  - Claude Code (Claude) / Architect 역할

- 목적
  - UI_SPEC.md에 에러 상태/이미지 로딩 섹션 추가
  - 개발 전 UI 스펙 완성

- 주요 프롬프트 (실제)

  ```
  AI Assist를 활용한 내용(프롬프트)이 전부는 아니더라도
  저의 프롬프트와 너의 답변 등이 AI_ASSIT.md에 기록되어야 합니다.
  ```

  ```
  UI_SPEC.md도 에러 상태/이미지 로딩 섹션 업데이트를 먼저 해야
  개발을 진행할 수 있지 않을까요?
  ```

- AI가 도와준 내용
  - UI_SPEC.md에 새로운 섹션 3개 추가:
    1. "5. 에러 상태 정의" - 6가지 에러 타입별 UI/액션 테이블
    2. "6. 이미지 로딩 스펙" - AsyncImage 사용법, 캐싱 정책
    3. "7. 상태 관리 흐름" - 화멸별 상태 전환 다이어그램
  - 기존 섹션 업데이트: 3.1 상태 영역, 4.1 결과 리스트 이미지 로딩 명시

- 내가 직접 결정/수정한 내용
  - 에러 상태 테이블 컬럼 정의 (에러 타입, 발생 상황, 화면 표시, 사용자 액션, 구현 위치)
  - SF Symbols 아이콘 선정 (wifi.slash, clock.arrow.circlepath, magnifyingglass 등)
  - AsyncImage placeholder/에러 상태 스펙 확정

- 관련 파일
  - UI_SPEC.md (수정)
  - AI_ASSIST.md (본 파일)

---

## 2026-03-09 – 추가 대화: MCP 도구 확인

- 사용 도구 / 역할
  - Claude Code / 일반 대화

- 목적
  - 사용 가능한 MCP 도구 확인

- 주요 프롬프트

  ```
  mcp list
  ```

- AI가 도와준 내용
  - 프로젝트의 MCP 서버 목록 확인:
    - playwright (브라우저 자동화)
    - chrome-devtools (Chrome DevTools 통합)
    - sequential-thinking (구조화된 추론)
    - context7 (문서 및 코드 컨텍스트)
    - XcodeBuildMCP (iOS/Xcode 빌드 도구)
    - filesystem (파일 시스템 작업)
    - iOSSimulator (iOS 시뮬레이터 제어)

- 확인 결과
  - XcodeBuildMCP: 시뮬레이터 빌드, 테스트, 스크린샷 등 iOS 개발에 활용 가능
  - sequential-thinking: 복잡한 설계 결정 시 활용됨
  - context7: 라이브러리 문서 조회에 활용 가능

---

## 2026-03-09 – Phase 1: Domain Layer 구현 (워크플로우 적용)

- 사용 도구 / 역할
  - Claude Code (Claude) / Developer → Reviewer → /simplify → Tester

- 목적
  - Phase 1 Domain Layer 구현 및 새로운 워크플로우 프로세스 적용

- 주요 프롬프트 (실제)

  Developer 역할:
  ```
  지금은 Developer 역할이야.
  Phase 1 Domain Layer를 구현해줘.
  - Entities: GitHubRepository, RecentSearchItem
  - Errors: AppError (6가지 에러 타입)
  - Repository Interfaces
  - UseCases
  ```

  Reviewer 역할:
  ```
  커밋을 하기 전에 개발한 내용 리뷰 및 검증이 필요하지 않나요?
  커밋을 하기 전에는 항상 코드리뷰 및 검증을 진행해야 하지 않나요?
  ```

  /simplify:
  ```
  (자동 실행)
  ```

- AI가 도와준 내용 (Developer)
  - GitHubRepository: Entity 정의, Preview 지원
  - RecentSearchItem: Entity + 정렬/중복제거/제한 비즈니스 로직
  - AppError: 6가지 에러 타입, Equatable, LocalizedError
  - Repository Interfaces: GitHubRepositoryRepository, RecentSearchStore
  - UseCases: SearchRepositoriesUseCase, RecentSearchUseCase

- 리뷰 내용 (Reviewer)
  - 발견된 문제점: RecentSearchStore 위치 오류 (Data → Domain)
  - 수정 사항: Store 인터페이스를 Domain/Repositories로 이동
  - 오타 수정: "입력핳거나" → "입력하거나"

- /simplify 검증 결과
  - 발견된 이슈:
    1. Untrimmed keyword passed to repository (Medium)
    2. Wrong error type for page validation (Medium)
    3. String-based error comparison (Medium)
    4. Duplicate lowercasing in closure (Low)
    5. Unused error enum (Low)
    6. timeIntervalSince(Date()) (Very Low)
  - 수정 사항:
    1. SearchRepositoriesUseCase: trimmedKeyword 저장 후 전달
    2. AppError: invalidParameter(String) 케이스 추가
    3. AppError.Equatable: NSError domain/code 비교로 변경
    4. RecentSearchUseCase: lowercased()를 closure 밖으로 이동
    5. RecentSearchStoreError: 미사용으로 제거
    6. AppError: timeIntervalSinceNow 사용 (negated)

- 테스트 내용 (Tester)
  - 작성된 테스트: (아직 진행하지 않음 - 다음 세션)
  - 테스트 커버리지: (예정)

- 내가 직접 결정/수정한 내용
  - 워크플로우 프로세스 정립: Developer→Reviewer→/simplify→Tester
  - 문서 4종 업데이트 (Claude.md, DEV_TASKS.md, CODE_REVIEW_AND_TESTING.md, AI_ASSIST.md)
  - 커밋 메시지 한글로 작성

- 관련 파일
  - Claude.md (워크플로우 추가)
  - DEV_TASKS.md (워크플로우 추가)
  - CODE_REVIEW_AND_TESTING.md (/simplify 단계 추가)
  - AI_ASSIST.md (템플릿 추가, 본 세션 기록)
  - Sources/Domain/Entities/GitHubRepository.swift
  - Sources/Domain/Entities/RecentSearchItem.swift
  - Sources/Domain/Errors/AppError.swift
  - Sources/Domain/Repositories/GitHubRepositoryRepository.swift
  - Sources/Domain/Repositories/RecentSearchStore.swift
  - Sources/Domain/UseCases/SearchRepositoriesUseCase.swift
  - Sources/Domain/UseCases/RecentSearchUseCase.swift

---

## 워크플로우 기록 템플릿

각 Phase 완료 시 다음 형식으로 기록:

```markdown
## YYYY-MM-DD – [Phase N]: [작업명]

- 사용 도구 / 역할
  - Claude Code (Claude) / Developer → Reviewer → Tester

- 목적
  - [해당 Phase의 목적]

- 주요 프롬프트 (실제)
  ```
  지금은 Developer 역할이야.
  [프롬프트 내용]
  ```

- AI가 도와준 내용 (Developer)
  - [구현 내용 요약]

- 리뷰 내용 (Reviewer)
  - 발견된 문제점: [있으면 기록]
  - 수정 사항: [있으면 기록]

- /simplify 검증 결과
  - 발견된 이슈: [있으면 기록]
  - 수정 사항: [있으면 기록]

- 테스트 내용 (Tester)
  - 작성된 테스트: [테스트 파일 목록]
  - 테스트 커버리지: [핵심 기능 커버리지]

- 내가 직접 결정/수정한 내용
  - [의사결정 사항]

- 관련 파일
  - [수정된 파일 목록]
```

---

---

## 2026-03-09 – Phase 1: Domain Layer 테스트 (Tester 역할)

- 사용 도구 / 역할
  - Claude Code (Claude) / Tester 역할

- 목적
  - Phase 1 Domain Layer 단위 테스트 작성

- 주요 프롬프트 (실제)

  ```
  테스트를 진행해주세요.
  ```

- AI가 도와준 내용 (Tester)
  - MockRecentSearchStore: 테스트용 InMemory Store 구현
  - RecentSearchUseCaseTests (15개 테스트):
    - getRecentSearches: 빈 배열, 최신순 정렬
    - addSearch: 빈 쿼리 무시, trimmed 저장, 중복 제거, 대소문자 무시, 최대 개수 제한, 맨 앞 삽입
    - deleteSearch: 존재하는 항목, 비존재 항목
    - clearAll: 전체 삭제
    - 에러 처리: Store 에러 전파
  - MockGitHubRepositoryRepository: 테스트용 Mock Repository
  - SearchRepositoriesUseCaseTests (12개 테스트):
    - 입력 검증: 빈 검색어, 공백만, 페이지 0, 음수 페이지
    - 성공 케이스: trimmed keyword 전달, 결과 반환, 페이지 번호 전달
    - 에러 전파: network, rateLimit
    - 엣지 케이스: 특수문자, 매우 긴 문자열

- 테스트 커버리지
  - RecentSearchUseCase: 핵심 비즈니스 로직 전체 커버
  - SearchRepositoriesUseCase: 입력 검증 및 에러 처리 전체 커버

- 관련 파일
  - Tests/DomainTests/MockRecentSearchStore.swift
  - Tests/DomainTests/RecentSearchUseCaseTests.swift
  - Tests/DomainTests/MockGitHubRepositoryRepository.swift
  - Tests/DomainTests/SearchRepositoriesUseCaseTests.swift

---

## 2026-03-09 – Phase 2: Data Layer (DTO + APIClient) 구현

- 사용 도구 / 역할
  - Claude Code (Claude) / Developer → Reviewer → /simplify → Tester

- 목적
  - Phase 2 Data Layer 중 DTO와 APIClient 구현

- 주요 프롬프트 (실제)

  Developer 역할:
  ```
  지금은 Developer 역할입니다. - Phase 2의 DTO + APIClient 먼저 구현해주세요.
  ```

  Reviewer 역할:
  ```
  지금은 Reviewer 역할입니다. 코드 리뷰 해주세요.
  ```

  /simplify:
  ```
  수정 후 /simplify 자동 검증을 진행해주세요.
  ```

  Tester 역할:
  ```
  단위 테스트를 작성해주세요.
  ```

- AI가 도와준 내용 (Developer)
  - GitHubDTOs.swift: GitHubSearchResponseDTO, GitHubRepositoryDTO, GitHubOwnerDTO 정의
  - CodingKeys로 snake_case → camelCase 매핑
  - toEntity(), toEntities() 메서드로 Domain Entity 변환
  - GitHubAPIClient.swift: 프로토콜 + actor 기본 구현
  - HTTP 상태 코드 처리 (401, 403, 429, 5xx)
  - Rate Limit 헤더 파싱 (X-RateLimit-Reset)

- 리뷰 내용 (Reviewer)
  - 발견된 문제점:
    1. `URLResponse() as! HTTPURLResponse` 강제 캐스팅 위험
    2. Rate Limit 파싱 로직 중복 (403, 429)
    3. `AppError.decoding`에 파라미터 전달 불일치
    4. baseURL 강제 언래핑
  - 수정 사항: guard let으로 안전한 캐스팅, 메서드 분리, 에러 타입 세분화

- /simplify 검증 결과
  - 발견된 이슈:
    1. JSONDecoder 매 요청마다 인스턴스 생성 (Medium)
    2. 중복 guard 구문 (Low)
    3. baseURL 강제 언래핑 (Low)
  - 수정 사항:
    1. `private let decoder: JSONDecoder`로 캐싱
    2. guard 구문 단순화 (components != nil 체크 제거)
    3. init에서 guard로 안전하게 baseURL 생성

- 테스트 내용 (Tester)
  - MockURLProtocol: URLSession 테스트를 위한 Mock 구현
  - GitHubAPIClientTests (15개 테스트):
    - 성공 케이스: 유효한 응답, 빈 결과
    - HTTP 상태: 401 unauthorized, 403 rateLimit/forbidden, 429 rateLimit
    - 서버 에러: 500, 503
    - 네트워크 에러 처리
    - 디코딩 에러 처리
    - 잘못된 URL 데이터 필터링
    - 요청 파라미터 검증
  - GitHubDTOsTests (9개 테스트):
    - toEntity 정상 변환
    - nil description/language 처리
    - invalid URL → nil 반환
    - toEntities 필터링
    - JSON 디코딩 (snake_case)

- 테스트 커버리지
  - GitHubAPIClient: 성공/실패 케이스, 모든 HTTP 에러 상태, 네트워크/디코딩 에러
  - DTO: Entity 변환, 유효성 검증, JSON 디코딩

- 내가 직접 결정/수정한 내용
  - AppError 확장: unauthorized, forbidden, serverError(Int) 추가
  - `case decoding(Error)`로 변경하여 원본 에러 보존
  - /simplify 검증 후 JSONDecoder 캐싱 적용

- 관련 파일
  - Sources/Data/API/GitHubDTOs.swift
  - Sources/Data/API/GitHubAPIClient.swift
  - Sources/Domain/Errors/AppError.swift (수정)
  - Tests/DataTests/MockURLProtocol.swift
  - Tests/DataTests/GitHubAPIClientTests.swift
  - Tests/DataTests/GitHubDTOsTests.swift

---

## 다음 세션 계획

- **Phase 2 (Data Layer) 완료** - 예정
  1. Developer: GitHubRepositoryRepositoryImpl, UserDefaultsRecentSearchStore
  2. Reviewer: 코드 리뷰
  3. /simplify: 자동 리뷰
  4. Tester: Data Layer 테스트 작성
  5. AI_ASSIST.md 업데이트
  6. 커밋
