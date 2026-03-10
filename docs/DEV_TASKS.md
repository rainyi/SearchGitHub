# DEV_TASKS – GitHubSearch iOS

이 문서는 실제 구현 작업(TODO)을 정리하는 용도입니다.  
Claude에게 "지금은 Developer 역할"이라고 말할 때 이 문서를 함께 보여줍니다.

---

## 사용 방법

- 각 Phase별로 체크박스를 사용해 진행 상황을 관리한다.
- Claude에게는 항상 "지금은 Developer 역할" + 이 문서의 특정 섹션을 함께 보여준다.
- 한 번에 1~2 항목만 요청해서 작업 단위를 작게 유지한다.

---

## Phase 1 – Domain 레이어

- [ ] `Sources/Domain/Entities/GitHubRepository.swift` 생성
- [ ] `Sources/Domain/Entities/RecentSearchItem.swift` 생성
- [ ] `Sources/Domain/Errors/AppError.swift` 정의
- [ ] `Sources/Domain/Repositories/GitHubRepositoryRepository.swift` 인터페이스 정의
- [ ] `Sources/Domain/UseCases/SearchRepositoriesUseCase.swift` (프로토콜 + 구현)
- [ ] `Sources/Domain/UseCases/RecentSearchUseCase.swift` (프로토콜 + 구현)

---

## Phase 2 – Data 레이어

- [ ] `Sources/Data/API/GitHubDTOs.swift` (검색 응답 DTO, 매핑)
- [ ] `Sources/Data/API/GitHubAPIClient.swift` (async/await API 클라이언트)
- [ ] `Sources/Data/Repositories/GitHubRepositoryRepositoryImpl.swift` 구현
- [ ] `Sources/Data/Storage/RecentSearchStore.swift` 프로토콜 정의
- [ ] `Sources/Data/Storage/UserDefaultsRecentSearchStore.swift` 구현
- [ ] `Sources/Data/Storage/InMemoryRecentSearchStore.swift` 구현(테스트용)

---

## Phase 3 – Presentation 레이어

- [ ] `Sources/Presentation/AppNavigation/AppRoute.swift` 정의
- [ ] `Sources/Presentation/AppNavigation/AppRouter.swift` 구현
- [ ] `Sources/App/AppEnvironment.swift`에서 DI 구성
- [ ] `Sources/App/GitHubSearchApp.swift`에서 RootView + Router 연결
- [ ] `Sources/Presentation/Search/SearchViewModel.swift` 구현
- [ ] `Sources/Presentation/Search/SearchView.swift` 구현
- [ ] (필요 시) ResultListView / RepositoryWebView 구현

---

## Phase 1 – Domain 레이어 (테스트 포함) ✅ 완료

- [x] `Sources/Domain/Entities/GitHubRepository.swift` 생성
- [x] `Sources/Domain/Entities/RecentSearchItem.swift` 생성
- [x] `Sources/Domain/Errors/AppError.swift` 정의
- [x] `Sources/Domain/Repositories/GitHubRepositoryRepository.swift` 인터페이스 정의
- [x] `Sources/Domain/UseCases/SearchRepositoriesUseCase.swift` (프로토콜 + 구현)
- [x] `Sources/Domain/UseCases/RecentSearchUseCase.swift` (프로토콜 + 구현)
- [x] `Tests/DomainTests/RecentSearchUseCaseTests.swift` 작성 (15개 테스트)
- [x] `Tests/DomainTests/SearchRepositoriesUseCaseTests.swift` 작성 (12개 테스트)

## Phase 2 – Data 레이어 (테스트 포함) 🔄 진행 중

### Part 1: DTO + APIClient ✅ 완료
- [x] `Sources/Data/API/GitHubDTOs.swift` (검색 응답 DTO, 매핑)
- [x] `Sources/Data/API/GitHubAPIClient.swift` (async/await API 클라이언트)
- [x] `Tests/DataTests/MockURLProtocol.swift` (URLSession 테스트용 Mock)
- [x] `Tests/DataTests/GitHubAPIClientTests.swift` (15개 테스트)
- [x] `Tests/DataTests/GitHubDTOsTests.swift` (9개 테스트)

### Part 2: Repository + Store ✅ 완료
- [x] `Sources/Data/Repositories/GitHubRepositoryRepositoryImpl.swift` 구현
- [x] `Sources/Data/Storage/UserDefaultsRecentSearchStore.swift` 구현
- [x] `Sources/Data/Storage/InMemoryRecentSearchStore.swift` 구현(테스트용)
- [x] `Tests/DataTests/GitHubRepositoryRepositoryImplTests.swift` 작성 (6개 테스트)
- [x] `Tests/DataTests/UserDefaultsRecentSearchStoreTests.swift` 작성 (8개 테스트)

## Phase 3 – Presentation 레이어 (테스트 포함) ✅ 완료

- [x] `Sources/Presentation/Router/AppRoute.swift` 정의
- [x] `Sources/Presentation/Router/AppRouter.swift` 구현
- [x] `Sources/App/AppEnvironment.swift`에서 DI 구성
- [x] `Sources/App/GitHubSearchApp.swift`에서 RootView + Router 연결
- [x] `Sources/Presentation/Search/SearchViewModel.swift` 구현
- [x] `Sources/Presentation/Search/SearchView.swift` 구현
- [x] `Sources/Presentation/RepositoryDetail/RepositoryWebView.swift` 구현
- [x] `Sources/Presentation/Components/LoadingView.swift` 구현
- [x] `Sources/Presentation/Components/ErrorView.swift` 구현
- [x] `Sources/Presentation/Components/EmptyView.swift` 구현
- [x] `Tests/PresentationTests/SearchViewModelTests.swift` 작성 (12개 테스트)
- [x] `Tests/PresentationTests/AppRouterTests.swift` 작성 (7개 테스트)

### UI 테스트 (추가)

- [x] `Tests/UITests/SearchFlowUITests.swift` 작성 (12개 UI 테스트)
  - 검색 흐름 테스트 (검색어 입력 → 결과 표시 → 셀 탭 → WebView)
  - 최근 검색어 테스트 (저장 → 표시 → 탭 → 전체 삭제)
  - 뒤로 가기 버튼 테스트
  - Pull to Refresh 테스트
  - 빈 상태/빈 결과 테스트

**총 테스트: 76개 (단위 64개 + UI 12개)**

## Phase 4 – 마무리 ✅ 완료

- [x] 전체 코드 리팩터링 및 불필요 코드 제거
- [x] 커버리지 체크 (중요 로직 위주)
  - Domain Layer (UseCases): 100%
  - Data Layer (Repository): 100%
  - Presentation Layer (ViewModels): 80-90%
  - 총 64개 테스트 통과
- [x] README.md 최종 업데이트
- [x] AI_ASSIST.md 최종 업데이트
- [x] Phase 3 커밋 완료

## 2026-03-10 – UI/UX 개선 및 구조 변경 ✅ 완료

- [x] 검색 화면 UI 개선
  - [x] 네비게이션 타이틀 "Search"로 변경
  - [x] 검색바 동적 레이아웃 (텍스트 입력 시 취소 버튼 표시)
  - [x] 취소 버튼 빨간색 적용
  - [x] X 버튼으로 검색 결과 화면 → 검색 입력 화면 전환
- [x] 검색 결과 화면 통합
  - [x] ResultListView 제거, SearchView에 통합
  - [x] AppRouter.showResults() 메서드 제거
  - [x] SearchViewModel에 검색 결과 상태 추가 (repositories, totalCount, isLoadingMore)
- [x] 최근 검색어 UI 개선
  - [x] 시계 아이콘 제거
  - [x] 화살표 아이콘 제거
  - [x] X 버튼으로 개별 삭제
  - [x] 전체 삭제 버튼 목록 하단 우측에 배치
  - [x] X 버튼 터치 영역 축소 (16x16)하여 오탭 방지
- [x] 페이지네이션 개선
  - [x] List → ScrollView + LazyVStack 변경
  - [x] isSearching / isLoadingMore 상태 분리
  - [x] 마지막 3개 아이템에서 다음 페이지 로드
  - [x] 페이지네이션 로딩 이슈 수정
- [x] 관련 문서 업데이트
  - [x] AI_ASSIST.md 업데이트
  - [x] UI_SPEC.md 업데이트
  - [x] ARCHITECT.md 업데이트

---

## 워크플로우 프로세스 (Claude.md와 동일)

각 Phase는 다음 순서로 진행한다:

1. **Developer 역할** → 1~2 파일씩 개발
2. **Reviewer 역할** → CODE_REVIEW_AND_TESTING.md 기준 리뷰
3. **/simplify** → 재사용성/품질/효율성 자동 검증
4. **Tester 역할** → 테스트 코드 작성
5. **AI_ASSIST.md 업데이트** → 대화 내용 요약 기록

---

## Developer 역할에게 요청할 것 (Claude용 안내)

- 내가 특정 항목(예: Phase 1의 앞 두 개)을 지정하면:
  - 해당 파일들의 전체 코드를 제안해 달라.
  - DEV_TASKS.md에서 완료한 항목을 표시할 수 있도록,
    “어떤 항목이 완료되었는지”를 답변 끝에서 다시 언급해 달라.
- **한 번에 너무 많은 항목을 처리하지 말고, 1~2개씩 진행한다.**
- **개발-테스트-커밋 사이클:**
  1. Developer: 1~2 파일 개발
  2. Reviewer: 코드 리뷰
  3. /simplify: 자동 검증
  4. Tester: 해당 파일 단위 테스트 작성 (바로)
  5. 커밋: 테스트 포함하여 커밋
  6. AI_ASSIST.md: 세션 기록 업데이트
- **커버리지 체크:** 각 Phase 끝 또는 전체 마무리 시 (숫자 집착 금지, 중요 로직 확인용)

