# Remote Toolkit

让本地 Claude Code 通过 SSHFS + SSH 操控远程服务器的轻量 Bash 工具包。支持多 profile 同时连接多台服务器。

## 原理

```
本地 Claude Code
  ├── Read/Edit/Write  →  ~/remote/<profile>/  ← SSHFS →  远程服务器:/project
  └── Bash: rt exec    →  SSH                  →          远程服务器 shell
                                                            └── tmux (长任务)
```

## 前置要求

| 工具 | 用途 | 安装 |
|------|------|------|
| `ssh` | 远程连接 | `sudo apt install openssh-client` |
| `sshfs` | 挂载远程文件系统 | `sudo apt install sshfs` |
| `sshpass` | 自动推送 SSH 密钥 | `sudo apt install sshpass` |
| `tmux` | 后台长任务 | `sudo apt install tmux` |

一键安装所有依赖：
```bash
sudo apt install -y sshfs sshpass tmux
```

运行 `./rt check` 检查依赖状态。

> **注意：** Claude Code 无法执行 `sudo` 命令。如果 CC 提示依赖缺失，需要你手动安装。

## 快速开始

```bash
# 1. 检查依赖
./rt check

# 2. 创建配置
cp rt.conf.example rt.conf
vim rt.conf    # 填入 REMOTE_HOST 和 REMOTE_DIR

# 3. 推送 SSH 密钥（一次性）
./rt setup-key --password '你的密码'

# 4. 连接
./rt connect

# 5. 操作远程文件（直接在挂载点下读写）
ls ~/remote/

# 6. 执行远程命令
./rt exec "whoami"

# 7. 长任务
./rt exec --bg --name build "make all"
./rt logs rt_default_bg_build

# 8. 断开
./rt disconnect
```

## 多服务器 (Profile)

每个 profile 有独立的配置文件和挂载点，互不干扰。

```bash
# 创建 profile 配置
cat > rt.conf.gpu1 << 'EOF'
REMOTE_HOST="root@gpu-server-1"
REMOTE_DIR="/root/workspace"
SSH_PORT=22
EOF

cat > rt.conf.gpu2 << 'EOF'
REMOTE_HOST="root@gpu-server-2"
REMOTE_DIR="/root/workspace"
SSH_PORT=11720
EOF

# 分别推送密钥
./rt -p gpu1 setup-key --password 'pass1'
./rt -p gpu2 setup-key --password 'pass2'

# 同时连接两台
./rt -p gpu1 connect    # 挂载到 ~/remote/gpu1/
./rt -p gpu2 connect    # 挂载到 ~/remote/gpu2/

# 分别操作
./rt -p gpu1 exec "nvidia-smi"
./rt -p gpu2 exec "nvidia-smi"

# 查看所有连接
./rt status --all

# 分别断开
./rt -p gpu1 disconnect
./rt -p gpu2 disconnect
```

不带 `-p` 等同于 `-p default`，配置文件为 `rt.conf`，挂载点为 `~/remote/`。

## 命令参考

| 命令 | 说明 |
|------|------|
| `rt check` | 检查依赖是否齐全 |
| `rt setup-key [--password PASS]` | 推送 SSH 密钥到远程 |
| `rt connect` | 挂载远程目录 |
| `rt disconnect` | 卸载并清理 |
| `rt exec "cmd"` | 同步执行远程命令 |
| `rt exec --bg "cmd"` | 后台执行（tmux） |
| `rt exec --bg --name NAME "cmd"` | 指定名称的后台任务 |
| `rt logs` | 列出后台任务 |
| `rt logs JOB_ID` | 查看任务输出 |
| `rt logs JOB_ID -f` | 实时跟踪输出 |
| `rt status` | 当前 profile 连接状态 |
| `rt status --all` | 所有 profile 连接状态 |
| `rt help` | 帮助信息 |

所有命令均可在前面加 `-p <profile>` 指定 profile。

## 配置文件

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `REMOTE_HOST` | 是 | — | user@hostname 或 SSH config 别名 |
| `REMOTE_DIR` | 是 | — | 要挂载的远程目录 |
| `LOCAL_MOUNT` | 否 | `~/remote` 或 `~/remote/<profile>` | 本地挂载点 |
| `SSH_KEY` | 否 | SSH agent | SSH 密钥路径 |
| `SSH_PORT` | 否 | `22` | SSH 端口 |

## 与 Claude Code 配合使用

1. 在 remote-toolkit 目录下启动 Claude Code
2. CC 读取 `CLAUDE.md` 自动了解用法
3. CC 可以：创建配置、推送密钥、连接、读写远程文件、执行远程命令
4. CC 不能：安装系统依赖（需要你手动 `sudo apt install`）

## 故障排查

| 问题 | 解决 |
|------|------|
| `sshfs: command not found` | `sudo apt install sshfs` |
| `sshpass: command not found` | `sudo apt install sshpass` |
| SSH 连接失败 | 检查网络、密钥：`ssh -p PORT user@host "echo ok"` |
| 挂载后文件操作超时 | `rt disconnect && rt connect` 重连 |
| 卸载失败 (device busy) | 关闭所有访问挂载点的进程后重试 |
| 后台任务无输出 | 确认远程已装 tmux：`ssh user@host "tmux -V"` |
