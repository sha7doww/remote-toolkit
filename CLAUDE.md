# Remote Toolkit — Claude Code 指南

本项目通过 SSHFS + SSH 让你操控远程服务器。支持多 profile 同时连接不同服务器。

## 前置依赖

**重要：** 以下工具需要 `sudo` 安装，Claude Code 无法自动完成。如果缺失，请提示用户手动安装。

运行 `rt check` 检查依赖状态。如果有缺失项，告知用户执行：
```bash
sudo apt install sshfs sshpass tmux
```

## 首次连接新服务器

完整流程（以用户提供 `user@host -p PORT` 和密码为例）：

1. 创建配置文件（默认 profile 用 `rt.conf`，命名 profile 用 `rt.conf.<name>`）：
   ```bash
   # 默认 profile
   cat > rt.conf << 'EOF'
   REMOTE_HOST="user@host"
   REMOTE_DIR="/home/user/project"
   SSH_PORT=22
   EOF

   # 或命名 profile
   cat > rt.conf.gpu1 << 'EOF'
   REMOTE_HOST="root@gpu-server"
   REMOTE_DIR="/root/workspace"
   SSH_PORT=22
   EOF
   ```

2. 推送 SSH 密钥（一次性，之后免密）：
   ```bash
   rt setup-key --password '密码'
   rt -p gpu1 setup-key --password '密码'
   ```

3. 连接：
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
- 默认 profile：`~/remote/`
- 命名 profile：`~/remote/<name>/`（如 `~/remote/gpu1/`）

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
