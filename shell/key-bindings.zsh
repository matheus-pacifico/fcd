#     _____ _____ ____
#    / ___// ___// __ \
#   / /__ / /   / / / /
#  / ___// /__ / /_/ /
# /_/   /____//_____/ key-bindings.zsh
#
# - $FCD_ALT_S_COMMAND
# - $FCD_ALT_S_OPTS
# - $FCD_ALT_Q_COMMAND
# - $FCD_ALT_Q_OPTS
#
# Adapted from fzf shell integration:
# https://github.com/junegunn/fzf

# Key bindings
# ------------

if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  __fcd_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  () {
    __fcd_key_bindings_options="setopt"
    'local' '__fcd_opt'
    for __fcd_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fcd_opt" ]]; then
        __fcd_key_bindings_options+=" -o $__fcd_opt"
      else
        __fcd_key_bindings_options+=" +o $__fcd_opt"
      fi
    done
  }
fi

'builtin' 'emulate' 'zsh' && 'builtin' 'setopt' 'no_aliases'

{
if [[ -o interactive ]]; then

__fcd_tmux_opts() {
  [[ -n ${TMUX_PANE-} ]] && { [[ ${FCD_TMUX:-0} != 0 ]] || [[ -n ${FCD_TMUX_OPTS-} ]]; } &&
    builtin printf -- '--tmux=%s -- ' "${FCD_TMUX_OPTS:--d${FCD_TMUX_HEIGHT:-40%}}" || builtin printf ''
}

__fcd_defaults() {
  builtin printf '%s\n' "--height ${FCD_TMUX_HEIGHT:-40%} --min-height 20+ --ignore-ctrl-z $1"
  command cat "${FCD_DEFAULT_OPTS_FILE-}" 2> /dev/null
  builtin printf '%s\n' "${FCD_DEFAULT_OPTS-} $2"
}

# ALT-S - cd into the selected directory
fcd-widget() {
  setopt localoptions pipefail no_aliases 2> /dev/null
	local tmux_opts
  tmux_opts="$(__fcd_tmux_opts)"
  local dir="$(
    FCD_DEFAULT_OPTS=$(__fcd_defaults "--walker=dir,follow,nohidden" "${FCD_ALT_S_OPTS-}") \
		FCD_DEFAULT_OPTS_FILE='' \
		command fcd ${tmux_opts:+"$tmux_opts"})"
  if [[ -z "$dir" ]]; then
	  zle redisplay
	  return 0
	fi
  dir=$(builtin cd -q >/dev/null -- "${dir}" && echo "${PWD}" || echo "${dir}")
	zle push-line # Clear buffer. Auto-restored on next prompt.
	BUFFER="builtin cd -- ${(q)dir}"
	zle accept-line
	local ret=$?
	unset dir # ensure this doesn't end up appearing in prompt expansion
	zle reset-prompt
	return $ret
}
if [[ "${FCD_ALT_S_COMMAND-x}" != "" ]]; then
  zle     -N             fcd-widget
  bindkey -M emacs '\es' fcd-widget
  bindkey -M vicmd '\es' fcd-widget
  bindkey -M viins '\es' fcd-widget
fi

# ALT-Q - cd into the selected drive and/or directory
fcd-drives-widget() {
  setopt localoptions pipefail no_aliases 2> /dev/null
	local tmux_opts
  tmux_opts="$(__fcd_tmux_opts)"
  local dir="$(
    FCD_DEFAULT_OPTS=$(__fcd_defaults "--walker=drive,follow,nohidden" "${FCD_ALT_Q_OPTS-}") \
		FCD_DEFAULT_OPTS_FILE='' \
		command fcd ${tmux_opts:+"$tmux_opts"})"
  if [[ -z "$dir" ]]; then
	  zle redisplay
	  return 0
	fi
  dir=$(builtin cd -q >/dev/null -- "${dir}" && echo "${PWD}" || echo "${dir}")
	zle push-line # Clear buffer. Auto-restored on next prompt.
	BUFFER="builtin cd -- ${(q)dir}"
	zle accept-line
	local ret=$?
	unset dir # ensure this doesn't end up appearing in prompt expansion
	zle reset-prompt
	return $ret
}
if [[ "${FCD_ALT_Q_COMMAND-x}" != "" ]]; then
  zle     -N             fcd-drives-widget
  bindkey -M emacs '\eq' fcd-drives-widget
  bindkey -M vicmd '\eq' fcd-drives-widget
  bindkey -M viins '\eq' fcd-drives-widget
fi
fi

} always {
  eval $__fcd_key_bindings_options
  'unset' '__fcd_key_bindings_options'
}
