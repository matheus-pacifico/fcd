#     _____ _____ ____
#    / ___// ___// __ \
#   / /__ / /   / / / /
#  / ___// /__ / /_/ /
# /_/   /____//_____/ key-bindings.bash
#
# - $FCD_ALT_S_COMMAND
# - $FCD_ALT_S_OPTS
# - $FCD_ALT_Q_COMMAND
# - $FCD_ALT_Q_OPTS
#
# Adapted from fzf shell integration:
# https://github.com/junegunn/fzf

if [[ $- =~ i ]]; then

# Key bindings
# ------------

__fcd_tmux_opts() {
  [[ -n ${TMUX_PANE-} ]] && { [[ ${FCD_TMUX:-0} != 0 ]] || [[ -n ${FCD_TMUX_OPTS-} ]]; } &&
    builtin printf -- '--tmux=%s -- ' "${FCD_TMUX_OPTS:--d${FCD_TMUX_HEIGHT:-40%}}" || builtin printf ''
}

__fcd_defaults() {
  builtin printf '%s\n' "--height ${FCD_TMUX_HEIGHT:-40%} --min-height 20+ --ignore-ctrl-z $1"
  command cat "${FCD_DEFAULT_OPTS_FILE-}" 2> /dev/null
  builtin printf '%s\n' "${FCD_DEFAULT_OPTS-} $2"
}

__fcd__() {
  local dir
  local tmux_opts
  tmux_opts="$(__fcd_tmux_opts)"
  dir=$(
    FCD_DEFAULT_OPTS=$(__fcd_defaults "--walker=dir,follow,nohidden" "${FCD_ALT_S_OPTS-}") \
      FCD_DEFAULT_OPTS_FILE='' command fcd ${tmux_opts:+"$tmux_opts"}
  ) && printf 'builtin cd -- %q' "$(builtin unset CDPATH && builtin cd -- "$dir" && builtin pwd)"
}

__fcd_drive__() {
  local dir
  local tmux_opts
  tmux_opts="$(__fcd_tmux_opts)"
  dir=$(
    FCD_DEFAULT_OPTS=$(__fcd_defaults "--walker=drive,follow,nohidden" "${FCD_ALT_Q_OPTS-}") \
      FCD_DEFAULT_OPTS_FILE='' command fcd ${tmux_opts:+"$tmux_opts"}
  ) && printf 'builtin cd -- %q' "$(builtin unset CDPATH && builtin cd -- "$dir" && builtin pwd)"
}

# Required to refresh the prompt after fcd
bind -m emacs-standard '"\C-\e(": redraw-current-line'

bind -m vi-command '"\C-z": emacs-editing-mode'
bind -m vi-insert '"\C-z": emacs-editing-mode'
bind -m emacs-standard '"\C-z": vi-editing-mode'

# ALT-S - cd into the selected directory
if [[ ${FCD_ALT_S_COMMAND-x} != "" ]]; then
  bind -m emacs-standard '"\es": " \C-b\C-k \C-u`__fcd__`\e\C-e\C-\e(\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d\C-y\ey\C-_"'
  bind -m vi-command '"\es": "\C-z\es\C-z"'
  bind -m vi-insert '"\es": "\C-z\es\C-z"'
fi

# ALT-Q - cd into the selected drive and/or directory
if [[ ${FCD_ALT_Q_COMMAND-x} != "" ]]; then
  bind -m emacs-standard '"\eq": " \C-b\C-k \C-u`__fcd_drive__`\e\C-e\C-\e(\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d\C-y\ey\C-_"'
  bind -m vi-command '"\eq": "\C-z\eq\C-z"'
  bind -m vi-insert '"\eq": "\C-z\eq\C-z"'
fi

fi
