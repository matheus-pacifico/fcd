#     _____ _____ ____
#    / ___// ___// __ \
#   / /__ / /   / / / /
#  / ___// /__ / /_/ /
# /_/   /____//_____/ key-bindings.fish
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

function fcd_key_bindings

  # The oldest supported fish version is 3.4.0. For this message being able to be
  # displayed on older versions, the command substitution syntax $() should not
  # be used anywhere in the script, otherwise the source command will fail.
  if string match -qr -- '^[12]\\.|^3\\.[0-3]' $version
    echo "fcd key bindings script requires fish version 3.4.0 or newer." >&2
    return 1
  else if not command -q fcd
    echo "fcd was not found in path." >&2
    return 1
  end

	function __fcd_defaults
    # $argv[1]: Prepend to FCD_DEFAULT_OPTS_FILE and FCD_DEFAULT_OPTS
    # $argv[2..]: Append to FCD_DEFAULT_OPTS_FILE and FCD_DEFAULT_OPTS
    test -n "$FCD_TMUX_HEIGHT"; or set -l FCD_TMUX_HEIGHT 40%
    string join ' ' -- \
      "--height $FCD_TMUX_HEIGHT --min-height=20+ --ignore-ctrl-z" $argv[1] \
      (test -r "$FCD_DEFAULT_OPTS_FILE"; and string join -- ' ' <$FCD_DEFAULT_OPTS_FILE) \
      $FCD_DEFAULT_OPTS $argv[2..]
  end

	function __fcd_tmux_opts
    test -n "$FCD_TMUX_HEIGHT"; or set -l FCD_TMUX_HEIGHT 40%
    if test -n "$FCD_TMUX_OPTS"
      echo "--tmux $FCD_TMUX_OPTS -- "
    else if test "$FCD_TMUX" = "1"
      echo "--tmux -d$FCD_TMUX_HEIGHT -- "
    else
      echo ""
    end
  end

  function __fcd_parse_commandline -d 'Parse the current command line token and return split of existing filepath, fcd query, and optional -option= prefix'
    set -l fcd_query ''
    set -l prefix ''
    set -l dir '.'

    set -l -- match_regex '(?<fcd_query>[\\s\\S]*?(?=\\n?$)$)'
    set -l -- prefix_regex '^-[^\\s=]+=|^-(?!-)\\S'

    # Don't use option prefix if " -- " is preceded.
    string match -qv -- '* -- *' (string sub -l (commandline -Cp) -- (commandline -p))
    and set -- match_regex "(?<prefix>$prefix_regex)?$match_regex"

    # Set $prefix and expanded $fcd_query with preserved trailing newlines.
    if string match -qr -- '^\\d\\d+|^[4-9]' $version
      # fish v4.0.0 and newer
      string match -q -r -- $match_regex (commandline --current-token --tokens-expanded | string collect -N)
    else
      string match -q -r -- $match_regex (commandline --current-token --tokenize | string collect -N)
      eval set -- fcd_query (string escape -n -- $fcd_query | string replace -r -a '^\\\\(?=~)|\\\\(?=\\$\\w)' '')
    end

    if test -n "$fcd_query"
      # Normalize path in $fcd_query, set $dir to the longest existing directory.
      if string match -qr -- '^\\d\\d+|^4|^3\\.[5-9]' $version
        # fish v3.5.0 and newer
        set -- fcd_query (path normalize -- $fcd_query)
        set -- dir $fcd_query
        while not path is -d $dir
          set -- dir (path dirname $dir)
        end
      else
        string match -q -r -- '(?<fcd_query>^[\\s\\S]*?(?=\\n?$)$)' \
          (string replace -r -a -- '(?<=/)/|(?<!^)/+(?!\\n)$' '' $fcd_query | string collect -N)
        set -- dir $fcd_query
        while not test -d "$dir"
          set -- dir (dirname -z -- "$dir" | string split0)
        end
      end

      if not string match -q -- '.' $dir; or string match -qr -- '^\\.(/|$)' $fcd_query
        # Strip $dir from $fcd_query - preserve trailing newlines.
        if string match -qr -- '^\\d\\d+|^[4-9]' $version
          # fish v4.0.0 and newer
          string match -q -r -- '^'(string escape --style=regex -- $dir)'/?(?<fcd_query>[\\s\\S]*)' $fcd_query
        else
          string match -q -r -- '^/?(?<fcd_query>[\\s\\S]*?(?=\\n?$)$)' \
            (string replace -- "$dir" '' $fcd_query | string collect -N)
        end
      end
    end

    string escape -n -- "$dir" "$fcd_query" "$prefix"
  end

  function fcd-widget -d "Change directory"
    set -l commandline (__fcd_parse_commandline)
    set -lx dir $commandline[1]
    set -l fcd_query $commandline[2]
    set -l prefix $commandline[3]
		set -l tmux_opts (__fcd_tmux_opts)

		set -lx FCD_DEFAULT_OPTS (__fcd_defaults "$tmux_opts" \
      "--walker=dir,follow,nohidden" \
      "$FCD_ALT_S_OPTS --print0")

    set -lx FCD_DEFAULT_OPTS_FILE

    if set -l result (command fcd | string split0)
      cd -- $result
      commandline -rt -- $prefix
    end

    commandline -f repaint
  end

  function fcd-drives-widget -d "Change drive directory"
    set -l commandline (__fcd_parse_commandline)
    set -lx dir $commandline[1]
    set -l fcd_query $commandline[2]
    set -l prefix $commandline[3]
		set -l tmux_opts (__fcd_tmux_opts)

		set -lx FCD_DEFAULT_OPTS (__fcd_defaults "$tmux_opts" \
      "--walker=drive,follow,nohidden" \
      "$FCD_ALT_Q_OPTS --print0")

    set -lx FCD_DEFAULT_OPTS_FILE

    if set -l result (command fcd | string split0)
      cd -- $result
      commandline -rt -- $prefix
    end

    commandline -f repaint
  end

  if not set -q FCD_ALT_S_COMMAND; or test -n "$FCD_ALT_S_COMMAND"
    bind \es fcd-widget
    bind -M insert \es fcd-widget
  end

  if not set -q FCD_ALT_Q_COMMAND; or test -n "$FCD_ALT_Q_COMMAND"
    bind \eq fcd-drives-widget
    bind -M insert \eq fcd-drives-widget
  end

end

# Run setup
fcd_key_bindings
