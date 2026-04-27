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

Subcommands: `init` `check` `setup-key` `connect` `disconnect` `exec` `logs` `status` `sync` `slurm` `help`

## Mutagen Integration

- `rt connect` ensures the Mutagen daemon is running (`mutagen daemon start`, idempotent), then creates a sync session named `rt-<profile>` with label `rt-profile=<profile>`.
- All Mutagen queries (`_has_sync`, `_sync_status`, `_sync_flush`, `_sync_terminate`) use `--label-selector rt-profile=<p>` rather than session names — labels are robust across renames and let `_status_all` enumerate by label without mutating `RT_PROFILE`.
- Mutagen URL form is `[user@]host:path` and reads SSH parameters from `~/.ssh/config`. For non-default `SSH_PORT` or `SSH_KEY`, the user must add a matching Host entry to ssh config; `rt connect` warns when this is needed.

## Slurm Integration

- Gated by per-profile `SLURM_ENABLED=1`. `cmd_slurm` calls `_slurm_require_enabled` first; non-Slurm hosts get a clear error.
- `rt slurm submit` performs a mandatory `_sync_flush` before `sbatch` to prevent stale-code submissions, then parses sbatch output for the job ID and appends to `.rt/<profile>/slurm_jobs` (cap 50 entries).

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
