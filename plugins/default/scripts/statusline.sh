#!/bin/sh
# Claude Code status line - dir + branch | model + usage meters

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')

# Rate limits (Pro/Max only, may be absent)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Context window
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Git branch: prefer JSON field, fall back to running git
branch=$(echo "$input" | jq -r '.git.branch // empty')
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" -c core.fsmonitor=false rev-parse --short HEAD 2>/dev/null)
  fi
fi

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Build progress bar (8 blocks wide)
# Args: percentage (0-100)
make_bar() {
  pct=$1
  width=8
  if [ -z "$pct" ]; then
    return
  fi
  filled=$(awk "BEGIN { v = int($pct * $width / 100); if (v > $width) v = $width; print v }")
  bar=""
  i=0
  while [ "$i" -lt "$width" ]; do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}█"
    else
      bar="${bar}░"
    fi
    i=$((i + 1))
  done
  pct_int=$(printf '%.0f' "$pct")
  printf '[%s] %s%%' "$bar" "$pct_int"
}

# ── Left: directory + branch ──────────────────────────────────────────────────
if [ -n "$branch" ]; then
  left="$short_cwd   $branch"
else
  left="$short_cwd"
fi

# ── Right: model + usage meters ───────────────────────────────────────────────
right=""

append_right() {
  if [ -z "$right" ]; then
    right="$1"
  else
    right="$right  |  $1"
  fi
}

# Model
if [ -n "$model" ]; then
  append_right "$model"
fi

# 5-hour rate limit
if [ -n "$five_pct" ]; then
  bar=$(make_bar "$five_pct")
  append_right "5h: $bar"
fi

# Weekly rate limit
if [ -n "$week_pct" ]; then
  bar=$(make_bar "$week_pct")
  append_right "7d: $bar"
fi

# Context window (fallback if no rate limits)
if [ -z "$five_pct" ] && [ -z "$week_pct" ] && [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  append_right "ctx: ${ctx_int}%"
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$right" ]; then
  printf '%s  |  %s' "$left" "$right"
else
  printf '%s' "$left"
fi
