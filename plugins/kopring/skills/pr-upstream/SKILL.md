---
name: pr-upstream
description: >
  Fork 워크플로우에서 origin(fork) PR이 머지된 뒤 upstream 원본 저장소로 PR을 올릴 때 사용하는 스킬입니다.
  "upstream PR", "원본 저장소 PR", "팀원 리뷰 PR", "pr-upstream", "fork에서 upstream으로",
  "upstream으로 올려줘" 등의 요청에 이 스킬을 사용하세요.
  origin PR의 제목/본문을 재활용하고, upstream 기준 최신화 여부를 확인한 뒤 `gh pr create`로 PR을 생성합니다.
---

# pr-upstream — Fork → Upstream PR 생성 스킬

`kopring:feat`로 origin(fork) PR을 만들고 Claude 코드 리뷰까지 마친 뒤,
**팀원 리뷰를 받기 위해 원본 저장소(upstream)로 PR을 올리는 단계**를 담당합니다.

전제: 현재 브랜치는 이미 origin에 push되어 있고, origin PR이 존재(보통 머지 완료 또는 머지 직전 상태).

---

## Step 1. 원격 저장소 확인

```bash
git remote -v
```

- `origin`은 본인 fork, `upstream`은 원본 저장소여야 합니다.
- `upstream`이 없으면 사용자에게 원본 저장소 URL을 물어보고 추가:
  ```bash
  git remote add upstream <upstream-url>
  ```

upstream의 기본 브랜치(main/master/develop)도 확인합니다:
```bash
gh repo view <upstream-owner>/<repo> --json defaultBranchRef -q .defaultBranchRef.name
```

---

## Step 2. 현재 브랜치와 origin PR 정보 수집

```bash
git branch --show-current
gh pr view --json number,title,body,headRefName,baseRefName
```

- origin PR의 **제목/본문을 그대로 재활용**합니다. (Claude 리뷰 반영 후 최종본이므로)
- PR이 여러 개이거나 못 찾으면 사용자에게 어느 PR을 기준으로 할지 확인합니다.

---

## Step 3. upstream 기준 최신화 확인

```bash
git fetch upstream
git log --oneline HEAD..upstream/<default-branch> | head -20
```

upstream에 새 커밋이 있어 충돌 가능성이 보이면 사용자에게 알리고 다음 중 선택받습니다:
- **rebase**: `git rebase upstream/<default-branch>` 후 force push (origin)
- **그대로 진행**: 충돌은 PR에서 해결

> 사용자 확인 없이 rebase/force push를 임의로 진행하지 않습니다.

---

## Step 4. fork 브랜치가 origin에 최신 상태인지 확인

```bash
git status
git log --oneline @{u}..HEAD
```

push되지 않은 커밋이 있으면 사용자에게 알리고 push 여부를 확인합니다.

---

## Step 5. upstream PR 생성

origin PR의 제목/본문을 변수에 담아 그대로 사용합니다.

```bash
PR_TITLE="$(gh pr view --json title -q .title)"
PR_BODY="$(gh pr view --json body -q .body)"
ORIGIN_PR_URL="$(gh pr view --json url -q .url)"
FORK_OWNER="$(gh repo view --json owner -q .owner.login)"
BRANCH="$(git branch --show-current)"

gh pr create \
  --repo <upstream-owner>/<repo> \
  --base <default-branch> \
  --head "${FORK_OWNER}:${BRANCH}" \
  --title "${PR_TITLE}" \
  --body "$(cat <<EOF
${PR_BODY}

---
> 이 PR은 fork에서 1차 리뷰를 거친 뒤 올라온 PR입니다.
> Origin PR: ${ORIGIN_PR_URL}
EOF
)"
```

생성된 upstream PR URL을 사용자에게 알려줍니다.

---

## Step 6. (선택) 리뷰어 지정

사용자가 리뷰어를 미리 알려줬거나, 프로젝트에 `CODEOWNERS`가 없는 경우 사용자에게 리뷰어를 물어보고 지정합니다:
```bash
gh pr edit <pr-number> --repo <upstream-owner>/<repo> --add-reviewer <user1>,<user2>
```

리뷰어가 명시되지 않았다면 **임의로 지정하지 않습니다.**

---

## 주의사항

- **force push는 사용자 확인 후에만**: rebase가 필요해도 origin에 force push하면 origin PR의 리뷰 스레드가 깨질 수 있으므로 반드시 확인.
- **upstream PR의 base 브랜치**: main이 아닐 수 있으니 Step 1에서 확인한 default branch 사용.
- **본문 중복 방지**: origin PR 본문에 이미 "Origin PR: ..." 링크가 들어있다면 footer를 추가하지 않습니다.
- **Conventional Commits**: 제목은 origin PR과 동일하게 유지하여 추적성을 보장합니다.
- **CI 실패 시**: upstream 쪽 CI가 fork PR과 다를 수 있습니다. 실패하면 사용자에게 보고만 하고 임의 수정하지 않습니다.
