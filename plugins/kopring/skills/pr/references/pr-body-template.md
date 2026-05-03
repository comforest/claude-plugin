# PR 본문 템플릿

`pr` 스킬 Step 6에서 사용. 변수는 셸에서 치환되거나 호출 직전 `Edit`/문자열 치환으로 채웁니다.

```markdown
## 관련 이슈
[${JIRA_KEY}](${JIRA_LINK})

## 변경 사항
- <색션 작업 항목 1>
- <색션 작업 항목 2>

## 배포 안전성
- <DB 마이그레이션 / API 호환 / 롤링 배포 고려사항. plan 색션의 체크리스트 그대로>

## 테스트
- [x] 단위 테스트 통과 (`./gradlew test`)
- [x] 빌드 통과 (`./gradlew build`)
- [ ] 통합 테스트 (해당 시)

## 관련 계획서
`docs/yyyy-mm-dd-{featName}.md` — 색션 ${SECTION_NUMBER}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## 채울 항목

- `${JIRA_KEY}` / `${JIRA_LINK}` — `pr` Step 2에서 추출한 값.
- 변경 사항 — plan 색션의 작업 항목 체크박스를 `- `로 변환.
- 배포 안전성 — plan 색션의 "배포 안전성 / 보안 체크" 항목 중 해당하는 것만.
- `${SECTION_NUMBER}` — 진행 상태 표의 색션 번호.
- 통합 테스트 항목은 해당하지 않으면 줄 자체를 삭제.
