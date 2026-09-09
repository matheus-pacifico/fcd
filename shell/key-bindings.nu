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

def __fcd_tmux_opts []: nothing -> string {
  let in_tmux = ($env.TMUX_PANE? | default '' | into string | is-not-empty)
  if not $in_tmux { return '' }

  let fcd_tmux = ($env.FCD_TMUX? | default 0 | into string)
  let fcd_tmux_opts = ($env.FCD_TMUX_OPTS? | default '' | into string)
  if ($fcd_tmux != '0') or ($fcd_tmux_opts | is-not-empty) {
		let opts = if ($fcd_tmux_opts | is-not-empty) { $fcd_tmux_opts } else { $"-d($env.FCD_TMUX_HEIGHT? | default '40%')" }
		$"--tmux=($opts) -- "
	} else {
		''
	}
}

export-env {
  $env.FCD_ALT_S_OPTS     = $env.FCD_ALT_S_OPTS?     | default ""
  $env.FCD_ALT_Q_OPTS     = $env.FCD_ALT_Q_OPTS?     | default ""
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
          let tmux_opts = __fcd_tmux_opts
				  let fcd_opts = (__fcd_defaults '--walker=dir,follow,nohidden' $'($env.FCD_ALT_S_OPTS)');
          let alt_s_cmd = ($env.FCD_ALT_S_COMMAND? | default null);
          let result = if ($alt_s_cmd == null) or ($alt_s_cmd | is-empty) {
					  if ($tmux_opts | is-empty) {
					  	with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^fcd }
				  	} else {
				  		with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^fcd $tmux_opts }
					  }
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
          let tmux_opts = __fcd_tmux_opts
				  let fcd_opts = (__fcd_defaults '--walker=drive,follow,nohidden' $'($env.FCD_ALT_Q_OPTS)');
          let alt_q_cmd = ($env.FCD_ALT_Q_COMMAND? | default null);
          let result = if ($alt_q_cmd == null) or ($alt_q_cmd | is-empty) {
					  if ($tmux_opts | is-empty) {
					  	with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^fcd }
				  	} else {
				  		with-env { FCD_DEFAULT_OPTS: $fcd_opts, FCD_DEFAULT_OPTS_FILE: '' } { ^fcd $tmux_opts }
					  }
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
  let fcd_names = ['fcd_dirs', 'fcd_drives']
  # Filter out any existing fcd bindings, then re-add the enabled ones.
  mut bindings = ($env.config.keybindings | where { |kb| $kb.name not-in $fcd_names })
  if (__fcd_binding_enabled 'FCD_ALT_S_COMMAND') { $bindings = ($bindings | append $alt_s) }
  if (__fcd_binding_enabled 'FCD_ALT_Q_COMMAND') { $bindings = ($bindings | append $alt_q) }
  $env.config.keybindings = $bindings
}
