# Living Themes: load the current theme's fzf/eza colours (extras/shell.sh) and
# reload them in open shells when the theme changes. Your own EZA_COLORS and
# FZF_DEFAULT_OPTS come back for themes that don't ship colours.
__living_themes_sync() {
  local target
  target=$(readlink "$HOME/.local/state/living-themes/current" 2>/dev/null || true)
  [[ $target == "${__living_themes_loaded-unset}" ]] && return 0
  if [[ -z ${__living_themes_saved+x} ]]; then
    __living_themes_saved=1
    __living_themes_eza=${EZA_COLORS-}
    __living_themes_fzf=${FZF_DEFAULT_OPTS-}
  fi
  __living_themes_loaded=$target
  export EZA_COLORS=$__living_themes_eza FZF_DEFAULT_OPTS=$__living_themes_fzf
  [[ -n $EZA_COLORS ]] || unset EZA_COLORS
  [[ -n $FZF_DEFAULT_OPTS ]] || unset FZF_DEFAULT_OPTS
  if [[ -n $target && -r $target/shell.sh ]]; then source "$target/shell.sh"; fi
  return 0
}
__living_themes_sync
PROMPT_COMMAND+=(__living_themes_sync)
