# GitHubSearch iOS

컬리 사전 과제로 구현한 GitHub 저장소 검색 iOS 앱입니다.  
GitHub 저장소를 검색하고, 최근 검색어를 관리하며, 결과를 WebView로 확인할 수 있습니다.

---

## 1. 개요

- 과제: GitHub 저장소 검색 iOS 앱
- 플랫폼: iOS 17+
- 언어/프레임워크: Swift 5.9, SwiftUI
- 아키텍처: Clean Architecture (Presentation / Domain / Data) + MVVM + Router

---

## 2. 주요 기능

### 검색 화면

- 검색어 입력 후 GitHub 저장소 검색
- 최근 검색어 표시 (최대 개수 제한, 최신 순)
- 최근 검색어 개별 삭제 / 전체 삭제
- 앱 재시작 후에도 최근 검색어 유지
- 최근 검색어 탭 시 해당 검색어로 재검색
- (옵션) 자동완성 / 추천 검색어

### 검색 결과 / 상세

- 검색 결과 리스트 표시
- 각 셀에 저장소 이름, Owner 이름(아이디) 표시
- 리스트 스크롤 시 다음 페이지 자동 로드(페이지네이션)
- 셀 탭 시 GitHub 저장소를 WebView로 오픈

---

## 3. 프로젝트 구조

Sources/
  App/
    GitHubSearchApp.swift       // 앱 엔트리 포인트
    AppEnvironment.swift        // 의존성 주입 구성

  Presentation/
    AppNavigation/
      AppRoute.swift            // 화면 전환 목적지 정의
      AppRouter.swift           // NavigationPath 관리
    Search/
      SearchView.swift          // 검색 화면 UI
      SearchViewModel.swift     // 검색/최근 검색 상태 관리
    ResultList/
      ResultListView.swift      // (필요 시) 결과 전용 View
      ResultListViewModel.swift // (선택 사항)

  Domain/
    Entities/
      GitHubRepository.swift    // 저장소 도메인 모델
      RecentSearchItem.swift    // 최근 검색어 도메인 모델
    UseCases/
      SearchRepositoriesUseCase.swift
      RecentSearchUseCase.swift
    Errors/
      AppError.swift            // 공통 에러 타입
    Repositories/
      GitHubRepositoryRepository.swift

  Data/
    API/
      GitHubAPIClient.swift     // GitHub API 호출
      GitHubDTOs.swift          // API 응답 DTO 및 매핑
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

Presentation 계층:
- SwiftUI View, ViewModel, AppRouter를 포함한 UI 계층

Domain 계층:
- 비즈니스 로직(UseCase), 도메인 모델, Repository 인터페이스, 에러 정의

Data 계층:
- API 호출, DTO, Repository 구현체, 로컬 저장소(UserDefaults 등)

------------------------------------------------------------

## 4. 빌드 및 실행 방법

1. 리포지토리 클론

   git clone https://github.com/your-id/GitHubSearch-iOS.git
   cd GitHubSearch-iOS

2. Xcode로 열기

   - GitHubSearch.xcodeproj (또는 .xcworkspace)를 Xcode로 연다.
   - 타겟: GitHubSearch
   - iOS 17 시뮬레이터 또는 실제 기기 선택

3. 실행

   - ⌘ + R 로 빌드 및 실행

(추가 설정이 필요하다면 예: GitHub API rate limit 대응, 팀 서명 설정 등을 여기에 메모)

------------------------------------------------------------

## 5. 테스트

주요 테스트 대상:
- RecentSearchUseCase
- UserDefaultsRecentSearchStore
- (선택) SearchViewModel

실행 방법:
1. Xcode 상단 메뉴에서 Product > Test 선택
2. 또는 단축키 ⌘ + U 로 전체 테스트 실행

------------------------------------------------------------

## 6. 아키텍처 / 설계 메모

레이어 의존 방향:
- View -> ViewModel -> UseCase -> Repository -> API / Storage

네비게이션:
- SwiftUI NavigationStack + AppRouter(AppRoute + NavigationPath) 조합
- ViewModel은 네비게이션을 직접 다루지 않고,
  onSelectRepository 같은 콜백으로 이벤트만 전달

비즈니스 로직:
- 검색 로직: SearchRepositoriesUseCase
- 최근 검색 관리: RecentSearchUseCase + RecentSearchStore (UserDefaults 기반)

------------------------------------------------------------

## 7. AI Assist 활용

이 프로젝트에서는 ChatGPT / Claude / Gemini 등의 AI Assist를 다음과 같이 활용했습니다.

- 아키텍처 설계 논의
- DTO, Repository, UseCase, Store 초안 코드 생성
- ViewModel / 테스트 코드 템플릿 생성
- 코드 리뷰 및 리팩터링 아이디어 제안

구체적인 프롬프트와 AI의 기여 내용은 AI_ASSIST.md에 기록했습니다.
(AI_ASSIST.md를 아직 만들지 않았다면, 이 문장은 나중에 수정하거나 삭제해도 됩니다.)

------------------------------------------------------------

## 8. 향후 개선 아이디어

- 검색 결과 정렬 / 필터 기능 추가
- 즐겨찾기(Starred) 저장소 관리
- 더 풍부한 에러 / 빈 상태 UI
- 다국어(Localization) 지원

