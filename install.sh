#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RT_HOME="${RT_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/remote-toolkit}"
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="$HOME/.claude"

info()  { printf '\e[32m:: %s\e[0m\n' "$*"; }
warn()  { printf '\e[33m!! %s\e[0m\n' "$*"; }

printf '\n  Remote Toolkit — Install\n\n'

# ── 1. Check dependencies ────────────────────────────────────────
chmod +x "$SCRIPT_DIR/rt"
"$SCRIPT_DIR/rt" check || true
printf '\n'

# ── 2. Create config directory & migrate existing configs ─────────
mkdir -p "$RT_HOME"

migrated=0
for conf in "$SCRIPT_DIR"/rt.conf "$SCRIPT_DIR"/rt.conf.*; do
  [[ -f "$conf" ]] || continue
  base=$(basename "$conf")
  [[ "$base" == "rt.conf.example" ]] && continue
  if [[ ! -f "$RT_HOME/$base" ]]; then
    cp "$conf" "$RT_HOME/$base"
    info "Migrated $base → $RT_HOME/$base"
    migrated=$((migrated + 1))
  fi
done

if [[ $migrated -eq 0 ]]; then
  # No configs to migrate; init if empty
  "$SCRIPT_DIR/rt" init 2>&1
fi

# ── 3. Symlink to PATH ───────────────────────────────────────────
mkdir -p "$BIN_DIR"
if [[ -L "$BIN_DIR/rt" || -f "$BIN_DIR/rt" ]]; then
  rm "$BIN_DIR/rt"
fi
ln -s "$SCRIPT_DIR/rt" "$BIN_DIR/rt"
info "Symlinked: $BIN_DIR/rt → $SCRIPT_DIR/rt"

# Check if ~/.local/bin is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  # Add to .bashrc
  SHELL_RC="$HOME/.bashrc"
  [[ -n "${ZSH_VERSION:-}" ]] && SHELL_RC="$HOME/.zshrc"
  if ! grep -q 'export PATH="$HOME/.local/bin' "$SHELL_RC" 2>/dev/null; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_RC"
    warn "$BIN_DIR not in PATH. Added to $SHELL_RC."
    warn "Run: source $SHELL_RC"
  fi
fi

# ── 4. Claude Code integration ───────────────────────────────────
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"

# 4a. Global CLAUDE.md (minimal, English)
MARKER_START="<!-- remote-toolkit start -->"
MARKER_END="<!-- remote-toolkit end -->"
RT_SECTION="$MARKER_START
## Remote Server Management

The \`rt\` command is available globally for managing remote servers via SSHFS + SSH.

- Connect: \`rt connect\` / \`rt -p <profile> connect\`
- Remote files: \`~/remote/\` (default) or \`~/remote/<profile>/\`
- Run commands: \`rt exec \"cmd\"\` / \`rt exec --bg --name NAME \"long cmd\"\`
- Status: \`rt status --all\`
- Full guide: use \`/remote\` slash command
- Quick ref: \`rt help\`

Rules: No interactive commands (vim, top, python REPL). Commands >30s must use \`--bg\`. Never sudo-install deps — ask the user. Config at ~/.config/remote-toolkit/.

When the user mentions a remote server or asks to work remotely, run \`rt status --all\` to see available profiles. Ask which profile to use if unclear.
$MARKER_END"

if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  # Remove old section if present, then append
  if grep -q "$MARKER_START" "$CLAUDE_DIR/CLAUDE.md"; then
    # Remove existing section (sed between markers inclusive)
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$CLAUDE_DIR/CLAUDE.md"
  fi
  printf '\n%s\n' "$RT_SECTION" >> "$CLAUDE_DIR/CLAUDE.md"
  info "Updated $CLAUDE_DIR/CLAUDE.md (remote-toolkit section)"
else
  printf '%s\n' "$RT_SECTION" > "$CLAUDE_DIR/CLAUDE.md"
  info "Created $CLAUDE_DIR/CLAUDE.md"
fi

# 4b. Slash command /remote
cat > "$CLAUDE_DIR/commands/remote.md" <<'SLASHCMD'
# Remote Toolkit — Claude Code 完整指南

本指南通过 `rt` 命令管理远程服务器（SSHFS + SSH），支持多 profile 同时连接不同服务器。

配置目录：`~/.config/remote-toolkit/`

## 前置依赖

**重要：** 以下工具需要 `sudo` 安装，你（Claude Code）无法自动完成。

运行 `rt check` 检查依赖状态。如果有缺失项，**停下来告知用户**执行：
```
sudo apt install -y sshfs sshpass tmux
```
用户安装完成后，再次运行 `rt check` 确认。

## 首次连接新服务器

当用户提供服务器信息（如 `ssh user@host -p PORT`，密码 `xxx`）时，按以下步骤操作：

### 1. 检查依赖
```bash
rt check
```

### 2. 创建配置文件

用 Write 工具创建配置。默认 profile 用 `rt.conf`，命名 profile 用 `rt.conf.<name>`。

默认 profile（单台服务器时使用）：
```
文件路径: ~/.config/remote-toolkit/rt.conf
内容:
REMOTE_HOST="user@host"
REMOTE_DIR="/home/user/project"
SSH_PORT=22
```

命名 profile（多台服务器时使用）：
```
文件路径: ~/.config/remote-toolkit/rt.conf.gpu1
内容:
REMOTE_HOST="root@gpu-server"
REMOTE_DIR="/root/workspace"
SSH_PORT=22
```

### 3. 推送 SSH 密钥（一次性）
```bash
rt setup-key --password '密码'
rt -p gpu1 setup-key --password '密码'
```

### 4. 连接
```bash
rt connect
rt -p gpu1 connect
```

## 日常使用

### 连接管理

```bash
rt status              # 当前 profile 状态
rt status --all        # 所有 profile 状态
rt connect             # 连接默认 profile
rt -p gpu1 connect     # 连接命名 profile
rt disconnect          # 断开
rt -p gpu1 disconnect  # 断开指定 profile
```

### 文件操作

远程文件挂载位置：
- 默认 profile → `~/remote/`
- 命名 profile → `~/remote/<name>/`（如 `~/remote/gpu1/`）

直接使用 Read / Edit / Write 工具操作这些路径：
- `Read ~/remote/src/main.py`
- `Edit ~/remote/gpu1/train.py`

改动通过 SSHFS 自动同步到远程。

### 执行远程命令

短命令（< 30 秒）：
```bash
rt exec "pwd"
rt -p gpu1 exec "nvidia-smi"
```

长命令（构建、训练、服务）：
```bash
rt exec --bg --name build "make all"
rt -p gpu1 exec --bg --name train "python3 train.py --epochs 100"
```

查看后台任务：
```bash
rt logs                              # 列出当前 profile 的后台任务
rt -p gpu1 logs                      # 列出 gpu1 的后台任务
rt -p gpu1 logs rt_gpu1_bg_train     # 查看具体输出
```

命令的工作目录是 REMOTE_DIR，与挂载目录对应，相对路径通用。

## 注意事项

1. **禁止交互式命令** — 不要运行 vim、less、top、python REPL。用非交互替代（`python3 -c "..."`、`head`、`cat`）。

2. **延迟** — SSHFS 有网络延迟。避免扫描大目录，优先读取特定文件。

3. **大文件** — 不要通过挂载读取 >10MB 的文件。用 `rt exec "head -100 big.log"` 代替。

4. **不要同时改同一文件** — 不要一边通过挂载编辑，一边通过 `rt exec` 写同一个文件。

5. **超过 30 秒的命令必须用 `--bg`** — 避免 SSH 超时杀死进程。

6. **连接中断** — 如果文件操作报错，运行 `rt status` 检查，必要时 `rt disconnect && rt connect` 重连。

7. **依赖缺失** — 如果 `rt check` 或任何命令报 "not found"，**不要尝试 sudo 安装**，告知用户手动安装。

8. **查看帮助** — 运行 `rt help` 可查看所有命令和用法。
SLASHCMD
info "Created $CLAUDE_DIR/commands/remote.md (/remote slash command)"

# ── 5. Summary ────────────────────────────────────────────────────
printf '\n'
info "Installation complete!"
info "  Config:   $RT_HOME/"
info "  Command:  rt (via $BIN_DIR/rt)"
info "  CC integration: $CLAUDE_DIR/CLAUDE.md + /remote"
printf '\n'
info "Next steps:"
info "  1. Edit $RT_HOME/rt.conf with your server details"
info "  2. rt setup-key --password 'your-password'"
info "  3. rt connect"
printf '\n'
