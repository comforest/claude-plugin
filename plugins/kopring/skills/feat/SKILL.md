---
name: feat
description: >
  Spring Boot (JVM/Kotlin/Java) 프로젝트에서 새로운 기능을 추가하거나 기존 기능을 수정할 때 사용하는 스킬입니다.
  "기능 추가", "기능 수정", "feat:", "새 API", "엔드포인트 추가", "서비스 로직 변경", "implement", "새로운 기능 구현",
  "add endpoint", "modify service" 등의 요청에 반드시 이 스킬을 사용하세요.
  3단계 워크플로우(계획 → 구현 → PR)로 진행하며, 코드 컨벤션/배포 안전성/보안/효율을 체계적으로 검토합니다.
  Spring Boot 프로젝트에서 코드 변경이 수반되는 모든 작업에 이 스킬을 적극 활용하세요.
---

# feat — Spring Boot 기능 개발 스킬

Spring Boot (JVM) 프로젝트에서 기능을 추가하거나 수정할 때의 전체 워크플로우를 담당합니다.
**Phase 1 → Phase 2 → Phase 3** 순서로 진행하되, 각 Phase 시작 전에 현재 상황을 사용자에게 안내하세요.

---

## Phase 1: 작업 계획 수립

### 목표
기능 명세를 분석하여 `TODO.md`를 생성합니다. 두 개의 subagent가 플래너/리뷰어 역할을 맡아 계획의 품질을 높입니다.

### 절차

**Step 1. 명세 파악**
프롬프트에서 다음을 추출합니다:
- 구현할 기능의 핵심 목적
- 입출력 스펙 (API라면 Request/Response 형태)
- 영향 받는 레이어 (Controller / Service / Repository / Domain)
- 명확하지 않은 부분이 있으면 사용자에게 질문 후 진행

**Step 2. Planner agent 실행 (subagent)**

Planner에게 다음을 지시합니다:
```
당신은 Spring Boot 기능 개발의 작업 계획을 작성하는 Planner입니다.

[작업 목표]
<기능 명세>

[프로젝트 구조 분석]
- build.gradle(.kts) / pom.xml 의존성 확인
- 기존 코드 컨벤션 파악 (패키지 구조, 네이밍, 어노테이션 패턴)
- 관련 파일 탐색 (수정/생성 대상)

[검토 항목]
1. 코드 컨벤션: 프로젝트의 기존 패턴 준수 여부
2. 배포 안전성:
   - DB 스키마 변경 시 하위 호환성 (컬럼 추가 시 nullable, 기본값 처리)
   - API 변경 시 버전 관리 또는 하위 호환 전략
   - 롤링/카나리 배포 환경에서 구버전-신버전 공존 가능 여부
3. 보안: 인증/인가 처리, 입력 유효성 검사, SQL 인젝션/XSS 방지
4. 로직 효율: N+1 쿼리, 불필요한 DB 호출, 캐시 활용 가능성

[TODO.md 생성]
루트 디렉토리에 TODO.md를 아래 형식으로 작성하세요.
```

**Step 3. Reviewer agent 실행 (subagent)**

Planner가 TODO.md를 생성하면 Reviewer에게 지시합니다:
```
당신은 작업 계획을 검토하는 Reviewer입니다.
TODO.md를 읽고 다음을 점검하세요:

1. 누락된 파일/컴포넌트가 없는지
2. 배포 안전성 검토가 충분한지 (특히 DB 마이그레이션, API 하위 호환)
3. 보안 취약점이 간과된 부분은 없는지
4. 병렬 처리 가능한 작업이 순차로 잡혀 있지는 않은지
5. 커밋 분리 전략이 적절한지

검토 결과를 TODO.md의 "## 리뷰 피드백" 섹션에 추가하고,
수정이 필요한 항목은 구체적으로 기술하세요.
```

**Step 4. 계획 검토 루틴 반복**

작업 규모에 따라 Planner/Reviewer 사이클을 반복합니다:
- **소규모** (파일 1~3개, 단순 CRUD): 2회
- **중규모** (레이어 2개 이상 변경, 새 도메인 추가): 3회
- **대규모** (DB 스키마 변경 + API 추가 + 비즈니스 로직 복합): 4~5회

각 사이클에서 Planner는 피드백을 반영하여 TODO.md를 갱신하고, Reviewer는 재검토합니다.
최종 TODO.md에 "## 최종 검토 완료" 표시가 있으면 Phase 1 종료.

---

### TODO.md 형식

```markdown
# TODO: <기능명>

## 개요
- **목적**: 
- **영향 범위**: 
- **예상 작업 규모**: 소/중/대

## 배포 안전성 검토
- [ ] DB 변경 하위 호환성: <내용>
- [ ] API 하위 호환성: <내용>
- [ ] 롤링 배포 고려사항: <내용>

## 보안 검토
- [ ] 인증/인가: <내용>
- [ ] 입력 유효성: <내용>
- [ ] 기타: <내용>

## 작업 목록

### Commit 1: <커밋 제목> (작업이 클 경우 커밋 분리)
- [ ] 작업 항목 A
- [ ] 작업 항목 B
  - 병렬 가능: A와 동시 진행 가능

### Commit 2: <커밋 제목>
- [ ] 작업 항목 C
- [ ] 작업 항목 D

## 병렬 실행 가능 그룹
- **그룹 1**: 항목 A, B (서로 독립적)
- **그룹 2**: 항목 C, D (그룹 1 완료 후 시작)

## 리뷰 피드백
<!-- Reviewer가 작성 -->

## 최종 검토 완료
<!-- 모든 사이클 완료 후 Reviewer가 서명 -->
```

Phase 1이 완료되면 사용자에게 TODO.md를 확인하도록 안내하고, **Phase 2 진행 여부를 확인**합니다.

---

## Phase 2: 구현

### 목표
TODO.md에 정의된 작업을 실제로 수행합니다.

### 절차

**Step 1. TODO.md 로드**
TODO.md를 읽고 작업 목록과 병렬 그룹을 파악합니다.

**Step 2. 병렬 실행**
"병렬 실행 가능 그룹"에 묶인 항목은 subagent를 생성하여 동시에 진행합니다.
독립적인 파일(예: Controller와 Repository)은 같은 turn에 subagent로 분기합니다.

**Step 3. 구현 원칙**
- 기존 코드 컨벤션(패키지 구조, 네이밍, 어노테이션 스타일)을 반드시 따릅니다.
- TODO.md의 배포 안전성/보안 검토 항목을 구현 중에도 지속 확인합니다.
- 각 기능 단위가 완성되면 TODO.md에서 해당 항목을 `[x]`로 체크합니다.

**Step 4. 중간 커밋**
TODO.md의 "Commit N" 단위가 완성될 때마다 커밋을 진행합니다:
```bash
git add <관련 파일>
git commit -m "<type>(<scope>): <설명>

<변경 이유 및 배경>"
```
커밋 메시지는 Conventional Commits 형식을 따릅니다 (`feat`, `fix`, `refactor`, `test` 등).

**Step 5. 테스트**
구현 완료 후:
```bash
./gradlew test          # 전체 테스트 (macOS/Linux)
gradlew.bat test        # Windows
```
실패한 테스트가 있으면 수정 후 재실행합니다.

Phase 2가 완료되면 사용자에게 알리고, **Phase 3 진행 여부를 확인**합니다.

---

## Phase 3: 마무리 및 PR

### 절차

**Step 1. TODO.md 검증**
TODO.md를 읽고 미완료 항목(`[ ]`)이 있는지 확인합니다.
미완료 항목이 있으면 Phase 2로 돌아가 완료합니다.

**Step 2. 최종 빌드 확인**
```bash
./gradlew build    # macOS/Linux
gradlew.bat build  # Windows
```

**Step 3. TODO.md 삭제**
모든 항목이 완료되었으면 루트의 `TODO.md`를 삭제합니다.

**Step 4. PR 생성**
원격 저장소가 여러 개인 경우 `origin`에 push합니다:
```bash
git push origin <branch-name>
gh pr create \
  --title "<feat/fix>: <기능 요약>" \
  --body "$(cat <<'EOF'
## 변경 사항
<작업 내용 요약>

## 배포 고려사항
<DB 마이그레이션, API 하위 호환 등>

## 테스트
- [ ] 단위 테스트 통과
- [ ] 통합 테스트 통과

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

PR URL을 사용자에게 알려줍니다.

---

## 주의사항

- **배포 안전성 최우선**: DB 컬럼 추가 시 반드시 `nullable` 또는 `DEFAULT` 지정, API 필드 제거 시 Deprecated 단계 고려
- **보안 기본**: 모든 외부 입력에 `@Valid` + Bean Validation, Spring Security 인가 누락 금지
- **Windows 환경**: `./gradlew` 대신 `gradlew.bat` 사용
- **커밋 전 확인**: `git diff --staged`로 의도치 않은 변경 포함 여부 확인
