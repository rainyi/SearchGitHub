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

## Phase 4 – 테스트 / 리팩터링

- [ ] `Tests/DomainTests/RecentSearchUseCaseTests.swift` 작성
- [ ] `Tests/DataTests/UserDefaultsRecentSearchStoreTests.swift` 작성
- [ ] (선택) `Tests/PresentationTests/SearchViewModelTests.swift` 작성
- [ ] 전체 코드 리팩터링 및 불필요 코드 제거
- [ ] README.md, AI_ASSIST.md 업데이트

---

## Developer 역할에게 요청할 것 (Claude용 안내)

- 내가 특정 항목(예: Phase 1의 앞 두 개)을 지정하면:
  - 해당 파일들의 전체 코드를 제안해 달라.
  - DEV_TASKS.md에서 완료한 항목을 표시할 수 있도록,  
    “어떤 항목이 완료되었는지”를 답변 끝에서 다시 언급해 달라.
- 한 번에 너무 많은 항목을 처리하지 말고, 1~2개씩 진행한다.
- 구현이 끝난 Phase에 대해서는:
  - 코드 리뷰: CODE_REVIEW_AND_TESTING.md 의 코드 리뷰 기준으로 Reviewer 역할에게 리뷰를 요청한다.
  - 테스트: CODE_REVIEW_AND_TESTING.md 의 테스트 전략을 기준으로 Tester 역할에게 테스트 보완을 요청한다.

