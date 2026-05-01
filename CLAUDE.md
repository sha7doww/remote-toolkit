# Remote Toolkit — Developer Guide

This file is for **CC developing this tool**, not for using it. The usage guide is in `SKILL.md`.

## Project Structure

```
rt                    Main script (Bash), all functionality
rt.conf.example       Config template
install.sh            Installer: symlink, config migration, CC SKILL install
SKILL.md              Claude Code SKILL — frontmatter (name=remote, description) + full guide.
                      install.sh symlinks the whole repo to ~/.claude/skills/remote/.
commands/
  remote.md           Slash-command shim. install.sh symlinks to ~/.claude/commands/remote.md.
                      `/remote` invokes the SKILL.
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

## CC Integration: SKILL + slash command

`install.sh` installs as a Claude Code SKILL, mirroring the codex-review pattern. There is no `~/.claude/CLAUDE.md` injection.

- **`SKILL.md`** (repo root): frontmatter (`name: remote` + a "pushy" description that lists trigger phrases) + the full operational guide. install.sh symlinks the whole repo to `~/.claude/skills/remote/`. Loaded eagerly as metadata in CC's skill list; the body loads when the description matches the user's prompt or when `/remote` is invoked.
- **`commands/remote.md`**: thin slash-command shim with frontmatter (`description`, `argument-hint`, `allowed-tools`). install.sh symlinks it to `~/.claude/commands/remote.md`. Typing `/remote` triggers the SKILL.

If symlinked (default `--symlink` install mode), edits to `SKILL.md` and `commands/remote.md` take effect immediately — no re-run of `install.sh` needed. With `--copy`, re-run install.sh after edits.

`install.sh` also performs a one-shot migration from the old install form: it strips the `<!-- remote-toolkit start/end -->` block from `~/.claude/CLAUDE.md` and removes a stale regular-file `~/.claude/commands/remote.md` (left by the old `cp`-based install) before creating the new symlinks.

Skill design follows the official Anthropic skill-creator standards (progressive disclosure, "pushy" description that lists trigger phrases, imperative writing style). Reference: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`.

## Development Conventions

- Run `bash -n rt` after modifying the rt script to check syntax
- Use `RT_HOME` for all paths — never hardcode `RT_DIR` or the script directory
- No Python/Node or other runtime dependencies — keep it pure Bash
- Config file format is source-able Bash variable assignments
