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

_graybash_name="graybash"
_graybash_bashrc="${GRAYBASH_BASHRC:-$HOME/.bashrc}"
_graybash_backup="${_graybash_bashrc}.graybash.bak"
_graybash_begin="# >>> graybash >>>"
_graybash_end="# <<< graybash <<<"

# Greyscale UI (black on white header, 256-color body). Disabled when stdout
# is not a terminal, or when NO_COLOR is set.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _GB_RESET=$'\e[0m'
  _GB_HEAD=$'\e[0;30;47m'
  _GB_DIM=$'\e[38;5;245m'
  _GB_FG=$'\e[38;5;252m'
  _GB_BOLD=$'\e[1;37m'
else
  _GB_RESET="" _GB_HEAD="" _GB_DIM="" _GB_FG="" _GB_BOLD=""
fi

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

say() {
  printf '%b\n' "$*"
}

die() {
  if [[ -n "$_GB_HEAD" ]]; then
    say "${_GB_HEAD} ${_graybash_name} ${_GB_RESET} $*" >&2
  else
    say "${_graybash_name}: $*" >&2
  fi
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
  local who host
  who="${USER:-$(id -un)}"
  host="$(hostname -s 2>/dev/null || hostname)"
  say "${_GB_HEAD} ${_graybash_name} ${_GB_RESET} ${_GB_DIM}grayscale prompts for ${who}@${host}${_GB_RESET}"
}

list_themes() {
  local name ps1 preview
  for name in $(theme_names); do
    ps1="$(theme_ps1 "$name")"
    preview="$(render_preview "$ps1")"
    preview="${preview//$'\n'/$'\n              '}"
    printf '  %s%-10s%s %s%s%s\n' "$_GB_BOLD" "$name" "$_GB_RESET" "$_GB_FG" "$preview" "$_GB_RESET"
  done
}

installed_theme() {
  [[ -f "$_graybash_bashrc" ]] || return 1
  awk -v b="$_graybash_begin" -v e="$_graybash_end" '
    $0 == b { inblock=1; next }
    $0 == e { inblock=0 }
    inblock && $0 ~ /^# theme: / {
      sub(/^# theme: /, "")
      print
      exit
    }
  ' "$_graybash_bashrc"
}

show_status() {
  local theme
  theme="$(installed_theme || true)"
  if [[ -n "$theme" ]]; then
    say "Installed theme: ${_GB_BOLD}${theme}${_GB_RESET}"
    say "Config: ${_graybash_bashrc}"
    [[ -f "$_graybash_backup" ]] && say "Backup: ${_graybash_backup}"
  else
    say "No graybash theme is installed in ${_graybash_bashrc}"
  fi
}

ensure_bashrc() {
  if [[ ! -e "$_graybash_bashrc" ]]; then
    printf '# ~/.bashrc  (created by graybash)\n' > "$_graybash_bashrc"
  elif [[ ! -f "$_graybash_bashrc" ]]; then
    die "Refusing to edit ${_graybash_bashrc}: not a regular file"
    return 1
  fi
}

backup_bashrc() {
  if [[ -f "$_graybash_bashrc" && ! -f "$_graybash_backup" ]]; then
    cp -a "$_graybash_bashrc" "$_graybash_backup"
    say "Backup created: ${_graybash_backup}"
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
  awk -v b="$_graybash_begin" -v e="$_graybash_end" '
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
  mv "$tmp" "$file" || {
    rm -f "$tmp"
    die "Failed to replace ${file}"
    return 1
  }
}

write_block() {
  local theme="$1" ps1="$2" dest="$3"
  case "$ps1" in
    *\'*)
      die "Internal error: theme '${theme}' PS1 contains a single quote"
      return 1
      ;;
  esac
  cat >> "$dest" <<EOF

${_graybash_begin}
# theme: ${theme}
PROMPT_DIRTRIM=3
PS1='${ps1}'
${_graybash_end}
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
  strip_block "$_graybash_bashrc" || return 1
  write_block "$theme" "$ps1" "$_graybash_bashrc" || return 1
  apply_to_current_shell "$ps1"

  say "Applied ${_GB_BOLD}${theme}${_GB_RESET} to ${_graybash_bashrc}"
  if is_sourced; then
    say "This shell is using the new prompt now."
  else
    say "Reload it with:  ${_GB_BOLD}source ${_graybash_bashrc}${_GB_RESET}"
    say "Or open a new terminal."
  fi
}

restore_default() {
  if [[ -f "$_graybash_bashrc" ]]; then
    strip_block "$_graybash_bashrc" || return 1
  fi

  if is_sourced; then
    unset PROMPT_DIRTRIM 2>/dev/null || true
    # Reload bashrc so the account's original PS1 comes back.
    if [[ -f "$_graybash_bashrc" ]]; then
      # shellcheck source=/dev/null
      source "$_graybash_bashrc"
    else
      PS1='\u@\h:\w\$ '
    fi
  fi

  say "Removed graybash prompt from ${_graybash_bashrc}"
  if ! is_sourced; then
    say "Reload it with:  ${_GB_BOLD}source ${_graybash_bashrc}${_GB_RESET}"
  fi
}

try_theme() {
  local theme="$1" ps1 rcfile st
  valid_theme "$theme" || {
    die "Unknown theme '${theme}'"
    return 1
  }
  ps1="$(theme_ps1 "$theme")"
  rcfile="$(mktemp)" || {
    die "Could not create a temporary file"
    return 1
  }
  {
    [[ -f "$_graybash_bashrc" ]] && cat "$_graybash_bashrc"
    printf '\n# graybash try session (%s)\n' "$theme"
    printf 'PROMPT_DIRTRIM=3\n'
    printf "PS1='%s'\n" "$ps1"
  } > "$rcfile"
  say "Trying ${_GB_BOLD}${theme}${_GB_RESET}. Type ${_GB_BOLD}exit${_GB_RESET} to leave the preview shell."
  bash --rcfile "$rcfile" -i
  st=$?
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
    say "${_GB_DIM}Custom prompts${_GB_RESET}"
    say "  ${_GB_BOLD}1)${_GB_RESET} classic     $(render_preview "$(theme_ps1 classic)")"
    say "  ${_GB_BOLD}2)${_GB_RESET} clock       $(render_preview "$(theme_ps1 clock)")"
    say "  ${_GB_BOLD}3)${_GB_RESET} userhost    $(render_preview "$(theme_ps1 userhost)")"
    say "  ${_GB_BOLD}4)${_GB_RESET} twoline"
    if supports_prompt_expand; then
      local twopreview
      twopreview="$(render_preview "$(theme_ps1 twoline)")"
      twopreview="${twopreview//$'\n'/$'\n               '}"
      printf '               %s\n' "$twopreview"
    fi
    say ""
    say "${_GB_DIM}Other${_GB_RESET}"
    say "  ${_GB_BOLD}d)${_GB_RESET} default     restore the prompt from ${_graybash_bashrc}"
    say "  ${_GB_BOLD}s)${_GB_RESET} status      show the installed theme"
    say "  ${_GB_BOLD}t)${_GB_RESET} try         open a subshell with a theme"
    say "  ${_GB_BOLD}q)${_GB_RESET} quit"
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
    if confirm "Apply '${theme}' to ${_graybash_bashrc}? [Y/n] "; then
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
      die "Unknown command '${cmd}'. Try: ${_graybash_name} help"
      return 1
      ;;
  esac
}

# Avoid leaking set -u / helper functions into the caller shell when sourced.
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
unset _graybash_name _graybash_bashrc _graybash_backup _graybash_begin _graybash_end \
  _GB_RESET _GB_HEAD _GB_DIM _GB_FG _GB_BOLD 2>/dev/null || true

if (( __graybash_sourced == 1 )); then
  unset __graybash_sourced __graybash_had_nounset
  return "$__graybash_status"
fi
unset __graybash_sourced __graybash_had_nounset
exit "$__graybash_status"
