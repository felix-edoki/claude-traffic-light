#!/usr/bin/env bash
# Usage: set-state.sh <ready|working|waiting>
# Writes the state file and plays the matching sound (fails silently).

state="${1:-ready}"
case "$state" in ready|working|waiting) ;; *) exit 0 ;; esac

state_file="${TRAFFIC_LIGHT_STATE:-$HOME/.claude/traffic-light.state}"
mkdir -p "$(dirname "$state_file")" 2>/dev/null
printf "%s" "$state" > "$state_file"

# Resolve the sounds dir: env override > repo-relative > $HOME/.claude/sounds
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sounds_dir="${TRAFFIC_LIGHT_SOUNDS:-$script_dir/../sounds}"
[ -d "$sounds_dir" ] || sounds_dir="$HOME/.claude/sounds"

case "$state" in
    ready)   sound="$sounds_dir/ready.wav"   ;;
    working) sound="$sounds_dir/working.wav" ;;
    waiting) sound="$sounds_dir/waiting.wav" ;;
esac

[ -f "$sound" ] || exit 0

play() {
    case "$(uname -s)" in
        Darwin) command -v afplay >/dev/null && afplay "$sound" >/dev/null 2>&1 ;;
        Linux)  command -v paplay >/dev/null && paplay "$sound" >/dev/null 2>&1 \
                || (command -v aplay >/dev/null && aplay -q "$sound" >/dev/null 2>&1) ;;
        MINGW*|MSYS*|CYGWIN*)
            win_path=$(cygpath -w "$sound" 2>/dev/null || echo "$sound")
            powershell -NoProfile -Command "(New-Object Media.SoundPlayer '$win_path').PlaySync()" >/dev/null 2>&1
            ;;
    esac
}

play &
disown 2>/dev/null
exit 0
