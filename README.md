# Remote Toolkit

Let Claude Code control remote servers from any working directory. Supports multiple simultaneous server connections.

## How It Works

Remote directories are mounted locally via SSHFS so CC can use Read/Edit/Write directly on remote files. Commands are executed over SSH, with tmux keeping long-running tasks alive.

```
Local Claude Code
  ├── Read/Edit/Write  →  ~/remote/       ← SSHFS →  ServerA:/project
  ├── Read/Edit/Write  →  ~/remote/gpu1/  ← SSHFS →  ServerB:/workspace
  └── rt exec          →  SSH + tmux      →          remote shell
```

## Install

```bash
# 1. Install system dependencies (CC can't sudo — you need to do this)

# Linux (Debian/Ubuntu)
sudo apt install -y sshfs sshpass tmux

# macOS (requires Homebrew)
brew install macfuse
brew install gromgit/fuse/sshfs-mac
brew install esolitos/ipa/sshpass
brew install tmux

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

**Multiple servers:** Give each server a name, CC manages them as profiles.

> **You:** Connect to this GPU server, call it gpu1: root@10.0.0.5 port 22, password xxx, working directory /root/workspace

Then refer to it by name:

> **You:** Run `python train.py --epochs 100` on gpu1

> **You:** Disconnect gpu1

Disconnecting only unmounts the filesystem. Config files are preserved — just say "connect gpu1" to reconnect.

## Things You May Need to Do Manually

| Scenario | Action |
|----------|--------|
| CC reports missing dependencies (Linux) | `sudo apt install -y sshfs sshpass tmux` |
| CC reports missing dependencies (macOS) | `brew install macfuse gromgit/fuse/sshfs-mac esolitos/ipa/sshpass tmux` |
| First time connecting to a server | Tell CC the address, port, and password |
| Mount problems | Tell CC to reconnect, or run `rt disconnect && rt connect` |

Everything else (config creation, SSH key setup, file editing, command execution, background task management) is handled by CC through the `rt` command.

## Configuration

Config directory: `~/.config/remote-toolkit/`

One config file per server:

| File | Purpose | Mount point |
|------|---------|-------------|
| `rt.conf` | Default server | `~/remote/` |
| `rt.conf.gpu1` | Named profile | `~/remote/gpu1/` |
| `rt.conf.gpu2` | Named profile | `~/remote/gpu2/` |

Config contents (typically created by CC automatically):
```bash
REMOTE_HOST="root@192.168.1.100"   # required
REMOTE_DIR="/root/workspace"        # required
SSH_PORT=22                         # optional, default 22
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| CC says `sshfs: command not found` (Linux) | `sudo apt install sshfs` |
| CC says `sshfs: command not found` (macOS) | `brew install macfuse && brew install gromgit/fuse/sshfs-mac` |
| SSH connection failed | Check network: `ssh -p PORT user@host "echo ok"` |
| File operations timeout/hang | Tell CC to reconnect, or `rt disconnect && rt connect` |
| Unmount fails (device busy) | Close all processes accessing `~/remote/` and retry |
