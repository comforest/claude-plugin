# 색션 단위 커밋 정리

`pr` 스킬 Step 4에서 사용. 워킹 트리에 변경이 남아 있을 때만 적용 (이미 `execute`가 색션 끝에서 커밋했으면 skip).

## 절차

1. 변경 범위 확인
   ```bash
   git status
   git diff --stat
   ```

2. 색션 범위 파일만 스테이징 — `git add <files>` 형태로 명시. `git add -A` / `git add .` 금지.

3. 스테이징 결과 재확인 (다른 색션 파일 섞임 방지):
   ```bash
   git diff --staged --stat
   ```
   색션 범위 외 파일이 보이면 사용자에게 보고하고 진행 여부를 확인.

4. 커밋 메시지 — Conventional Commits + 지라 키:
   ```bash
   git commit -m "$(cat <<EOF
   <type>(<scope>): <색션 요약>

   <주요 작업 항목 1>
   <주요 작업 항목 2>

   Refs: ${JIRA_KEY}
   EOF
   )"
   ```

## 타입 가이드

| 타입 | 사용처 |
|------|--------|
| `feat` | 신규 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 동일, 구조 개선 |
| `perf` | 성능 개선 |
| `test` | 테스트 코드만 |
| `chore` | 빌드/설정 변경 |

## 주의

- pre-commit hook 실패 시 **새 커밋**으로 수정. `--amend` 금지 (hook이 막은 시점에 커밋이 없으므로 amend는 직전 색션 커밋을 덮어씀).
- `--no-verify` 금지 — hook 실패는 근본 원인 해결.
