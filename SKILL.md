---
name: remote
description: Remote Toolkit — drives remote servers via Mutagen file sync + SSH through the `rt` CLI; supports multiple servers via profiles, Slurm submission/monitoring on HPC hosts, and tmux-backed background commands. Use this skill whenever the user mentions a remote server, SSH target, HPC cluster, GPU box, the `rt` command, file sync to/from a remote machine, Slurm jobs (submit/queue/logs/cancel), `.sbatch` files, profile setup/connection, or asks to run/move/deploy something on a remote — even if they don't explicitly say "rt" or "remote toolkit". On the first prompt that triggers this skill, run `rt status --all` to enumerate configured profiles before assuming which one to use.
---

# Remote Toolkit — Full Guide for Claude Code

Drive remote servers via the `rt` command. Files sync via Mutagen; commands run via SSH/tmux; HPC clusters get optional Slurm subcommands.

Config directory: `~/.config/remote-toolkit/`

**First action when this skill triggers:** run `rt status --all` to see which profiles are configured. If multiple profiles exist and the user's intent doesn't pin down a target, ask which to use before doing anything else. Never sudo-install dependencies — surface missing tools to the user instead.

## Prerequisites

**Important:** These tools require admin rights. You (Claude Code) cannot install them — ask the user.

Run `rt check` to verify dependencies. If anything is missing, **stop and tell the user**:

Linux (Debian/Ubuntu):
```
sudo apt install -y tmux sshpass
# Mutagen: see https://mutagen.io/documentation/introduction/installation
```

macOS (requires Homebrew):
```
brew install mutagen-io/mutagen/mutagen
brew install tmux
brew install esolitos/ipa/sshpass
```

After install, run `rt check` again.

## First-Time Server Connection

When the user provides server info (e.g., `ssh user@host -p PORT`, password `xxx`):

### 1. Check dependencies
```bash
rt check
```

### 2. Create config file

Use Write to create config at `~/.config/remote-toolkit/`. Default profile uses `rt.conf`; named profiles use `rt.conf.<name>`.

Default profile:
```
File: ~/.config/remote-toolkit/rt.conf
REMOTE_HOST="user@host"
REMOTE_DIR="/home/user/project"
SSH_PORT=22
```

Named profile (multiple servers / HPC):
```
File: ~/.config/remote-toolkit/rt.conf.hpc
REMOTE_HOST="user@login.cluster"
REMOTE_DIR="/home/user/project"
SSH_PORT=22
SLURM_ENABLED=1
```

For non-default SSH_PORT or SSH_KEY, **also add a Host entry to `~/.ssh/config`** so Mutagen finds the right SSH parameters (Mutagen reads ssh config, not rt.conf):
```
Host login.cluster
    Port 2222
    IdentityFile ~/.ssh/cluster_key
```

### 3. Push SSH key (one-time)
```bash
rt setup-key --password 'password'
rt -p hpc setup-key --password 'password'
```

### 4. Connect
```bash
rt connect
rt -p hpc connect
```

`connect` starts the Mutagen daemon (if needed) and creates a sync session named `rt-<profile>`. Initial scan happens in the background; `rt status` shows progress.

## Daily Usage

### Connection Management

```bash
rt status              # Sync + SSH state for current profile
rt status --all        # All profiles
rt connect             # Idempotent — flushes if already connected
rt disconnect          # Terminates sync; preserves local files
```

### File Operations

The local replica directory:
- Default profile → `~/work/`
- Named profile → `~/work/<name>/` (e.g., `~/work/hpc/`)

These are **regular local directories**, not network mounts. Read / Edit / Write at full local-disk speed:
- `Read ~/work/src/main.py`
- `Edit ~/work/hpc/train.py`

Mutagen syncs changes to and from the remote in the background (typically < 1s for small files). Use `rt sync flush` to force reconciliation; `rt sync status` for diagnostics.

### Remote Command Execution

Short commands (< 30 seconds) — auto-flushes sync first:
```bash
rt exec "pwd"
rt -p hpc exec "nvidia-smi"
rt exec --no-flush "ls"           # skip flush for fast iteration
```

Long commands (builds, training daemons, services):
```bash
rt exec --bg --name build "make all"
rt -p hpc exec --bg --name train "python3 train.py"
```

Check background tasks:
```bash
rt logs                              # List background jobs for current profile
rt -p hpc logs rt_hpc_bg_train       # Show specific output
rt -p hpc logs rt_hpc_bg_train -f    # Follow (tail -f)
```

The working directory for `rt exec` is REMOTE_DIR, which mirrors the local `~/work/<profile>/` replica.

## Slurm (HPC) Workflows

Available when the profile has `SLURM_ENABLED=1`. Sync flush is automatic before submit.

```bash
rt -p hpc slurm submit train.sbatch                       # cd && sbatch train.sbatch
rt -p hpc slurm submit train.sbatch -- --time=04:00:00    # extra args after `--`
rt -p hpc slurm queue                                      # squeue -u $USER
rt -p hpc slurm queue --all                                # squeue (whole cluster)
rt -p hpc slurm logs                                       # list recent submissions
rt -p hpc slurm logs 12345                                 # cat slurm-12345.out
rt -p hpc slurm logs 12345 -f                              # tail -f
rt -p hpc slurm logs 12345 --err                           # show .err instead
rt -p hpc slurm cancel 12345                               # scancel 12345
```

`rt` does not generate sbatch scripts — write your own `*.sbatch` in `~/work/hpc/` and submit by path.

## Important Rules

1. **No interactive commands** — vim, less, top, python REPL won't work. Use non-interactive alternatives (`python3 -c "..."`, `head`, `cat`).

2. **Long-running commands** — use `rt exec --bg` (any host) or `rt slurm submit` (Slurm hosts). SSH timeouts will kill foreground commands over a few minutes.

3. **Sync timing** — Mutagen syncs in the background. `rt exec` auto-flushes before executing, so the remote sees the latest edits. If skipping flush (`--no-flush`), beware of stale code.

4. **Connection issues** — If `rt status` shows `sync=offline`, check network. `rt sync flush` to retry. `rt disconnect && rt connect` to recreate the session.

5. **Missing dependencies** — If `rt check` reports "not found", **do not attempt to sudo install**. Tell the user to run the install commands.

6. **Help** — `rt help` for command reference.
