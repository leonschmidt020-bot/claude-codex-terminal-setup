#!/bin/bash

dim=$'\033[2m'
reset=$'\033[0m'
orange=$'\033[1;38;5;208m'
cyan=$'\033[36m'
green=$'\033[32m'

parsed="$(
  /usr/bin/jq -r '
    def clean: tostring | gsub("[\r\n]"; " ");
    [
      ((.model.display_name // "Claude") | clean),
      ((.effort.level // "") | clean),
      (if .context_window.used_percentage == null
       then ""
       else (.context_window.used_percentage | clean)
       end)
    ] | join("\u001f")
  ' 2>/dev/null
)" || parsed=""

IFS=$'\037' read -r claude_model effort context <<< "$parsed"
[ -n "$claude_model" ] || claude_model="Claude"

config_file="$HOME/.codex/config.toml"
codex_model=""
if [ -r "$config_file" ]; then
  codex_model="$(
    /usr/bin/sed -nE \
      '/^[[:space:]]*\[/{q;}; /^[[:space:]]*model[[:space:]]*=[[:space:]]*"[^"]*"/{s/^[^=]*=[[:space:]]*"([^"]*)".*$/\1/;p;q;}' \
      "$config_file" 2>/dev/null
  )"
fi
[ -n "$codex_model" ] || codex_model="-"

collab="$(cat "$HOME/.claude/codex-collab" 2>/dev/null)"
[ -n "$collab" ] || collab="on"

codex_active=""
if [ "$collab" = "on" ]; then
  while IFS= read -r line; do
    pid="${line%%[[:space:]]*}"
    case "$line" in
      *SkyComputerUse*|*"Computer Use.app"*) continue ;;
    esac
    if [ -n "$pid" ] && [ "$pid" != "$$" ]; then
      codex_active="1"
      break
    fi
  done < <(/usr/bin/pgrep -fl '(^|/)codex (exec|e) ' 2>/dev/null)
fi

printf '%sModell:%s %s%s' "$dim" "$reset" "$orange" "$claude_model"
if [ -n "$effort" ]; then
  printf ' (%s)' "$effort"
fi
if [ "$collab" = "off" ]; then
  printf '%s%s · %s%sCodex: aus%s' "$reset" "$dim" "$reset" "$dim" "$reset"
else
  printf '%s%s · %s%sCodex:%s %s%s%s' \
    "$reset" "$dim" "$reset" "$dim" "$reset" "$cyan" "$codex_model" "$reset"
  if [ -n "$codex_active" ]; then
    printf ' %s● aktiv%s' "$green" "$reset"
  fi
fi
if [ -n "$context" ]; then
  printf '%s · %s%sKontext:%s %s%%' "$dim" "$reset" "$dim" "$reset" "$context"
fi
printf '%s\n' "$reset"
exit 0
