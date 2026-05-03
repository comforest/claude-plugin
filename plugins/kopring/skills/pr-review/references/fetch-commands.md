# 리뷰 코멘트 수집 명령

`pr-review` 스킬 Step 1에서 사용. PR 번호(`$PR_NUMBER`)와 저장소 owner/repo는 `gh repo view --json owner,name -q '.owner.login + "/" + .name'`로 미리 얻습니다.

## 기본 코멘트 수집 (인라인 + 리뷰 + 이슈 코멘트)

```bash
OWNER_REPO=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')

# 인라인 코드 코멘트 (파일/라인 포함)
gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/comments" \
  --jq '.[] | {id, path, line, body, user: .user.login, in_reply_to_id}'

# PR 전체 리뷰 (승인/변경요청 본문)
gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/reviews" \
  --jq '.[] | {id, state, body, user: .user.login}'

# 일반 이슈 코멘트
gh api "repos/${OWNER_REPO}/issues/${PR_NUMBER}/comments" \
  --jq '.[] | {id, body, user: .user.login}'
```

## Resolved 상태 포함 조회 (GraphQL)

이미 해결된 스레드(`isResolved: true`)를 건너뛰기 위해 사용:

```bash
OWNER=$(gh repo view --json owner -q .owner.login)
REPO=$(gh repo view --json name -q .name)

gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){
          nodes{
            isResolved
            comments(first:20){
              nodes{ body path line author{login} }
            }
          }
        }
      }
    }
  }' -F owner="$OWNER" -F repo="$REPO" -F pr="$PR_NUMBER"
```

## 필터 원칙

- **본인(Claude)이 남긴 코멘트는 제외** — `user.login`으로 식별.
- 답글 스레드는 **가장 마지막 상태** 기준으로 처리 필요 여부 판단.
- `isResolved: true` 스레드는 스킵.
