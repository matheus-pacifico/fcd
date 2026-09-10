# fcd

An interactive directory navigator powered by [fzf](https://github.com/junegunn/fzf).

`fcd` provides a seamless TUI for navigating directories and drives with fuzzy search, live previews, sorting, clipboard integration, navigation history and customizable behavior.

## Key Features

- **Fuzzy Search Navigation:** Fast folder traversal powered by `fzf`.
- **Dual Walker Support:** Easily switch between standard directory browsing and full system drive/partition selection.
- **Dynamic Previews:** Flexible preview window supporting `tree`, `list`, or `grid` modes with adjustable search depth and hidden item toggles.
- **Clipboard Integration:** Instant path copying (`wl-copy`, `xclip`, `xsel`).
- **Path Truncation:** Smart header/footer path position formatting with customizable alignment and truncation.
- **Tmux Ready:** Native floating pane support via `fzf-tmux`.

## Installation

### Requirements

**Required:**

- `bash`
- `fzf`  (0.72.0+)
- `find`

**Optional:**

- `tree` (for tree-style directory previews)
- `wl-copy`, `xclip`, or `xsel` (for clipboard copying support)
- `lsblk` (for drive/partition detection)
- `sort`

### Using git

You can "git clone" this repository to any directory and run
[install](https://github.com/matheus-pacifico/fcd/blob/main/install) script.

```sh
git clone --depth 1 https://github.com/matheus-pacifico/fcd.git ~/.fcd
~/.fcd/install
```

The install script will add lines to your shell configuration file to modify `$PATH` and set up shell integration.

### Releases

You can download official release archives directly from the releases page.

- https://github.com/matheus-pacifico/fcd/releases

## Upgrading fcd

Please follow the instruction below to upgrade fcd.

git: `cd ~/.fcd && git pull && ./install`

## Usage

After selecting a target, `fcd` prints its path to standard output. It does not change the current directory of the calling shell by itself. Shell integrations and [Key bindings](#key-bindings-for-command-line) can use this output to change directories automatically.

To change directories directly from standard execution, wrap it in your shell configuration (e.g. `~/.bashrc` or `~/.zshrc`):

```bash
alias fcd='cd "$(command fcd)"'
```

> [!NOTE]
> Since `fcd` operates through standard shell output and terminal keybindings, it works seamlessly in integrated terminals in IDEs such as **VS Code**, **Cursor**, and **JetBrains IDEs**.

### Examples

Basic execution in current directory
```sh
fcd
```

Start browsing from a specific path
```sh
fcd --walker-root ~/Projects
```

Limit traversal depth and start with a preview
```sh
fcd --max-depth=2 --preview=dir,tree
```

Pass options directly to fzf-tmux
```sh
fcd --tmux="-p 60% -- --layout=bottom"
```

Start with a specific search query:
```sh
fcd --query="project"
```

Here's an example of the default mode:

<img width="967" height="625" alt="Image" src="https://github.com/user-attachments/assets/836bd2a8-2331-4129-8166-f9f658323c4e" />

Here's an example of the drive mode:

<img src="https://github.com/user-attachments/assets/6d506bae-7f21-4601-a911-173133a99218" />

<details>

```sh
fcd --walker=drive \
    --preview="dir,file,tree,asc,2" \
    --preview-window="down:55%:border-rounded" \
    --height=85% --border=dashed
```

</details>

### In-Finder Controls

| **Key**                 | **Action**                                  |
| ----------------------- | ------------------------------------------- |
| `Enter`                 | Select the highlighted directory and exit   |
| `Left Arrow`            | Navigate to parent directory                |
| `Right Arrow`           | Open highlighted directory                  |
| `Ctrl-H`                | Toggle hidden directories                   |
| `Alt-H`                 | Toggle hidden directories/files in preview  |
| `Ctrl-Y`                | Copy target directory path to clipboard     |
| `Alt-Y`                 | Copy highlighted path to clipboard          |
| `Ctrl-P`                | Toggle preview window                       |
| `Ctrl-Home`             | Jump directly to home directory             |
| `Alt-Home`              | Reset navigation back to starting directory |
| `Ctrl-R`                | Reload current directory or drive list      |
| `Ctrl-C`/`Ctrl-G`/`Esc` | Exit without selecting                      |

## Configuration & Options

### Navigation

By default, `fcd` starts directory navigation from the current directory.

A different root can be specified with:

```sh
fcd --walker-root ~/Projects
```

Directories can also be excluded from traversal:

```sh
fcd --walker-skip .git,node_modules
```

The traversal mode can be configured with `--walker`:

```sh
fcd --walker=dir
fcd --walker=drive
```

Additional options control symbolic-link handling and hidden directories.

### Preview

The preview window can be configured independently from directory navigation.

For example, to use a deeper preview:

```sh
fcd --preview=dir,follow,sort,asc,list,3
```

The final numeric value specifies the maximum preview depth. A value of `0` means unlimited depth.

Preview behavior can also be configured for:

- directories
- files
- hidden entries
- symbolic links
- sorting
- ascending or descending order
- list, tree, or grid display

The preview window itself can be positioned and configured using `--preview-window`.

### Sorting

Sorting can be enabled or disabled with:

```sh
fcd --sort
fcd --no-sort
```

The sort order can be changed with:

```sh
fcd --sort-order=asc
fcd --sort-order=desc
```

Sorting is enabled by default and uses ascending order.

### Output

By default, `fcd` outputs the selected target directory.

The output behavior can be customized with:

```sh
fcd --print-current
```

to print the current directory even when it is selected, or:

```sh
fcd --print-current-dot
```

to print `.` when the target directory is the current directory.

For use in scripts that require NUL-delimited output:

```sh
fcd --print0
```

### tmux Integration

`fcd` can optionally run through [`fzf-tmux`](https://github.com/junegunn/fzf/blob/master/bin/fzf-tmux).

```sh
fcd --tmux
```

Options supplied to `--tmux` are passed directly to `fzf-tmux`.

Use `--` inside the option list to separate `fzf-tmux` options from `fcd` options.

> [!TIP]
> For a complete list of command-line options and their syntax, run:
> ```sh
> fcd --help
> ```

## Key bindings for command-line

By setting up shell integration, you can use the following key bindings in bash, zsh, fish and Nushell.

- `ALT-S` - cd into the selected directory
  - The list is generated using `--walker dir,follow,nohidden` option
  - Set `FCD_ALT_S_OPTS` to pass additional options to fcd
    ```sh
    # Set preview to tree structure
    export FCD_ALT_S_OPTS="
      --walker-skip .git,node_modules,target
      --preview dir,file,tree"
    ```
  - Can be disabled by setting `FCD_ALT_S_COMMAND` to an empty string when sourcing the script
- `ALT-Q` - cd into the selected drive and/or directory
  - The list is generated using `--walker drive,follow,nohidden` option
  - Set `FCD_ALT_Q_OPTS` to pass additional options to fcd
    ```sh
    # Set preview to grid structure with no sort
    export FCD_ALT_Q_OPTS="
      --walker-skip .git,node_modules,target
      --preview file,grid,nosort,auto"
    ```
  - Can be disabled by setting `FCD_ALT_Q_COMMAND` to an empty string when sourcing the script

Display modes for these bindings can be separately configured via `FCD_{ALT_S,ALT_Q}_OPTS` or globally via `FCD_DEFAULT_OPTS`. (e.g. `FCD_ALT_Q_OPTS='--layout top-list --height 60% --border rounded'`)

## Why Pure Bash?

`fcd` is intentionally implemented as a Bash script rather than a compiled application. This keeps the tool close to the shell environment it is designed to extend and makes its behavior easy to inspect and customize.

Some of the main reasons for this choice are:

- **Easy customization:** The implementation is directly accessible to the user. Those who want to customize `fcd` can open the script and modify its behavior, add or remove options, or adjust the `fzf` configuration without having to rebuild the application.
- **Wide availability:** Bash is widely available on Linux systems and is already a natural part of the command-line environment `fcd` is designed for.
- **Shell integration:** As a shell-native tool, Bash makes it straightforward to interact with the current working directory, environment variables, command-line options, and other Unix command-line utilities.
- **fzf integration:** `fcd` builds on top of `fzf`, allowing much of the interactive interface to be configured through shell-level options and commands.

The goal is not to hide the implementation behind a compiled binary, but to keep `fcd` transparent, hackable, and easy to adapt to individual workflows.

## Platform Support

Currently, `fcd` has full support for **Linux**.

While it may run on macOS or WSL with proper dependencies (GNU coreutils, `fzf`, `bash`), Linux is the primary target platform for path resolution, hardware drive detection (`lsblk`), and clipboard integration.

## Acknowledgments

`fcd` adapts the shell integration, installer, and keybinding script patterns from fzf to fit its directory navigation workflow.

Special thanks to Junegunn Choi and the `fzf` contributors for creating such outstanding shell tooling and inspiration.

## License

MIT License

Copyright (c) 2026 Matheus Pacifico
