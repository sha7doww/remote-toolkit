# Remote Toolkit

让 Claude Code 在任意工作目录操控远程服务器。支持同时连接多台服务器。

## 原理

通过 SSHFS 把远程目录挂载到本地，CC 用 Read/Edit/Write 直接操作远程文件；通过 SSH 执行远程命令，长任务用 tmux 保活。

```
本地 Claude Code
  ├── Read/Edit/Write  →  ~/remote/       ← SSHFS →  服务器A:/project
  ├── Read/Edit/Write  →  ~/remote/gpu1/  ← SSHFS →  服务器B:/workspace
  └── rt exec          →  SSH + tmux      →          远程 shell
```

## 安装

```bash
# 1. 安装系统依赖（CC 无法 sudo，需要你手动执行）
sudo apt install -y sshfs sshpass tmux

# 2. 克隆并安装
git clone <repo-url> ~/Project/remote-toolkit
cd ~/Project/remote-toolkit
./install.sh
```

`install.sh` 做了以下事情：
- 创建 symlink `~/.local/bin/rt` → 让 `rt` 命令全局可用
- 创建配置目录 `~/.config/remote-toolkit/`，迁移已有配置
- 写入 `~/.claude/CLAUDE.md` → CC 在任意工作区自动知道 `rt` 的存在
- 写入 `~/.claude/commands/remote.md` → 输入 `/remote` 可让 CC 获取完整操作指南

## 使用

安装后，直接告诉 CC 你的服务器信息即可：

> **你：** 帮我连上 root@192.168.1.100 端口 22，密码 xxx，改一下 /root/app/config.yaml

CC 会自动完成：创建配置 → 推送密钥 → 连接 → 编辑文件。

**多台服务器：** 给服务器起个名字，CC 通过 profile 管理。

> **你：** 帮我连上这台 GPU 服务器，叫 gpu1：root@10.0.0.5 端口 22，密码 xxx，工作目录 /root/workspace

之后就可以按名字操作：

> **你：** 在 gpu1 上跑 `python train.py --epochs 100`

> **你：** 断开 gpu1

断开只是卸载挂载，配置文件保留，下次 `连上 gpu1` 即可重新连接。

## 你可能需要手动做的事

| 场景 | 操作 |
|------|------|
| CC 提示依赖缺失 | `sudo apt install -y sshfs sshpass tmux` |
| 首次连接新服务器 | 告诉 CC 服务器地址、端口、密码 |
| 挂载异常 | 告诉 CC 重连，或手动 `rt disconnect && rt connect` |

其余操作（配置文件创建、SSH 密钥推送、文件编辑、命令执行、后台任务管理）全部由 CC 通过 `rt` 命令完成。

## 配置

配置目录：`~/.config/remote-toolkit/`

每台服务器一个配置文件：

| 文件 | 用途 | 挂载点 |
|------|------|--------|
| `rt.conf` | 默认服务器 | `~/remote/` |
| `rt.conf.gpu1` | 命名 profile | `~/remote/gpu1/` |
| `rt.conf.gpu2` | 命名 profile | `~/remote/gpu2/` |

配置内容（通常由 CC 自动创建）：
```bash
REMOTE_HOST="root@192.168.1.100"   # 必填
REMOTE_DIR="/root/workspace"        # 必填
SSH_PORT=22                         # 可选，默认 22
```

## 故障排查

| 问题 | 解决 |
|------|------|
| CC 说 `sshfs: command not found` | `sudo apt install sshfs` |
| SSH 连接失败 | 检查网络：`ssh -p PORT user@host "echo ok"` |
| 文件操作超时/卡住 | 告诉 CC 重连，或 `rt disconnect && rt connect` |
| 卸载失败 (device busy) | 关闭所有访问 `~/remote/` 的进程后重试 |
