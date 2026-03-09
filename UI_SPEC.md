# UI Spec – GitHubSearch iOS

## 1. 공통 사항

- 플랫폼: iOS 17+, SwiftUI
- 공통 스타일:
  - 시스템 폰트 사용
  - 시스템 컬러 우선 사용
  - 기본 padding 16pt 기준

## 2. 화면 목록

1. 검색 화면 (Search Screen)
2. 검색 결과 / 상세 화면 (Result & Detail Screen)

## 3. 검색 화면 UI

이 화면은 과제 문서에 제공된 "검색 화면 예시 이미지"를 기본 레이아웃으로 하되,  
아래 텍스트 스펙을 기준으로 구현한다.

### 3.1 레이아웃 구조

1. 상단 영역
   - 검색어 입력 필드
     - Placeholder: "검색어를 입력하세요" (과제에서 제시한 문구가 있다면 그 문구 사용)
     - 키보드 Return / 검색 버튼 탭 시 검색 실행
   - (옵션) 검색 버튼
     - Label: "검색"

2. 최근 검색어 영역 (검색 전이거나, 최근 검색어가 존재할 때)
   - 섹션 제목: "최근 검색어"
   - 최근 검색어 목록
     - 최대 10개까지 표시
     - 정렬: 검색 시점 기준으로 최신 순 (가장 최근 검색이 위)
     - 각 항목:
       - 검색어 텍스트
       - (추가 구현 기준) 검색 날짜 표시 (예: yyyy.MM.dd)
       - 우측에 개별 삭제 버튼 (아이콘: xmark 형태 등)
   - 전체 삭제
     - 목록 상단 우측에 "모두 지우기" 버튼

3. 상태 영역
   - 초기 상태:
     - 아직 검색을 수행하지 않은 경우, "검색어를 입력하고 검색을 시작하세요." 와 같은 안내 문구 표시 (과제 문구에 맞게 조정)
   - 로딩 상태:
     - 검색 결과를 최초로 불러오는 동안 화면 중앙에 로딩 인디케이터(ProgressView) 표시
     - 배경은 흰색/투명, ProgressView는 중앙 정렬
   - 에러 상태:
     - 에러 타입별로 다른 메시지와 액션 표시 (상세 내용은 "5. 에러 상태 정의" 참고)
   - 빈 결과:
     - 검색 후 결과가 0개일 때 "검색 결과가 없습니다." 와 같은 문구 표시
     - 중앙 정렬, 보조 색상 사용

### 3.2 동작 스펙

- 검색 실행
  - 검색어가 빈 문자열이면 검색을 수행하지 않는다.
  - 유효한 검색어 입력 후 Return/검색 버튼:
    - GitHub 검색 API 호출
    - 최근 검색어 목록에 추가
    - 결과 화면(결과 리스트 영역)으로 전환

- 최근 검색어 추가/삭제
  - 검색 성공 시:
    - 기존 목록에서 동일 검색어가 있으면 제거 후 맨 앞에 삽입
    - 최대 10개까지만 유지 (11개 이상이면 가장 오래된 항목 제거)
    - 저장 시점의 Date를 함께 보관 (정렬/표시 용도)
  - 최근 검색어 탭:
    - 해당 검색어를 검색 필드에 세팅
    - 즉시 검색 실행
  - 개별 삭제 버튼:
    - 해당 검색어만 목록에서 제거
  - "모두 지우기" 버튼:
    - 최근 검색어 목록 전체 삭제

---

## 4. 검색 결과 / 상세 화면 UI

이 화면은 과제 문서의 "검색 결과 예시 이미지"를 기본 레이아웃으로 하되,  
아래 텍스트 스펙을 기준으로 구현한다.

### 4.1 검색 결과 리스트

1. 상단 정보
   - (옵션) "총 N개" 형식의 검색 결과 수 표시
     - 예: "총 123개"

2. 결과 리스트
   - SwiftUI List 또는 ScrollView + LazyVStack 구성
   - 각 셀의 구성:
     - 왼쪽: Owner Avatar 이미지
       - URL: owner.avatar_url
       - 크기: 40x40 pt
       - 모양: 원형 (clipShape(Circle()))
       - 구현: AsyncImage 사용 (상세 내용은 "6. 이미지 로딩 스펙" 참고)
       - Placeholder: 회색 원형 또는 ProgressView
       - 에러: person.circle.fill 아이콘 (회색)
     - 오른쪽: 두 줄 텍스트
       - 1줄: 저장소 이름 (response.name)
         - 폰트: headline 정도
       - 2줄: Owner 이름/아이디 (owner.login)
         - 폰트: subheadline, 보조 색상 사용

3. 페이지네이션
   - GitHub Search API의 page 파라미터를 사용
   - 리스트의 특정 지점(예: 끝에서 5번째 셀)에 도달하면 다음 페이지 자동 로드
   - 추가 페이지 로딩 중에는 리스트 하단에 로딩 인디케이터(작은 ProgressView)를 표시

### 4.2 저장소 상세 (WebView 화면)

1. 화면 구조
   - NavigationStack 기반 네비게이션
   - Navigation Bar Title:
     - 저장소 이름 또는 "Repository" 중 하나 선택
   - 본문:
     - GitHub 저장소 상세를 표시하는 WebView
     - URL: html_url

2. 네비게이션 동작
   - 검색 결과 셀 탭:
     - AppRouter를 통해 `AppRoute.repositoryDetail(url: URL)` 로 이동
   - 뒤로가기:
     - NavigationBar 기본 Back 버튼으로 검색 결과로 복귀

### 4.3 상태/에러

- 결과 로딩 중:
  - 첫 페이지 로딩:
    - 검색 화면에서 처리 (3.2 로딩 상태 참고)
  - 추가 페이지 로딩:
    - 리스트 하단 로딩 표시만 사용

- 에러:
  - 네트워크/디코딩 에러 등 발생 시:
    - 에러 타입별로 정의된 UI/액션 표시 (상세 내용은 "5. 에러 상태 정의" 참고)

---

## 5. 에러 상태 정의

| 에러 타입 | 발생 상황 | 화면 표시 | 사용자 액션 | 구현 위치 |
|:---|:---|:---|:---|:---|
| **emptyQuery** | 검색어가 비어있을 때 | 입력 필드 하단에 빨간색 문구 "검색어를 입력해주세요" | 재입력 | SearchView |
| **network** | 네트워크 연결 실패 (WiFi/셀룰러 끊김) | 화면 중앙에 아이콘 + "인터넷 연결을 확인해 주세요" + 재시도 버튼 | 수동 재시도 | SearchView, ResultListView |
| **rateLimit** | GitHub API 429 응답 | 화면 중앙에 아이콘 + "잠시 후 다시 시도해 주세요" + 남은 시간 표시 | 자동 해제 대기 | SearchView, ResultListView |
| **invalidResponse** | 401, 403, 503 등 기타 HTTP 에러 | 화면 중앙에 아이콘 + "오류가 발생했습니다" + 재시도 버튼 | 수동 재시도 | SearchView, ResultListView |
| **decoding** | JSON 파싱 실패 | 화면 중앙에 아이콘 + "데이터를 불러올 수 없습니다" + 재시도 버튼 | 수동 재시도 | SearchView, ResultListView |
| **emptyResult** | 검색 결과 0개 | 화면 중앙에 돋보기 아이콘 + "검색 결과가 없습니다" | - | ResultListView |

### 5.1 에러 화면 공통 스펙

**레이아웃:**
- 전체 화면 중앙 정렬 (VStack)
- 아이콘: SF Symbols 사용 (systemName)
  - network: "wifi.slash" 또는 "exclamationmark.triangle"
  - rateLimit: "clock.arrow.circlepath"
  - emptyResult: "magnifyingglass"
  - 기타: "exclamationmark.circle"
- 메시지: headline 폰트, 기본 색상
- 재시도 버튼: "다시 시도" 레이블, primary 스타일
- 상하 여백: 기본 40pt 이상

**인터랙션:**
- 재시도 버튼 탭: 이전 검색어로 API 재호출
- 당겨서 새로고침 (Pull-to-refresh): ResultListView에서만 지원 (선택사항)

### 5.2 Rate Limit 특수 처리

**남은 시간 표시:**
```
"잠시 후 다시 시도해 주세요 (남은 시간: 45초)"
```
- 1초마다 타이머 업데이트
- 0초 되면 자동으로 재시도 버튼 활성화

---

## 6. 이미지 로딩 스펙

### 6.1 Owner Avatar 이미지

**사용 컴포넌트:** `AsyncImage` (iOS 15+ 기본 제공)

**스펙:**
```swift
AsyncImage(url: avatarURL) { phase in
    switch phase {
    case .empty:
        // 로딩 중: ProgressView 또는 회색 원형
    case .success(let image):
        // 성공: 이미지 표시
    case .failure:
        // 실패: 기본 아이콘 (person.circle.fill)
    @unknown default:
        EmptyView()
    }
}
```

**사이즈 및 스타일:**
- 크기: 40x40 pt
- 모양: 원형 (`.clipShape(Circle())`)
- 테두리: 선택적 (1pt 회색 테두리)

**Placeholder (로딩 중):**
- 회색 원형 (`Color.gray.opacity(0.3)`)
- 또는 작은 ProgressView

**에러 상태:**
- `person.circle.fill` SF Symbol 사용
- 회색 틴트 (`Color.gray`)

### 6.2 이미지 캐싱

**정책:** URLCache.shared 기본 사용 (별도 설정 없이 SwiftUI 기본값)
- 메모리 캐싱: 자동
- 디스크 캐싱: 자동
- 캐싱 정책: `.returnCacheDataElseLoad`

**커스텀 필요 시:**
```swift
// 향후 필요시 다음과 같이 설정
URLCache.shared = URLCache(
    memoryCapacity: 50 * 1024 * 1024,      // 50MB
    diskCapacity: 100 * 1024 * 1024,       // 100MB
    directory: cacheDirectory
)
```

### 6.3 WebView 이미지

**WebView 내 이미지:**
- GitHub 저장소 페이지 내 이미지는 WKWebView가 자동 처리
- 별도 캐싱 설정 불필요

---

## 7. 상태 관리 흐름

### 7.1 검색 화면 상태 전환

```
[초기 상태]
    ↓ (검색어 입력 + Return)
[로딩 상태] → ProgressView 표시
    ↓ (API 성공)
[결과 화면 이동] → Router 통해 ResultListView 표시
    ↓ (API 실패)
[에러 상태] → 에러 메시지 + 재시도 버튼
```

### 7.2 결과 화면 상태 전환

```
[결과 로딩]
    ↓ (결과 있음)
[리스트 표시] → 셀 표시 + 페이지네이션
    ↓ (결과 없음)
[빈 결과 상태] → "검색 결과가 없습니다"
    ↓ (API 실패)
[에러 상태] → 에러 타입별 메시지
```

