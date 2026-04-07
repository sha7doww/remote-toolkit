# Remote Toolkit — Full Guide for Claude Code

Manage remote servers via `rt` command (SSHFS + SSH). Supports multiple profiles for simultaneous connections.

Config directory: `~/.config/remote-toolkit/`

## Prerequisites

**Important:** The following tools require `sudo` to install. You (Claude Code) cannot do this.

Run `rt check` to verify dependencies. If anything is missing, **stop and tell the user** to run:
```
sudo apt install -y sshfs sshpass tmux
```
After the user installs them, run `rt check` again to confirm.

## First-Time Server Connection

When the user provides server info (e.g., `ssh user@host -p PORT`, password `xxx`), follow these steps:

### 1. Check dependencies
```bash
rt check
```

### 2. Create config file

Use the Write tool to create a config at `~/.config/remote-toolkit/`. Default profile uses `rt.conf`, named profiles use `rt.conf.<name>` (e.g., `rt.conf.gpu1`).

Default profile (single server):
```
File path: ~/.config/remote-toolkit/rt.conf
Content:
REMOTE_HOST="user@host"
REMOTE_DIR="/home/user/project"
SSH_PORT=22
```

Named profile (multiple servers):
```
File path: ~/.config/remote-toolkit/rt.conf.gpu1
Content:
REMOTE_HOST="root@gpu-server"
REMOTE_DIR="/root/workspace"
SSH_PORT=22
```

### 3. Push SSH key (one-time)
```bash
rt setup-key --password 'password'
rt -p gpu1 setup-key --password 'password'
```

### 4. Connect
```bash
rt connect
rt -p gpu1 connect
```

## Daily Usage

### Connection Management

```bash
rt status              # Current profile status
rt status --all        # All profiles status
rt connect             # Connect default profile
rt -p gpu1 connect     # Connect named profile
rt disconnect          # Disconnect
rt -p gpu1 disconnect  # Disconnect specific profile
```

### File Operations

Remote files are mounted at:
- Default profile → `~/remote/`
- Named profile → `~/remote/<name>/` (e.g., `~/remote/gpu1/`)

Use Read / Edit / Write tools directly on these paths:
- `Read ~/remote/src/main.py`
- `Edit ~/remote/gpu1/train.py`

Changes sync to remote automatically via SSHFS.

### Remote Command Execution

Short commands (< 30 seconds):
```bash
rt exec "pwd"
rt -p gpu1 exec "nvidia-smi"
```

Long commands (builds, training, services):
```bash
rt exec --bg --name build "make all"
rt -p gpu1 exec --bg --name train "python3 train.py --epochs 100"
```

Check background tasks:
```bash
rt logs                              # List background tasks for current profile
rt -p gpu1 logs                      # List gpu1's background tasks
rt -p gpu1 logs rt_gpu1_bg_train     # View specific output
```

The working directory for commands is REMOTE_DIR, which corresponds to the mount directory. Relative paths work across both.

## Important Rules

1. **No interactive commands** — Do not run vim, less, top, or python REPL. Use non-interactive alternatives (`python3 -c "..."`, `head`, `cat`).

2. **Latency** — SSHFS has network latency. Avoid scanning large directories; read specific files instead.

3. **Large files** — Do not read files >10MB through the mount. Use `rt exec "head -100 big.log"` instead.

4. **No concurrent writes** — Do not edit a file via the mount while also writing to it via `rt exec`.

5. **Commands over 30 seconds must use `--bg`** — Prevents SSH timeout from killing the process.

6. **Connection issues** — If file operations fail, run `rt status` to check, then `rt disconnect && rt connect` to reconnect if needed.

7. **Missing dependencies** — If `rt check` or any command reports "not found", **do not attempt to sudo install**. Tell the user to install manually.

8. **Help** — Run `rt help` for all commands and usage.
