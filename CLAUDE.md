# Remote Toolkit — Developer Guide

This file is for **CC developing this tool**, not for using it. The usage guide is in `cc/remote.md`.

## Project Structure

```
rt                    Main script (Bash), all functionality
rt.conf.example       Config template
install.sh            Installer: symlink, config migration, CC integration
cc/
  claude-global.md    → Installed into ~/.claude/CLAUDE.md (English, ~10 lines)
  remote.md           → Installed into ~/.claude/commands/remote.md (full guide)
CLAUDE.md             This file (developer guide)
README.md             User-facing documentation
```

## rt Script Architecture

- **RT_HOME**: Root directory for config and state, defaults to `~/.config/remote-toolkit/`, overridable via env var
- **RT_SCRIPT_DIR**: Script's own directory, only used by `init` command to find `rt.conf.example`
- **Profile system**: `-p <name>` selects a profile, affecting config path (`rt.conf.<name>`), state dir (`.rt/<name>/`), mount point (`~/remote/<name>/`), and tmux session prefix
- **Dispatch**: `main()` parses global flags then routes to `cmd_*` functions

Subcommands: `init` `check` `setup-key` `connect` `disconnect` `exec` `logs` `status` `help`

## CC Integration Files (cc/ directory)

These are source files installed into the user's environment by `install.sh`:

- **`cc/claude-global.md`**: HTML-marked section appended to `~/.claude/CLAUDE.md`. Keep it minimal (~10 lines) since it loads on every CC startup.
- **`cc/remote.md`**: Full content of the `/remote` slash command. Only injected when the user explicitly invokes it.

After editing these files, re-run `./install.sh` to deploy updates.

## Development Conventions

- Run `bash -n rt` after modifying the rt script to check syntax
- Use `RT_HOME` for all paths — never hardcode `RT_DIR` or the script directory
- No Python/Node or other runtime dependencies — keep it pure Bash
- Config file format is source-able Bash variable assignments
