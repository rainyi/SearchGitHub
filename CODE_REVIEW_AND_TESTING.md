# CODE_REVIEW & TESTING – GitHubSearch iOS

이 문서는 코드 리뷰와 테스트 전략을 정리합니다.  
Claude에게 "지금은 Reviewer 역할" 또는 "지금은 Tester 역할"이라고 말할 때 이 문서를 함께 보여줍니다.

---

## 1. 코드 리뷰 기준 (Reviewer 역할)

리뷰 시 다음 항목을 우선적으로 확인해 달라.

1. 아키텍처 / 의존 방향
   - View → ViewModel → UseCase → Repository → API/Storage 순서가 깨지지 않았는가
   - Presentation에서 Data 레이어 타입을 직접 참조하지 않는가

2. 책임 분리
   - ViewModel이 너무 비대해지지 않았는가
   - UseCase/Repository/Store에 둘 책임이 ViewModel에 섞여 있지 않은가

3. 에러 처리
   - AppError 사용이 일관적인가
   - 네트워크/디코딩 에러를 적절히 래핑했는가

4. 코드 스타일/가독성
   - 네이밍이 명확한가
   - 복잡한 메서드는 적절히 분리되어 있는가

리뷰 요청 예시 프롬프트:

> 지금은 Reviewer 역할이야.  
> 아래 파일들에 대해 CODE_REVIEW.md 기준으로 리뷰 코멘트를 달아줘.  
> 특히 아키텍처/의존 방향과 책임 분리를 우선으로 봐줘.

---

## 2. 자동 리뷰 (/simplify)

Reviewer 리뷰 완료 후 실행하는 자동 검증 단계.

**실행 방법:**
```
/simplify
```

**검증 항목:**
1. **재사용성** - 중복 코드, 추출 가능한 유틸리티
2. **품질** - redundant state, parameter sprawl, leaky abstractions
3. **효율성** - 불필요한 연산, 메모리 누수, 성능 병목

**처리 방식:**
- 3개의 병렬 Agent가 코드를 검토
- 발견된 문제점을 집계
- 사용자와 상의 후 수정 적용

---

## 3. 테스트 전략 (Tester 역할)

우선순위 높은 테스트 대상:

1. RecentSearchUseCase + RecentSearchStore
2. GitHubRepositoryRepositoryImpl (필요 시)
3. SearchViewModel의 핵심 로직(검색, 페이지네이션, 최근 검색어 반영)

테스트 스타일:

- XCTest 사용
- Given-When-Then 네이밍 및 구조 유지

테스트 요청 예시 프롬프트:

> 지금은 Tester 역할이야.
> RecentSearchUseCase와 UserDefaultsRecentSearchStore에 대해
> TESTING 섹션 기준으로 필요한 유닛 테스트 케이스를 정의하고,
> XCTest 코드 예제를 작성해줘.

---

## 4. 완료 기준 체크리스트

각 Phase 완료 전 확인해야 할 항목:

- [ ] **Developer** - 1~2 파일 단위 개발 완료
- [ ] **Reviewer** - Claude.md 기준 코드 리뷰 완료
- [ ] **/simplify** - 자동 리뷰 및 수정 완료
- [ ] **Tester** - 핵심 기능 테스트 작성 완료
- [ ] **AI_ASSIST.md** - 대화 내용 요약 기록 완료
- [ ] **커밋** - git commit 완료

**모든 항목 완료 후 다음 Phase로 진행**

---
