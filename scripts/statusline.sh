#!/usr/bin/env bash
# Traffic-light statusline for Claude Code.
# Renders a colored strip based on ~/.claude/traffic-light.state,
# then appends the standard cwd | branch | ctx | tokens info.

input=$(cat)

state_file="${TRAFFIC_LIGHT_STATE:-$HOME/.claude/traffic-light.state}"
state="ready"
if [ -r "$state_file" ]; then
    state=$(tr -d '[:space:]' < "$state_file")
fi

case "$state" in
    working) strip=$'\033[30;43m  WORK   \033[0m'  ;;  # yellow
    waiting) strip=$'\033[97;41m  WAIT   \033[0m'  ;;  # red
    *)       strip=$'\033[30;42m  READY  \033[0m'  ;;  # green
esac

# --- cwd ---
cwd_raw=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
cwd=$(echo "$cwd_raw" | tr '\\' '/')
home_fwd=$(echo "$USERPROFILE" | tr '\\' '/')
if [ -n "$home_fwd" ]; then
    short_cwd="${cwd/#$home_fwd/\~}"
else
    short_cwd="$cwd"
fi
short_cwd=$(echo "$short_cwd" | awk -F'/' '{
    n=NF
    if (n <= 2) { print $0 }
    else if ($1 == "~") { print "~/" $(n-1) "/" $n }
    else { print ".../" $(n-1) "/" $n }
}')

# --- git branch ---
git_branch=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
                 || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# --- context + tokens ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

parts=("$short_cwd")
[ -n "$git_branch" ] && parts+=("[$git_branch]")
if [ -n "$used_pct" ]; then
    parts+=("ctx:$(printf "%.0f" "$used_pct")%")
fi
if [ -n "$total_in" ] && [ -n "$total_out" ]; then
    total=$(( total_in + total_out ))
    if [ "$total" -ge 1000000 ]; then
        tok_fmt=$(awk "BEGIN { printf \"%.1fM\", $total/1000000 }")
    elif [ "$total" -ge 1000 ]; then
        tok_fmt=$(awk "BEGIN { printf \"%.0fk\", $total/1000 }")
    else
        tok_fmt="${total}"
    fi
    parts+=("tokens:${tok_fmt}")
fi

output=""
for part in "${parts[@]}"; do
    if [ -z "$output" ]; then output="$part"
    else output="$output  |  $part"; fi
done

printf "%s  %s" "$strip" "$output"
