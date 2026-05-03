# [기능명]

> 작성일: yyyy-mm-dd
> 통합 브랜치 (integration): `feat/PROJ-1`  <!-- 색션 sub-branch들의 stack base. 색션 1개면 이 브랜치 자체가 PR head -->
> 머지 대상 (merge target): `main`           <!-- 통합 브랜치를 최종 머지할 곳. 단일 색션 PR의 `--base`이기도 함 -->
> 지라: [PROJ-1](https://your-org.atlassian.net/browse/PROJ-1)
> 상태: drafting | reviewed | in-progress | done

전체 상태값과 갱신 책임:

| 값 | 의미 | 갱신 주체 / 시점 |
|----|------|------------------|
| `drafting` | plan 작성 중 | `startPlan` 스킬 — 최초 생성 시 |
| `reviewed` | 리뷰 통과 | `review` 스킬(plan 모드) — Critical/Major 0건일 때 |
| `in-progress` | 색션 구현 중 | `execute` 스킬 — 첫 색션을 `in-progress`로 옮길 때 |
| `done` | 모든 색션 merged | `execute` 스킬 Step 3-2의 머지 동기화에서 마지막 색션이 `merged`로 전이될 때 |

---

## 요구사항

### 문제 정의 / 배경
- 

### 핵심 동작
1. 
2. 

### 비즈니스 규칙
- 

### 비기능 요구사항
해당 항목만 채우고 무관한 항목은 "해당 없음".

- **성능 / 응답 시간**: 
- **동시성**: 
- **트랜잭션 경계**: 
- **데이터 정합성**: 
- **외부 연동 실패 정책**: 

### 예외 / 에지 케이스
| 상황 | 처리 방식 |
|------|-----------|
|      |           |

### 영향 범위
- 

### 권한 / 사용 범위
- 

### 제외 범위 (Out of Scope)
- 

### 미결 사항 (Open Issues)
- 

---

## 변경 파일 (코드 매핑)

### 신규
- `path/to/NewFile.kt` — [책임]

### 수정
- `path/to/ExistingFile.kt#methodName` — [수정 내용]

### 데이터 모델 변경
해당 없으면 "해당 없음".

- **엔티티/테이블**: 
- **컬럼 변경**: 
- **인덱스**: 
- **마이그레이션 / 하위 호환**: 

---

## 색션 (= PR 단위)

각 색션은 단독 빌드/테스트 통과 가능해야 합니다 (revertable).

### 색션 1: [요약] → 브랜치 `feat/PROJ-1-1`

**목표**: 

**작업 항목**
- [ ] `path/File.kt#method` — [무엇을]
- [ ] 

**테스트**
- 단위: 
- 통합: 

**배포 안전성 / 보안 체크**
- [ ] DB 변경 하위 호환 (nullable / 기본값 / 단계적 배포)
- [ ] API 변경 하위 호환 (필드 추가는 안전, 제거는 Deprecated 단계)
- [ ] 새 엔드포인트 인증·인가
- [ ] 외부 입력 검증 (`@Valid` + Bean Validation)
- [ ] 권한 우회 가능 경로 차단

---

### 색션 2: [요약] → 브랜치 `feat/PROJ-1-2`

**의존**: 색션 1 머지 후 시작 / 또는 독립

**작업 항목**
- [ ] 

**테스트**
- 

**배포 안전성 / 보안 체크**
- [ ] 

---

## 진행 상태

색션 상태값: `pending` → `in-progress` → `done`(구현·테스트 통과) → `pr-open`(PR 생성됨, 머지 전) → `merged`.

| 색션 | 브랜치 | 상태 | PR |
|------|--------|------|-----|
| 1    | feat/PROJ-1-1 | pending | - |
| 2    | feat/PROJ-1-2 | pending | - |

---

## 리뷰 결과

<!-- review 스킬이 채움. 메인 스레드는 이 섹션을 보지 않고 review 스킬에 위임. -->
