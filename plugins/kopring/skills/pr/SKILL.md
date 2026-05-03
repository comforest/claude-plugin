---
name: pr
description: >
  `execute`로 완료된 plan 색션을 sub-branch(`feat/PROJ-1-N`)로 분기해 PR을 생성합니다.
  통합 브랜치명(`feat/PROJ-1`)에서 지라 키를 추출해 PR 본문에 자동으로 지라 링크를 포함하고,
  생성된 PR 번호/URL은 plan 계획서의 진행 상태 표에 기록되어 다음 세션에서도 추적 가능합니다.
  사용자가 직접 호출하거나, 선행 스킬(`execute` 색션 완료)이 자동 체이닝으로 호출합니다.
  "PR 만들어줘", "올려줘", "PR 생성" 같은 자연어 발화도 매칭됩니다.
  PR 생성 후에는 자동 체인을 종료합니다 (다음 색션은 PR 머지가 외부 이벤트라 새 호출 필요).
  코드 리뷰 코멘트 반영은 별도의 `pr-review`, fork→upstream PR은 별도의 `pr-upstream` 스킬을 사용합니다.
---

# pr — Sub-branch + PR 생성 스킬

`execute`가 끝낸 색션을 GitHub PR로 올립니다. 색션 = PR이라는 1:1 매핑을 유지합니다.

전제: 현재 브랜치는 plan의 통합 브랜치(예: `feat/PROJ-1`), 색션의 변경사항이 워킹 트리에 있거나 이미 통합 브랜치에 커밋되어 있음.

---

## Step 1. plan과 색션 식별

`docs/`에서 plan 파일을 식별 (사용자 명시 우선, 없으면 가장 최근). `Read`로 한 번만 로드합니다 (이후 모든 메타 파싱은 메인이 이 결과로 처리 — 동일 파일을 여러 번 grep하지 않음).

PR 생성 대상 색션 결정:
- 진행 상태 표에서 `done`인데 `PR` 칸이 비어 있는 색션 — 가장 작은 번호.
- 사용자가 명시했으면 그것 우선.
- 후보가 없으면 "먼저 `execute`로 색션을 완료해주세요" 안내 후 중단.

색션의 작업 항목이 모두 `[x]`인지 다시 확인. 누락된 `[ ]`이 있으면 사용자에게 알리고 진행 여부 확인.

---

## Step 2. 메타 추출 (메인이 plan 본문에서 파싱)

Step 1에서 `Read`한 plan 본문에서 다음 4개 값을 메인이 직접 파싱합니다 (별도 grep 호출 X):

| 값 | 출처 | 예시 |
|----|------|------|
| `INTEGRATION_BRANCH` | 메타 헤더 `통합 브랜치 (integration)` 줄의 백틱 안 | `feat/PROJ-1` |
| `MERGE_TARGET` | 메타 헤더 `머지 대상 (merge target)` 줄의 백틱 안 | `main` |
| `JIRA_KEY` | `INTEGRATION_BRANCH`에서 `[A-Z]+-[0-9]+` 패턴 | `PROJ-1` |
| `JIRA_LINK` | 메타 헤더 `지라:` 줄의 마크다운 링크 URL | `https://your-org.atlassian.net/browse/PROJ-1` |

추출 실패 시(브랜치명에 지라 키가 없거나 메타 누락):
- `JIRA_KEY` 누락 → plan 메타의 `지라:` 마크다운 링크 텍스트(`[PROJ-1]`)에서 재시도, 그래도 없으면 사용자에게 직접 요청.
- 그 외 누락 → plan이 손상된 것이므로 사용자에게 보고하고 중단.

현재 체크아웃된 브랜치가 `INTEGRATION_BRANCH`와 다르면 사용자에게 보고하고 중단 — `pr`은 통합 브랜치 위에서만 동작.

---

## Step 3. PR head 결정 + sub-branch 생성

색션 번호는 진행 상태 표에서의 행 인덱스. 색션 개수에 따라 분기합니다:

| 케이스 | `BRANCH_TO_PUSH` | `PR_BASE` | `PR_HEAD` |
|--------|------------------|-----------|-----------|
| 색션 = 1 | `INTEGRATION_BRANCH` (sub-branch 안 만듦) | `MERGE_TARGET` | `INTEGRATION_BRANCH` |
| 색션 ≥ 2 (stacked) | `${INTEGRATION_BRANCH}-${SECTION_NUMBER}` | `INTEGRATION_BRANCH` | `BRANCH_TO_PUSH` |

색션 ≥ 2일 때만 sub-branch 생성:

```bash
SUB_BRANCH="${INTEGRATION_BRANCH}-${SECTION_NUMBER}"   # 예: feat/PROJ-1-1
git checkout -b "$SUB_BRANCH"
```

이미 같은 이름의 브랜치가 있으면 사용자에게 보고하고 중단 — 기존 브랜치를 덮어쓰는 옵션은 제공하지 않습니다 (force push 금지 원칙과 충돌). 다른 번호를 쓰거나, 기존 브랜치를 사용자가 정리한 뒤 다시 호출하도록 안내.

---

## Step 4. 커밋 정리

워킹 트리에 변경이 남아 있으면 `references/commit-staging.md`를 `Read`해 절차대로 진행. `execute`가 마지막에 이미 커밋했으면 이 단계는 skip.

핵심 원칙만 본문에 명시:
- 색션 범위 외 파일 섞임 발견 시 사용자에게 반드시 보고 후 결정.
- 커밋 메시지 끝에 `Refs: ${JIRA_KEY}` 포함.
- pre-commit hook 실패 시 `--amend`/`--no-verify` 금지.

---

## Step 5. Push

```bash
git push -u origin "$BRANCH_TO_PUSH"
```

- 색션 ≥ 2: `BRANCH_TO_PUSH=$SUB_BRANCH` (Step 3에서 신규 브랜치 → 신규 push).
- 색션 = 1: `BRANCH_TO_PUSH=$INTEGRATION_BRANCH` (이미 origin에 있을 수 있어 `-u`는 첫 push에만 의미; 추적 설정되어 있으면 `git push`만으로 충분).

push 실패(권한·네트워크·non-fast-forward) 시 사용자에게 보고하고 중단 — force push 임의 우회 금지.

---

## Step 6. PR 생성

PR 본문은 `references/pr-body-template.md`를 `Read`해 변수를 채운 뒤 임시 파일에 쓰고 `--body-file`로 전달합니다 (셸 escape 부담 제거).

```bash
# pr-body-template.md를 채워 /tmp/pr-body.md에 Write 한 뒤:
gh pr create --base "$PR_BASE" --head "$PR_HEAD" \
  --title "<type>(<scope>): <색션 요약>" \
  --body-file /tmp/pr-body.md
```

- `--base`/`--head`는 Step 3 표를 그대로 사용. 임의로 `main`으로 바꾸지 않음.
- 사용자가 stacked가 아닌 일반 흐름(여러 색션이지만 각 PR을 모두 머지 대상으로)을 원하면 plan에서 통합 브랜치 = 머지 대상으로 정의했을 것 — 그 값을 따릅니다.

---

## Step 7. plan 진행 상태 표 갱신

PR URL/번호를 받아 plan md의 진행 상태 표를 `Edit`로 갱신:

```bash
PR_URL=$(gh pr view --json url -q .url)
PR_NUMBER=$(gh pr view --json number -q .number)
```

- 해당 색션 행의 `PR` 칸을 `#${PR_NUMBER}`로 갱신.
- 상태를 `done` → `pr-open`으로 변경.

`pr-open` → `merged` 전이는 **이 스킬이 아니라 다음 `execute` 호출의 Step 3-2(머지 동기화)에서 처리**합니다. 사용자가 GitHub에서 직접 머지 후 새 세션을 열 때 자연스럽게 반영되도록.

---

## Step 8. 자동 체인 종료 + 사용자 안내

PR 생성으로 한 색션의 자동 체인은 종료됩니다. 다음 색션은 PR 머지(외부 이벤트)가 선행되어야 하므로 자동 호출하지 않고 사용자에게 다음 행동만 안내합니다.

```
색션 N PR 생성 완료: <PR URL>
- base: <PR_BASE>
- head: <PR_HEAD>
- 지라: <JIRA_LINK>

자동 체인 종료. 다음 단계:
- GitHub에서 리뷰/머지 후 다음 색션을 `execute`로 호출 (머지 상태는 execute Step 3-2가 자동 감지·plan 갱신)
- 코드리뷰 코멘트가 달리면 `pr-review` 스킬로 반영
- fork → upstream PR이 필요하면 `pr-upstream`
```

---

## 주의사항

- **base는 절대 자동으로 변경하지 않음**. plan 메타의 통합 브랜치/머지 대상을 신뢰. 사용자가 다른 base를 원했으면 plan에 그렇게 적혀 있어야 함.
- **다른 색션 파일 섞임 금지**: Step 4에서 `git diff --staged --stat`로 색션 범위 외 파일이 있는지 반드시 확인.
- **force push 금지**: 신규 sub-branch라 force push가 필요할 일이 없음. 필요해 보이면 의심하고 사용자 확인. 단일 색션(`BRANCH_TO_PUSH=INTEGRATION_BRANCH`)에서 non-fast-forward가 나면 origin이 앞서가는 상황이므로 사용자에게 보고.
- **리뷰어 자동 지정 금지**: CODEOWNERS가 있으면 GitHub가 알아서 처리. 사용자가 명시적으로 요청한 경우만 `gh pr edit --add-reviewer`.
- **CI 실패 시**: 보고만 하고 임의 수정하지 않음. 색션 안의 문제면 추가 커밋, 색션 외 문제면 사용자 결정.
