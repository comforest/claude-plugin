---
name: pr
description: >
  `execute`로 완료된 plan 색션을 sub-branch(`feat/PROJ-1-N`)로 분기해 PR을 생성합니다.
  베이스 브랜치명(`feat/PROJ-1`)에서 지라 키를 추출해 PR 본문에 자동으로 지라 링크를 포함합니다.
  생성된 PR 번호/URL은 plan 계획서의 진행 상태 표에 기록되어 다음 세션에서도 추적 가능합니다.
  "PR 만들어줘", "pr", "올려줘", "PR 올려줘", "이 색션 PR 생성"
  같은 요청에 이 스킬을 사용하세요. 코드 리뷰 반영은 `pr-review`, fork→upstream은 `pr-upstream` 별도.
---

# pr — Sub-branch + PR 생성 스킬

`execute`가 끝낸 색션을 GitHub PR로 올립니다. 색션 = PR이라는 1:1 매핑을 유지합니다.

전제: 현재 브랜치는 plan의 베이스 브랜치(예: `feat/PROJ-1`), 색션의 변경사항이 워킹 트리에 있거나 이미 베이스 브랜치에 커밋되어 있음.

---

## Step 1. plan과 색션 식별

`docs/`에서 plan 파일을 식별 (사용자 명시 우선, 없으면 가장 최근). `Read`로 로드.

PR 생성 대상 색션 결정:
- 진행 상태 표에서 `done`인데 `PR` 칸이 비어 있는 색션 — 가장 작은 번호.
- 사용자가 명시했으면 그것 우선.
- 후보가 없으면 "먼저 `execute`로 색션을 완료해주세요" 안내 후 중단.

색션의 작업 항목이 모두 `[x]`인지 다시 확인. 누락된 `[ ]`이 있으면 사용자에게 알리고 진행 여부 확인.

---

## Step 2. 메타 추출 (브랜치명 기반)

```bash
BASE_BRANCH=$(git branch --show-current)
```

지라 키 추출 — 베이스 브랜치명에서 `[A-Z]+-[0-9]+` 패턴:

```bash
JIRA_KEY=$(echo "$BASE_BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1)
```

추출 실패 시 plan 메타에서 `지라:` 항목을 파싱하거나 사용자에게 직접 입력 요청.

지라 도메인은 plan 메타 헤더에서 가져옵니다 (예: `https://your-org.atlassian.net/browse/PROJ-1` 형태로 적혀 있음). 도메인만 추출:

```
JIRA_BASE_URL="https://your-org.atlassian.net/browse"
JIRA_LINK="${JIRA_BASE_URL}/${JIRA_KEY}"
```

---

## Step 3. Sub-branch 생성

색션 번호 결정 — 진행 상태 표에서 행 인덱스. 색션이 1개뿐이면 sub-branch 안 만들고 베이스 브랜치 그대로 사용 (다음 단계로).

여러 색션이면:

```bash
SUB_BRANCH="${BASE_BRANCH}-${SECTION_NUMBER}"   # 예: feat/PROJ-1-1
git checkout -b "$SUB_BRANCH"
```

이미 같은 이름의 브랜치가 있으면 사용자에게 알리고 어떻게 할지 묻습니다 (덮어쓰기 / 다른 번호).

---

## Step 4. 커밋 정리

워킹 트리에 변경이 있으면 커밋. `execute`가 마지막에 커밋했으면 이 단계는 skip.

```bash
git status
git diff --stat
```

색션의 변경 파일만 스테이징 (다른 색션 파일이 섞여 있지 않은지 확인):

```bash
git add <section files>
```

커밋 메시지는 Conventional Commits + 지라 키:

```bash
git commit -m "$(cat <<EOF
<type>(<scope>): <색션 요약>

<주요 작업 항목 1>
<주요 작업 항목 2>

Refs: ${JIRA_KEY}
EOF
)"
```

타입 가이드: `feat`(신규 기능), `fix`(버그), `refactor`(구조 개선), `perf`(성능), `test`(테스트만).

---

## Step 5. Push

```bash
git push -u origin "$SUB_BRANCH"
```

push 실패(권한·네트워크) 시 사용자에게 보고하고 중단 — 임의 우회하지 않음.

---

## Step 6. PR 생성

PR 본문 템플릿:

```bash
gh pr create \
  --base "$BASE_BRANCH" \
  --head "$SUB_BRANCH" \
  --title "<type>(<scope>): <색션 요약>" \
  --body "$(cat <<EOF
## 관련 이슈
[${JIRA_KEY}](${JIRA_LINK})

## 변경 사항
- <색션 작업 항목 1>
- <색션 작업 항목 2>

## 배포 안전성
- <DB 마이그레이션 / API 호환 / 롤링 배포 고려사항. plan 색션의 체크리스트 그대로>

## 테스트
- [x] 단위 테스트 통과 (\`./gradlew test\`)
- [x] 빌드 통과 (\`./gradlew build\`)
- [ ] 통합 테스트 (해당 시)

## 관련 계획서
\`docs/yyyy-mm-dd-{featName}.md\` — 색션 ${SECTION_NUMBER}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- `--base`는 plan의 베이스 브랜치. main이 아닐 수 있음 (stacked PR 흐름).
- 색션 1개뿐이라 sub-branch가 없는 경우, `--base`는 plan에서 정해둔 머지 대상(보통 `main` 또는 `develop`), `--head`는 베이스 브랜치 자체.
- 색션이 여러 개인데 사용자가 stacked가 아닌 일반 흐름(모두 main을 base)을 원하면 plan 메타에 명시했을 것 — 그 값을 따릅니다.

---

## Step 7. plan 진행 상태 표 갱신

PR URL/번호를 받아 plan md의 진행 상태 표에 기록:

```bash
PR_URL=$(gh pr view --json url -q .url)
PR_NUMBER=$(gh pr view --json number -q .number)
```

`Edit`로 plan md 수정 — 해당 색션 행의 `PR` 칸을 `#${PR_NUMBER}` 또는 URL로 갱신. 상태는 `done`에서 `pr-open`으로 바꿔도 됨 (선택).

---

## Step 8. 사용자 안내

```
색션 N PR 생성 완료: <PR URL>
- base: feat/PROJ-1
- head: feat/PROJ-1-N
- 지라: <JIRA_LINK>

다음 단계:
- 리뷰 후 머지 → 다음 색션을 `execute`로 진행
- 코드리뷰 코멘트가 달리면 `pr-review` 스킬로 반영
- fork → upstream PR이 필요하면 `pr-upstream`
```

---

## 주의사항

- **base는 절대 자동으로 main으로 바꾸지 않음**. plan 메타와 베이스 브랜치를 신뢰. 사용자가 main을 원했으면 plan에 그렇게 적혀 있어야 함.
- **다른 색션 파일 섞임 금지**: Step 4에서 `git diff --stat`로 색션 범위 외 파일이 있는지 반드시 확인. 있으면 사용자에게 보고.
- **force push 금지**: 신규 sub-branch라 force push가 필요할 일이 없음. 필요해 보이면 의심하고 사용자 확인.
- **리뷰어 자동 지정 금지**: CODEOWNERS가 있으면 GitHub가 알아서 처리. 사용자가 명시적으로 요청한 경우만 `gh pr edit --add-reviewer`.
- **CI 실패 시**: 보고만 하고 임의 수정하지 않음. 색션 안의 문제면 추가 커밋, 색션 외 문제면 사용자 결정.
