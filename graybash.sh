#!/usr/bin/env bash
# graybash.sh — grayscale bash prompt themes
#
# Original: Ak_0, 2017
# Apply a greyscale PS1 to the current account, persist it in ~/.bashrc,
# and restore the previous prompt without launching a nested shell.
#
# Usage:
#   ./graybash.sh                 Interactive menu
#   ./graybash.sh list            List theme names
#   ./graybash.sh preview NAME    Print a live preview
#   ./graybash.sh apply NAME      Write the theme to ~/.bashrc
#   ./graybash.sh try NAME        Open a subshell with the theme
#   ./graybash.sh restore         Remove the graybash prompt block
#   ./graybash.sh status          Show the installed theme
#   ./graybash.sh help
#
# Source the script (or ~/.bashrc after apply) to change the current shell:
#   source ./graybash.sh apply classic

SCRIPT_NAME="graybash"
BASHRC="${GRAYBASH_BASHRC:-$HOME/.bashrc}"
BACKUP="${BASHRC}.graybash.bak"
MARKER_BEGIN="# >>> graybash >>>"
MARKER_END="# <<< graybash <<<"

# Greyscale UI (black on white header, 256-color body). Disabled when stdout
# is not a terminal, or when NO_COLOR is set.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\e[0m'
  C_HEAD=$'\e[0;30;47m'
  C_DIM=$'\e[38;5;245m'
  C_FG=$'\e[38;5;252m'
  C_BOLD=$'\e[1;37m'
else
  C_RESET="" C_HEAD="" C_DIM="" C_FG="" C_BOLD=""
fi

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

say() {
  printf '%b\n' "$*"
}

die() {
  say "${C_HEAD} ${SCRIPT_NAME} ${C_RESET} $*" >&2
  if is_sourced; then
    return 1
  fi
  exit 1
}

usage() {
  cat <<'EOF'
graybash — grayscale bash prompt switcher

Usage:
  graybash.sh                  Interactive menu
  graybash.sh list             List available themes
  graybash.sh preview <name>   Show a live prompt preview
  graybash.sh apply <name>     Persist the theme in ~/.bashrc
  graybash.sh try <name>       Try the theme in a nested interactive bash
  graybash.sh restore          Remove graybash changes (default prompt)
  graybash.sh status           Show which theme is installed
  graybash.sh help             Show this help

Themes:
  classic    >[ user@12:00:00 AM ]:~/src:$
  clock      [14:23]~/src>
  userhost   user@host ~/src $
  twoline    two-line box prompt

Environment:
  GRAYBASH_BASHRC   Override the bashrc path (default: ~/.bashrc)
  NO_COLOR          Disable colour in the menu and messages
EOF
}

# PS1 values are stored without surrounding quotes. They must not contain
# single quotes so they can be written safely into bashrc as PS1='...'.
theme_ps1() {
  case "$1" in
    classic)
      # Original theme 1: >[ user@12-hour-time ]:cwd:$
      printf '%s' '>[ \[\e[38;5;241m\]\u\[\e[0m\]\[\e[38;5;15m\]@\[\e[0m\]\[\e[38;5;8m\]\@\[\e[0m\]\[\e[38;5;15m\] ]:\w:\$\[\e[0m\] '
      ;;
    clock)
      # Original theme 2: [HH:MM]cwd>
      printf '%s' '[\[\e[38;5;246m\]\A\[\e[0m\]]\w\[\e[38;5;243m\]>\[\e[0m\] '
      ;;
    userhost)
      printf '%s' '\[\e[38;5;245m\]\u\[\e[38;5;238m\]@\[\e[38;5;240m\]\h \[\e[38;5;252m\]\w \[\e[38;5;245m\]\$\[\e[0m\] '
      ;;
    twoline)
      printf '%s' '\[\e[38;5;240m\]┌─[\[\e[38;5;250m\]\u\[\e[38;5;240m\]]─[\[\e[38;5;245m\]\w\[\e[38;5;240m\]]\[\e[0m\]\n\[\e[38;5;240m\]└─\[\e[38;5;252m\]\$\[\e[0m\] '
      ;;
    *)
      return 1
      ;;
  esac
}

theme_names() {
  printf '%s\n' classic clock userhost twoline
}

valid_theme() {
  theme_ps1 "$1" >/dev/null
}

supports_prompt_expand() {
  (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4) ))
}

render_preview() {
  local ps1="$1"
  if supports_prompt_expand; then
    local PS1="$ps1"
    printf '%s' "${PS1@P}"
  else
    printf '%s' "(preview needs bash 4.4+; theme will still apply)"
  fi
}

banner() {
  say "${C_HEAD}                                                                        "
  say "  ${SCRIPT_NAME}  ·  grayscale bash prompts for ${USER:-$(id -un)}@$(hostname -s 2>/dev/null || hostname)  "
  say "                                                                        ${C_RESET}"
}

list_themes() {
  local name ps1 preview
  for name in $(theme_names); do
    ps1="$(theme_ps1 "$name")"
    preview="$(render_preview "$ps1")"
    preview="${preview//$'\n'/$'\n              '}"
    printf '  %s%-10s%s %s%s%s\n' "$C_BOLD" "$name" "$C_RESET" "$C_FG" "$preview" "$C_RESET"
  done
}

installed_theme() {
  [[ -f "$BASHRC" ]] || return 1
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { inblock=1; next }
    $0 == e { inblock=0 }
    inblock && $0 ~ /^# theme: / {
      sub(/^# theme: /, "")
      print
      exit
    }
  ' "$BASHRC"
}

show_status() {
  local theme
  theme="$(installed_theme || true)"
  if [[ -n "$theme" ]]; then
    say "Installed theme: ${C_BOLD}${theme}${C_RESET}"
    say "Config: ${BASHRC}"
    [[ -f "$BACKUP" ]] && say "Backup: ${BACKUP}"
  else
    say "No graybash theme is installed in ${BASHRC}"
  fi
}

ensure_bashrc() {
  if [[ ! -e "$BASHRC" ]]; then
    printf '# ~/.bashrc  (created by graybash)\n' > "$BASHRC"
  elif [[ ! -f "$BASHRC" ]]; then
    die "Refusing to edit ${BASHRC}: not a regular file"
    return 1
  fi
}

backup_bashrc() {
  if [[ -f "$BASHRC" && ! -f "$BACKUP" ]]; then
    cp -a "$BASHRC" "$BACKUP"
    say "Backup created: ${BACKUP}"
  fi
}

strip_block() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local tmp
  tmp="$(mktemp "${file}.XXXXXX")" || {
    die "Could not create a temporary file"
    return 1
  }
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    !skip { print }
  ' "$file" > "$tmp" || {
    rm -f "$tmp"
    die "Failed to update ${file}"
    return 1
  }

  if command -v chmod >/dev/null 2>&1 && chmod --reference="$file" "$tmp" 2>/dev/null; then
    :
  fi
  mv "$tmp" "$file"
}

write_block() {
  local theme="$1" ps1="$2" dest="$3"
  if [[ "$ps1" == *"'"* ]]; then
    die "Internal error: theme '${theme}' PS1 contains a single quote"
    return 1
  fi
  cat >> "$dest" <<EOF

${MARKER_BEGIN}
# theme: ${theme}
PROMPT_DIRTRIM=3
PS1='${ps1}'
${MARKER_END}
EOF
}

apply_to_current_shell() {
  is_sourced || return 0
  local ps1="$1"
  PROMPT_DIRTRIM=3
  PS1="$ps1"
  export PS1 PROMPT_DIRTRIM
}

apply_theme() {
  local theme="$1" ps1
  valid_theme "$theme" || {
    die "Unknown theme '${theme}'. Try: $(theme_names | tr '\n' ' ')"
    return 1
  }
  ps1="$(theme_ps1 "$theme")"

  ensure_bashrc || return 1
  backup_bashrc
  strip_block "$BASHRC" || return 1
  write_block "$theme" "$ps1" "$BASHRC" || return 1
  apply_to_current_shell "$ps1"

  say "Applied ${C_BOLD}${theme}${C_RESET} to ${BASHRC}"
  if is_sourced; then
    say "This shell is using the new prompt now."
  else
    say "Reload it with:  ${C_BOLD}source ${BASHRC}${C_RESET}"
    say "Or open a new terminal."
  fi
}

restore_default() {
  if [[ -f "$BASHRC" ]]; then
    strip_block "$BASHRC" || return 1
  fi

  if is_sourced; then
    unset PROMPT_DIRTRIM 2>/dev/null || true
    # Reload bashrc so the account's original PS1 comes back.
    if [[ -f "$BASHRC" ]]; then
      # shellcheck source=/dev/null
      source "$BASHRC"
    else
      PS1='\u@\h:\w\$ '
    fi
  fi

  say "Removed graybash prompt from ${BASHRC}"
  if ! is_sourced; then
    say "Reload it with:  ${C_BOLD}source ${BASHRC}${C_RESET}"
  fi
}

try_theme() {
  local theme="$1" ps1 rcfile
  valid_theme "$theme" || {
    die "Unknown theme '${theme}'"
    return 1
  }
  ps1="$(theme_ps1 "$theme")"
  rcfile="$(mktemp)"
  {
    [[ -f "$BASHRC" ]] && cat "$BASHRC"
    printf '\n# graybash try session (%s)\n' "$theme"
    printf 'PROMPT_DIRTRIM=3\n'
    printf "PS1='%s'\n" "$ps1"
  } > "$rcfile"
  say "Trying ${C_BOLD}${theme}${C_RESET}. Type ${C_BOLD}exit${C_RESET} to leave the preview shell."
  bash --rcfile "$rcfile" -i
  local st=$?
  rm -f "$rcfile"
  return "$st"
}

preview_theme() {
  local theme="$1" ps1
  valid_theme "$theme" || {
    die "Unknown theme '${theme}'"
    return 1
  }
  ps1="$(theme_ps1 "$theme")"
  printf 'Theme: %s\n' "$theme"
  printf 'Preview: %s\n' "$(render_preview "$ps1")"
}

confirm() {
  local prompt="${1:-Apply?} "
  local reply
  if [[ ! -t 0 ]]; then
    return 0
  fi
  printf '%s' "$prompt"
  read -r reply || return 1
  case "${reply:-Y}" in
    Y|y|yes|YES|"") return 0 ;;
    *) return 1 ;;
  esac
}

interactive_menu() {
  local choice theme
  while true; do
    printf '\n'
    banner
    say "${C_DIM}Custom prompts${C_RESET}"
    say "  ${C_BOLD}1)${C_RESET} classic     $(render_preview "$(theme_ps1 classic)")"
    say "  ${C_BOLD}2)${C_RESET} clock       $(render_preview "$(theme_ps1 clock)")"
    say "  ${C_BOLD}3)${C_RESET} userhost    $(render_preview "$(theme_ps1 userhost)")"
    say "  ${C_BOLD}4)${C_RESET} twoline     (two-line)"
    if supports_prompt_expand; then
      # Render twoline on its own so the newline does not break the menu row.
      printf '               %s\n' "$(render_preview "$(theme_ps1 twoline)")"
    fi
    say ""
    say "${C_DIM}Other${C_RESET}"
    say "  ${C_BOLD}d)${C_RESET} default     restore the prompt from ${BASHRC}"
    say "  ${C_BOLD}s)${C_RESET} status      show the installed theme"
    say "  ${C_BOLD}t)${C_RESET} try         open a subshell with a theme"
    say "  ${C_BOLD}q)${C_RESET} quit"
    printf '\n'
    show_status
    printf '\nSelect: '
    read -r choice || return 1
    case "$choice" in
      1|classic) theme=classic ;;
      2|clock) theme=clock ;;
      3|userhost) theme=userhost ;;
      4|twoline) theme=twoline ;;
      d|D|default|restore)
        if confirm "Remove graybash prompt and restore default? [Y/n] "; then
          restore_default || return 1
        else
          say "Cancelled."
        fi
        continue
        ;;
      s|S|status)
        show_status
        continue
        ;;
      t|T|try)
        printf 'Theme to try (classic|clock|userhost|twoline): '
        read -r theme || return 1
        if valid_theme "${theme:-}"; then
          try_theme "$theme" || true
        else
          say "Unknown theme '${theme:-}'."
        fi
        continue
        ;;
      q|Q|quit|exit)
        say "Bye."
        return 0
        ;;
      *)
        say "Not a valid choice."
        continue
        ;;
    esac

    preview_theme "$theme"
    if confirm "Apply '${theme}' to ${BASHRC}? [Y/n] "; then
      apply_theme "$theme" || return 1
    else
      say "Cancelled."
    fi
  done
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    ""|menu|interactive)
      interactive_menu
      ;;
    list|ls)
      list_themes
      ;;
    preview)
      [[ "${1:-}" ]] || { die "preview needs a theme name"; return 1; }
      preview_theme "$1"
      ;;
    apply|set)
      [[ "${1:-}" ]] || { die "apply needs a theme name"; return 1; }
      apply_theme "$1"
      ;;
    try|test)
      [[ "${1:-}" ]] || { die "try needs a theme name"; return 1; }
      try_theme "$1"
      ;;
    restore|default|reset|uninstall)
      restore_default
      ;;
    status)
      show_status
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      die "Unknown command '${cmd}'. Try: ${SCRIPT_NAME} help"
      return 1
      ;;
  esac
}

# Avoid leaking set -u / helper functions into the caller's shell when sourced.
__graybash_sourced=0
if is_sourced; then
  __graybash_sourced=1
fi
__graybash_had_nounset=0
case $- in
  *u*) __graybash_had_nounset=1 ;;
esac
set -u

main "$@"
__graybash_status=$?

if (( __graybash_had_nounset == 0 )); then
  set +u
fi

unset -f is_sourced say die usage theme_ps1 theme_names valid_theme \
  supports_prompt_expand render_preview banner list_themes installed_theme \
  show_status ensure_bashrc backup_bashrc strip_block write_block \
  apply_to_current_shell apply_theme restore_default try_theme preview_theme \
  confirm interactive_menu main 2>/dev/null || true
unset SCRIPT_NAME BASHRC BACKUP MARKER_BEGIN MARKER_END \
  C_RESET C_HEAD C_DIM C_FG C_BOLD 2>/dev/null || true

if (( __graybash_sourced == 1 )); then
  unset __graybash_sourced __graybash_had_nounset
  return "$__graybash_status"
fi
unset __graybash_sourced __graybash_had_nounset
exit "$__graybash_status"
