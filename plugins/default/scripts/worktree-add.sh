#!/bin/bash
NAME=$(jq -r .name)
DIR="$(pwd)/.claude/worktrees/$NAME"

if [ -d "$DIR" ]; then
  echo "$DIR"
  exit 0
fi


if git show-ref --verify --quiet "refs/heads/feat/$NAME"; then
      git worktree add "$DIR" "feat/$NAME" >&2
else
      git worktree add "$DIR" -b "feat/$NAME" >&2
fi

echo "$DIR"
exit 0
