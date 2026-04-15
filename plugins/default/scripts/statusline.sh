#!/bin/sh
# Claude Code status line - dir + branch | model + usage meters

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')

# Rate limits (Pro/Max only, may be absent)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Context window
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_max=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
ctx_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
ctx_cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
ctx_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

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

# Format reset timestamp as absolute time (HH:MM)
# Args: unix_timestamp
format_reset() {
  ts=$1
  if [ -z "$ts" ]; then
    return
  fi
  date -d "@$ts" '+%m/%d %H:%M' 2>/dev/null || date -r "$ts" '+%m/%d %H:%M' 2>/dev/null
}

# Format token count to human-readable (e.g., 45.2k, 1.2M)
format_tokens() {
  t=$1
  if [ -z "$t" ] || [ "$t" = "0" ]; then
    printf '0'
    return
  fi
  if [ "$t" -ge 1000000 ]; then
    awk "BEGIN { printf \"%.1fM\", $t / 1000000 }"
  elif [ "$t" -ge 1000 ]; then
    awk "BEGIN { printf \"%.0fk\", $t / 1000 }"
  else
    printf '%s' "$t"
  fi
}

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

# 5-hour rate limit + reset time
if [ -n "$five_pct" ]; then
  bar=$(make_bar "$five_pct")
  reset=$(format_reset "$five_reset")
  if [ -n "$reset" ]; then
    append_right "5h: $bar ↻${reset}"
  else
    append_right "5h: $bar"
  fi
fi

# Weekly rate limit + reset time
if [ -n "$week_pct" ]; then
  bar=$(make_bar "$week_pct")
  reset=$(format_reset "$week_reset")
  if [ -n "$reset" ]; then
    append_right "7d: $bar ↻${reset}"
  else
    append_right "7d: $bar"
  fi
fi

# Context window (always show if available)
if [ -n "$ctx_max" ] && [ "$ctx_max" != "0" ]; then
  ctx_used=$((ctx_input + ctx_output + ctx_cache_create + ctx_cache_read))
  used_fmt=$(format_tokens "$ctx_used")
  max_fmt=$(format_tokens "$ctx_max")
  if [ -n "$ctx_pct" ]; then
    bar=$(make_bar "$ctx_pct")
    append_right "ctx: $bar ${used_fmt}/${max_fmt}"
  else
    append_right "ctx: ${used_fmt}/${max_fmt}"
  fi
elif [ -n "$ctx_pct" ]; then
  bar=$(make_bar "$ctx_pct")
  append_right "ctx: $bar"
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$right" ]; then
  printf '%s  |  %s' "$left" "$right"
else
  printf '%s' "$left"
fi
