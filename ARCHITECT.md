# ARCHITECT – GitHubSearch iOS

이 문서는 아키텍처 설계/결정 사항을 정리하는 용도입니다.
Claude에게 "지금은 Architect 역할"이라고 말할 때 이 문서를 함께 보여줍니다.

---

## 1. 설계 목표

- 간결하지만 확장 가능한 구조 (과제 규모에 맞는 Clean Architecture)
- Presentation / Domain / Data 레이어 분리
- 테스트 가능한 구조 (UseCase/Store/Repository를 프로토콜로 추상화)
- 과제 규모에 적합한 수준의 추상화 (과도한 설계 지양)
- Router 패턴으로 네비게이션 로직 분리 (단순화된 구현)

---

## 2. 핵심 설계 결정

### 2.1 기술 스택

| 영역 | 선택 | 이유 |
|:---|:---|:---|
| UI 프레임워크 | SwiftUI | 과제 요구사항, iOS 17+ 타겟 |
| 아키텍처 | MVVM + Clean Architecture + Router | 과제 요구사항, 테스트 용이성 |
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
- 검색과 결과를 한