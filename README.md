# Remote Toolkit

Let Claude Code drive remote servers from any working directory. Mutagen sync for files; SSH/tmux for commands; opt-in Slurm subcommands for HPC clusters.

## How It Works

Local replica directories sync to remote via Mutagen, so CC can use Read/Edit/Write at local-disk speed. Commands run over SSH, with tmux keeping long-running tasks alive. For HPC clusters, opt-in Slurm subcommands wrap `sbatch`/`squeue`/`scancel`.

```
Local Claude Code
  ├── Read/Edit/Write  →  ~/work/        ⇄ Mutagen ⇄  loginA:/project
  ├── Read/Edit/Write  →  ~/work/hpc/    ⇄ Mutagen ⇄  loginB:/workspace  ─┐
  ├── rt exec          →  SSH + tmux     →  remote shell                  │ shared FS
  └── rt slurm submit  →  flush; sbatch  →  Slurm ─────────────────────→  compute (H100/H20/...)
```

## Install

```bash
# 1. Install system dependencies (CC can't sudo — you need to do this)

# Linux (Debian/Ubuntu)
sudo apt install -y tmux sshpass
# Plus Mutagen: https://mutagen.io/documentation/introduction/installation

# macOS (requires Homebrew)
brew install mutagen-io/mutagen/mutagen
brew install tmux
brew install esolitos/ipa/sshpass

# 2. Clone and install
git clone <repo-url>
cd remote-toolkit
./install.sh
```

`install.sh` does the following:
- Symlinks `~/.local/bin/rt` → makes the `rt` command available globally
- Adds `~/.local/bin` to PATH in `~/.bashrc` (or `~/.zshrc`) if not already present
- Creates config directory `~/.config/remote-toolkit/`, migrates existing configs
- Writes to `~/.claude/CLAUDE.md` → CC automatically knows about `rt` in any workspace
- Writes to `~/.claude/commands/remote.md` → type `/remote` for CC to get the full guide

## Usage

After installing, just tell CC your server info:

> **You:** Connect to root@192.168.1.100 port 22, password xxx, and edit /root/app/config.yaml

CC handles everything: create config → push SSH key → connect → edit the file.

On first connection, CC copies your local SSH public key (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`) to the remote server's `~/.ssh/authorized_keys` using the password you provide. After that, all connections are passwordless. The password is only used once and is not stored.

**Multiple servers:** Give each server a name; CC manages them as profiles.

> **You:** Connect to this HPC login node, call it hpc: user@login.cluster, password xxx, working directory /home/user/project, this cluster uses Slurm

Then refer to it by name:

> **You:** Submit train.sbatch to the queue on hpc

> **You:** Disconnect hpc

Disconnecting only terminates the sync session. Your local replica files at `~/work/<name>/` are preserved — say "connect hpc" to reconnect.

## Things You May Need to Do Manually

| Scenario | Action |
|----------|--------|
| CC reports missing dependencies (Linux) | `sudo apt install -y tmux sshpass` + install Mutagen from mutagen.io |
| CC reports missing dependencies (macOS) | `brew install mutagen-io/mutagen/mutagen tmux esolitos/ipa/sshpass` |
| First time connecting to a server | Tell CC the address, port, and password |
| Non-default SSH port / key | Add a `Host` entry to `~/.ssh/config` so Mutagen sees the same SSH params |
| Sync stuck or out of sync | Tell CC to run `rt sync flush` or `rt disconnect && rt connect` |

Everything else (config creation, SSH key setup, file editing, command execution, background task management, Slurm submission) is handled by CC through the `rt` command.

## Configuration

Config directory: `~/.config/remote-toolkit/`

One config file per server:

| File | Purpose | Local replica |
|------|---------|---------------|
| `rt.conf` | Default server | `~/work/` |
| `rt.conf.hpc` | Named profile | `~/work/hpc/` |
| `rt.conf.gpu2` | Named profile | `~/work/gpu2/` |

Required:
```bash
REMOTE_HOST="user@hostname"   # or ~/.ssh/config alias
REMOTE_DIR="/home/user/project"
```

Optional (SSH):
```bash
SSH_PORT=22
SSH_KEY="$HOME/.ssh/id_ed25519"
```

Optional (Mutagen):
```bash
LOCAL_DIR="$HOME/work"             # default: ~/work or ~/work/<profile>
MUTAGEN_SYNC_MODE="two-way-resolved"
MUTAGEN_IGNORE_VCS=1
MUTAGEN_IGNORE=("data/" "*.bin")   # appended to defaults
```

Optional (Slurm — HPC only):
```bash
SLURM_ENABLED=1                    # enables `rt slurm *`
SLURM_LOG_DIR="$REMOTE_DIR"        # where slurm-<id>.out lands
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `rt check` says `mutagen: command not found` | Install Mutagen (see Install section) |
| SSH connection failed | Check network: `ssh -p PORT user@host "echo ok"` |
| `rt status` shows `sync=offline` | `rt sync flush` to retry; check network; verify `~/.ssh/config` matches `rt.conf` |
| Mutagen connects but files don't sync | `rt sync status` for details; check `MUTAGEN_IGNORE` patterns |
| Slurm subcommands say "not enabled" | Set `SLURM_ENABLED=1` in `rt.conf.<profile>` |
| `rt slurm submit` ran old code | Sync may not have flushed; check `rt sync status` and re-run |
| **macOS:** replica ends up inside `~/Work/` mixed with your projects | APFS is case-insensitive by default, so the `~/work/<profile>/` default resolves to `~/Work/<profile>/` if you have a `~/Work/` dir. Set `LOCAL_DIR="$HOME/Work/Remote/<profile>"` (or any other path) explicitly in `rt.conf.<profile>` to override. |
| Mutagen halts with "one-sided root emptying" after you bulk-deleted files on one side | Safety feature: prevents accidental wipe via deletion propagation. Recover with `mutagen sync reset --label-selector=rt-profile=<profile>`, or `rm` the corresponding files on the other side too. |
