---
description: Register this plugin's statusline in ~/.claude/settings.json
allowed-tools: Bash, Read, Edit, Write
---

Claude Code 는 플러그인이 `statusLine` 을 직접 제공하는 걸 허용하지 않으므로, 사용자 스코프 `settings.json` 에 직접 등록해야 합니다. 이 커맨드는 그걸 자동화합니다.

## 수행 절차

1. **마켓플레이스 체크아웃 경로 확인.** 이 플러그인의 statusline 스크립트는 버전과 무관하게 다음 경로에 존재합니다:

   ```
   $HOME/.claude/plugins/marketplaces/comforest/plugins/default/scripts/statusline.sh
   ```

   `ls` 로 존재 여부를 확인하세요. 없으면 사용자에게 `/plugin` 으로 `default@comforest` 를 먼저 설치하라고 안내하고 중단합니다.

2. **`~/.claude/settings.json` 읽기.** 파일이 없으면 `{}` 로 시작합니다.

3. **`statusLine` 필드 병합.** 기존 `statusLine` 이 있으면 사용자에게 덮어쓸지 물어보세요. 승인되면 다음으로 설정합니다:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash $HOME/.claude/plugins/marketplaces/comforest/plugins/default/scripts/statusline.sh"
     }
   }
   ```

   Edit 도구로 병합 (다른 설정은 절대 건드리지 말 것).

4. **완료 안내.** `/reload-plugins` 또는 Claude Code 재시작 후 statusline 이 뜬다고 알려줍니다.
