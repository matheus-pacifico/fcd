#     _____ _____ ____
#    / ___// ___// __ \
#   / /__ / /   / / / /
#  / ___// /__ / /_/ /
# /_/   /____//_____/ key-bindings.nu
#
# - $FCD_ALT_S_COMMAND
# - $FCD_ALT_S_OPTS
# - $FCD_ALT_Q_COMMAND
# - $FCD_ALT_Q_OPTS
# - $FCD_ALT_N_COMMAND
# - $FCD_ALT_N_OPTS
#
# Adapted from fzf shell integration:
# https://github.com/junegunn/fzf

# Key bindings
# ------------

def __fcd_defaults [prepend: string, append: string]: nothing -> string {
  let base = $"--height ($env.FCD_TMUX_HEIGHT? | default '40%') --min-height 20+ --ignore-ctrl-z ($prepend)"
  let opts_file = if ($env.FCD_DEFAULT_OPTS_FILE? | default '' | is-not-empty) {
    try { open --raw ($env.FCD_DEFAULT_OPTS_FILE) | str trim } catch { '' }
  } else {
    ''
  }
  let default_opts = $env.FCD_DEFAULT_OPTS? | default ''
  $"($base) ($opts_file) ($default_opts) ($append)" | str trim
}

def __fcdcmd []: nothing -> list<string> {
  let in_tmux = ($env.TMUX_PANE? | default '' | into string | is-not-empty)
  if $in_tmux {
    let fcd_tmux = ($env.FCD_TMUX? | default 0 | into string)
    let fcd_tmux_opts = ($env.FCD_TMUX_OPTS? | default '' | into string)
    if ($fcd_tmux != '0') or ($fcd_tmux_opts | is-not-empty) {
      let opts = if ($fcd_tmux_opts | is-not-empty) { $fcd_tmux_opts } else { $"-d($env.FCD_TMUX_HEIGHT? | default '40%')" }
      return ['fcd' '--tmux' ...(($opts | split row ' ' | where { $in != '' })) '--']
    }
  }
  ['fcd']
}

export-env {
  $env.FCD_ALT_S_OPTS     = $env.FCD_ALT_S_OPTS?     | default ""
  $env.FCD_ALT_Q_OPTS     = $env.FCD_ALT_Q_OPTS?     | default ""
  $env.FCD_ALT_N_OPTS     = $env.FCD_ALT_N_OPTS?     | default ""
}

# Directories
const alt_s = {
    name: fcd_dirs
    modifier: alt
    keycode: char_s
    mode: [emacs, vi_normal, vi_insert]
    event: [
      {
        send: executehostcommand
        cmd: "
          let fcd_opts = (__fcd_defaults '--walker=dir,follow,nohidden' $'($env.FCD_ALT_S_OPTS)');
          let fcdcmd = (__fcdcmd);
          let fcd_args = ($fcdcmd | skip 1);
          let alt_s_cmd = ($env.FCD_ALT_S_COMMAND? | default null);
          let result = if ($alt_s_cmd == null) or ($alt_s_cmd | is-empty) {
            with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^($fcdcmd | first) ...$fcd_args }
          };
          if ($result | is-not-empty) { cd $result };
        "
      }
    ]
}

# Drives
const alt_q = {
    name: fcd_drives
    modifier: alt
    keycode: char_q
    mode: [emacs, vi_normal, vi_insert]
    event: [
      {
        send: executehostcommand
        cmd: "
          let fcd_opts = (__fcd_defaults '--walker=drive,follow,nohidden' $'($env.FCD_ALT_Q_OPTS)');
          let fcdcmd = (__fcdcmd);
          let fcd_args = ($fcdcmd | skip 1);
          let alt_q_cmd = ($env.FCD_ALT_Q_COMMAND? | default null);
          let result = if ($alt_q_cmd == null) or ($alt_q_cmd | is-empty) {
            with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^($fcdcmd | first) ...$fcd_args }
          };
          if ($result | is-not-empty) { cd $result };
        "
      }
    ]
}

# Bookmarks
const alt_n = {
    name: fcd_bookmarks
    modifier: alt
    keycode: char_n
    mode: [emacs, vi_normal, vi_insert]
    event: [
      {
        send: executehostcommand
        cmd: "
          let fcd_opts = (__fcd_defaults '--walker=bookmark,follow,nohidden' $'($env.FCD_ALT_N_OPTS)');
          let fcdcmd = (__fcdcmd);
          let fcd_args = ($fcdcmd | skip 1);
          let alt_n_cmd = ($env.FCD_ALT_N_COMMAND? | default null);
          let result = if ($alt_n_cmd == null) or ($alt_n_cmd | is-empty) {
            with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^($fcdcmd | first) ...$fcd_args }
          };
          if ($result | is-not-empty) { cd $result };
        "
      }
    ]
}

# Helper to check if a binding is enabled. A binding is disabled when
# the corresponding *_COMMAND variable is explicitly set to "".
# When not defined (null), the binding is enabled (using fcd's built-in walker).
def __fcd_binding_enabled [var_name: string]: nothing -> bool {
  let val = ($env | get -o $var_name)
  # null = not defined = enabled; "" = explicitly disabled
  $val == null or ($val | into string | is-not-empty)
}

# Update the $env.config
export-env {
  let fcd_names = ['fcd_dirs', 'fcd_drives', 'fcd_bookmarks']
  # Filter out any existing fcd bindings, then re-add the enabled ones.
  mut bindings = ($env.config.keybindings | where { |kb| $kb.name not-in $fcd_names })
  if (__fcd_binding_enabled 'FCD_ALT_S_COMMAND') { $bindings = ($bindings | append $alt_s) }
  if (__fcd_binding_enabled 'FCD_ALT_Q_COMMAND') { $bindings = ($bindings | append $alt_q) }
  if (__fcd_binding_enabled 'FCD_ALT_N_COMMAND') { $bindings = ($bindings | append $alt_n) }
  $env.config.keybindings = $bindings
}
