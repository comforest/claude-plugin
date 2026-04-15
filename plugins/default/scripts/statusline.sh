#!/bin/sh
# Claude Code status line - dir + branch | ctx | rate limit meters

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

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

# Format remaining time until reset (1d 2h 30m format)
# Args: unix_timestamp
format_reset() {
  ts=$1
  if [ -z "$ts" ]; then
    return
  fi
  now=$(date +%s)
  diff=$((ts - now))
  if [ "$diff" -le 0 ]; then
    return
  fi
  d=$((diff / 86400))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh %dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# Format token count to human-readable (e.g., 45k, 1.2M)
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

# ── Build segments ─────────────────────────────────────────────────────────────

# Context window segment
ctx_full="" ctx_short=""
if [ -n "$ctx_max" ] && [ "$ctx_max" != "0" ] && [ -n "$ctx_pct" ]; then
  ctx_used=$((ctx_input + ctx_output + ctx_cache_create + ctx_cache_read))
  used_fmt=$(format_tokens "$ctx_used")
  max_fmt=$(format_tokens "$ctx_max")
  bar=$(make_bar "$ctx_pct")
  ctx_pct_int=$(printf '%.0f' "$ctx_pct")
  ctx_full="ctx: $bar ${used_fmt}/${max_fmt}"
  ctx_short="ctx: ${ctx_pct_int}%"
elif [ -n "$ctx_pct" ]; then
  ctx_pct_int=$(printf '%.0f' "$ctx_pct")
  bar=$(make_bar "$ctx_pct")
  ctx_full="ctx: $bar"
  ctx_short="ctx: ${ctx_pct_int}%"
fi

# 5-hour rate limit segment
five_full="" five_short=""
if [ -n "$five_pct" ]; then
  bar=$(make_bar "$five_pct")
  reset=$(format_reset "$five_reset")
  five_pct_int=$(printf '%.0f' "$five_pct")
  if [ -n "$reset" ]; then
    five_full="5h: $bar ${reset}"
    five_short="5h: ${five_pct_int}%"
  else
    five_full="5h: $bar"
    five_short="5h: ${five_pct_int}%"
  fi
fi

# Weekly rate limit segment
week_full="" week_short=""
if [ -n "$week_pct" ]; then
  bar=$(make_bar "$week_pct")
  reset=$(format_reset "$week_reset")
  week_pct_int=$(printf '%.0f' "$week_pct")
  if [ -n "$reset" ]; then
    week_full="7d: $bar ${reset}"
    week_short="7d: ${week_pct_int}%"
  else
    week_full="7d: $bar"
    week_short="7d: ${week_pct_int}%"
  fi
fi

# ── Assemble right side with adaptive truncation ───────────────────────────────
term_width=$(tput cols 2>/dev/null || printf '200')

build_right() {
  r=""
  for seg in "$@"; do
    if [ -z "$seg" ]; then continue; fi
    if [ -z "$r" ]; then
      r="$seg"
    else
      r="$r  |  $seg"
    fi
  done
  printf '%s' "$r"
}

str_len() {
  printf '%s' "$1" | wc -m
}

# Level 0: full
right=$(build_right "$ctx_full" "$five_full" "$week_full")
total_len=$(( $(str_len "$left") + 5 + $(str_len "$right") ))  # 5 = "  |  "

if [ "$total_len" -gt "$term_width" ]; then
  # Level 1: ctx/rate limit 를 % 만 표시, 리셋 시간 유지
  right=$(build_right "$ctx_short" "$five_full" "$week_full")
  total_len=$(( $(str_len "$left") + 5 + $(str_len "$right") ))
fi

if [ "$total_len" -gt "$term_width" ]; then
  # Level 2: 리셋 시간 제거
  right=$(build_right "$ctx_short" "$five_short" "$week_short")
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [ -n "$right" ]; then
  printf '%s  |  %s' "$left" "$right"
else
  printf '%s' "$left"
fi
