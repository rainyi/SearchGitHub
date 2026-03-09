# UI Spec – GitHubSearch iOS

## 1. 공통 사항

- 플랫폼: iOS 17+, SwiftUI
- 공통 스타일:
  - 시스템 폰트 사용
  - 시스템 컬러 우선 사용
  - 기본 padding 16pt 기준

## 2. 화면 목록

1. 검색 화면 (Search Screen) - 검색어 입력 + 최근 검색어 + 검색 결과 통합
2. 저장소 상세 화면 (Repository Detail Screen) - WebView

## 3. 검색 화면 UI

### 3.1 레이아웃 구조

1. **네비게이션 타이틀**
   - "Search"

2. **검색바**
   - 회색 배경의 검색 입력 영역 (HStack)
     - 좌측: 돋보기 아이콘 (`magnifyingglass`)
     - 중앙: 텍스트필드 (Placeholder: "저장소 검색")
     - 우측: X 버튼 (텍스트 있을 때만 표시) - 텍스트 초기화
   - 취소 버튼 (텍스트 입력 시 검색바 우측에 표시)
     - 레이블: "취소"
     - 색상: 빨간색 (`.red`)
     - 동작: 텍스트 초기화 + 키보드 내림
   - 검색 실행: 키보드 Return 키

3. **콘텐츠 영역** (조걸별 표시)

   #### A. 검색 전 - 최근 검색어 영역
   - 섹션 제목: "최근 검색"
   - 최근 검색어 목록 (최대 10개, 최신순)
   - 각 항목:
     - 검색어 텍스트 (좌측 정렬)
     - 검색 시점 (상대 시간, 예: "3분 전")
     - X 버튼 (우측) - 해당 검색어만 삭제
   - 전체 삭제 버튼: 목록 하단 우측에 빨간색으로 표시

   #### B. 검색 후 - 검색 결과 영역
   - 결과 헤더: "총 N개 결과"
   - 결과 리스트 (ScrollView + LazyVStack)
     - 각 셀: RepositoryListCell (아바타 + 저장소명 + Owner)
     - Divider로 구분
     - 셀 탭 시 WebView로 이동
   - 페이지네이션: 스크롤 시 자동 로드
     - 하단에 ProgressView 표시 (로딩 중)
   - Pull-to-Refresh 지원

   #### C. 상태 화면
   - 초기 상태: "검색어를 입력해주세요" 안내
   - 로딩 상태: ProgressView (중앙)
   - 빈 결과: "검색 결과가 없습니다"
   - 에러 상태: 에러 타입별 메시지 + 재시도 버튼

### 3.2 동작 스펙

#### 검색 실행
- 검색어가 빈 문자열이면 검색을 수행하지 않는다.
- 유효한 검색어 입력 후 Return 키:
  - GitHub 검색 API 호출
  - 최근 검색어 목록에 추가
  - 같은 화면에서 결과 영역으로 전환

#### 검색 결과 화면에서 X 버튼
- 검색어 초기화
- 결과 영역 숨기고 최근 검색어 영역 표시
- `hasSearched = false` 상태로 변경

#### 최근 검색어 관리
- 검색 성공 시:
  - 기존 목록에서 동일 검색어가 있으면 제거 후 맨 앞에 삽입
  - 최대 10개까지만 유지
  - 저장 시점의 Date를 함께 보관
- 최근 검색어 탭:
  - 해당 검색어로 즉시 검색 실행
  - 결과 영역 표시
- 개별 삭제 (X 버튼):
  - 해당 검색어만 목록에서 제거
- 전체 삭제:
  - 최근 검색어 목록 전체 삭제

---

## 4. 저장소 상세 화면 (WebView)

### 4.1 화면 구조
- NavigationStack 기반 네비게이션
- Navigation Bar Title: 저장소 이름
- 본문: WKWebView로 GitHub 저장소 페이지 표시

### 4.2 네비게이션 동작
- 검색 결과 셀 탭:
  - `AppRouter.showDetail(url:)` 호출
  - WebView 화면으로 이동
- 뒤로가기:
  - NavigationBar 기본 Back 버튼
  - 검색 화면으로 복귀

---

## 5. 검색 결과 셀 (RepositoryListCell)

### 5.1 레이아웃
- HStack 구성:
  - 좌측: Owner Avatar (40x40, 원형)
  - 중앙: 텍스트 정보 (VStack)
    - 저장소 이름 (headline)
    - Owner 이름 (subheadline, 보조 색상)
    - 설명 (선택사항, caption)
    - 별 개수 + 언어 (선택사항)

### 5.2 이미지 로딩
- **AsyncImage** 사용 (iOS 15+ 기본 제공)
- Placeholder: 회색 원형 또는 ProgressView
- 에러: `person.circle.fill` 아이콘 (회색)

---

## 6. 페이지네이션

### 6.1 트리거
- 리스트의 마지막 3개 아이템 중 하나가 보이면 다음 페이지 로드
- `onAppear`로 감지

### 6.2 로딩 상태
- 초기 로딩: `isSearching` → 화면 중앙 ProgressView
- 추가 로딩: `isLoadingMore` → 리스트 하단 ProgressView
- 별도 상태 관리로 인디케이터 정확히 표시

### 6.3 구현 방식
```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(Array(repositories.enumerated()), id: \.element.id) { index, repo in
            RepositoryListCell(repository: repo)
                .onAppear {
                    let thresholdIndex = repositories.count - 3
                    if index >= thresholdIndex {
                        // 다음 페이지 로드
                    }
                }
            Divider()
        }

        if isLoadingMore {
            ProgressView()
        }
    }
}
```

---

## 7. 에러 상태 정의

| 에러 타입 | 발생 상황 | 화면 표시 | 사용자 액션 | 구현 위치 |
|:---|:---|:---|:---|:---|
| **emptyQuery** | 검색어가 비어있을 때 | 입력 필드 하단에 빨간색 문구 | 재입력 | SearchView |
| **network** | 네트워크 연결 실패 | 화면 중앙 아이콘 + 메시지 + 재시도 버튼 | 수동 재시도 | SearchView |
| **rateLimit** | GitHub API 429 응답 | 화면 중앙 아이콘 + 남은 시간 표시 | 자동 해제 대기 | SearchView |
| **invalidResponse** | 401, 403, 503 등 | 화면 중앙 아이콘 + 메시지 + 재시도 버튼 | 수동 재시도 | SearchView |
| **decoding** | JSON 파싱 실패 | 화면 중앙 아이콘 + 메시지 + 재시도 버튼 | 수동 재시도 | SearchView |
| **emptyResult** | 검색 결과 0개 | 화면 중앙 돋보기 아이콘 + 메시지 | - | SearchView |

---

## 8. 상태 관리 흐름

### 8.1 검색 화면 상태 전환

```
[초기 상태] - 최근 검색어 표시
    ↓ (검색어 입력 + Return)
[로딩 상태] - ProgressView 표시
    ↓ (API 성공 + 결과 있음)
[결과 표시] - 같은 화면에서 결과 리스트 표시
    ↓ (X 버튼 탭)
[초기 상태] - 검색어 초기화, 최근 검색어 표시
```

### 8.2 네비게이션 흐름

```
[검색 화면] ←→ [WebView 상세 화면]
   ↓ 셀 탭
[WebView] - 저장소 페이지 표시
   ↓ Back 버튼
[검색 화면] - 이전 검색 결과 유지
```

---

## 9. 변경 이력

| 날짜 | 변경사항 | 이유 |
|:---|:---|:---|
| 2026-03-09 | ResultListView 제거, SearchView에 통합 | 사용자 경험 개선, 불필요한 화면 전환 제거 |
| 2026-03-09 | 취소 버튼 빨간색 적용 | 시각적 구분 강화 |
| 2026-03-09 | 최근 검색어 아이콘 제거 | UI 간소화 |
| 2026-03-09 | X 버튼 터치 영역 조정 | 오탭 방지 |
| 2026-03-09 | List → ScrollView + LazyVStack | 페이지네이션 로딩 문제 해결 |

---
