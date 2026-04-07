# Remote Toolkit — 开发指南

本文件面向**开发此工具的 CC**，不是使用指南。使用指南在 `cc/remote.md`。

## 项目结构

```
rt                    主脚本（Bash），所有功能入口
rt.conf.example       配置模板
install.sh            安装脚本：symlink、配置迁移、CC 集成
cc/
  claude-global.md    → 安装时写入 ~/.claude/CLAUDE.md 的内容（英文，~10 行）
  remote.md           → 安装时复制到 ~/.claude/commands/remote.md（中文，完整操作指南）
CLAUDE.md             本文件（开发指南）
README.md             用户文档
```

## rt 脚本架构

- **RT_HOME**：配置和状态的根目录，默认 `~/.config/remote-toolkit/`，可通过环境变量覆盖
- **RT_SCRIPT_DIR**：脚本自身所在目录，仅用于 `init` 命令查找 `rt.conf.example`
- **Profile 系统**：`-p <name>` 选择 profile，影响配置文件路径（`rt.conf.<name>`）、状态目录（`.rt/<name>/`）、挂载点（`~/remote/<name>/`）、tmux session 前缀
- **Dispatch**：`main()` 解析全局 flag 后分发到 `cmd_*` 函数

子命令：`init` `check` `setup-key` `connect` `disconnect` `exec` `logs` `status` `help`

## CC 集成文件（cc/ 目录）

这两个文件是安装到用户环境的源文件，`install.sh` 负责部署：

- **`cc/claude-global.md`**：带 HTML marker 的片段，追加到 `~/.claude/CLAUDE.md`。保持精简（~10 行），因为每次 CC 启动都会加载。
- **`cc/remote.md`**：`/remote` 斜杠命令的完整内容。只在用户主动调用时注入上下文。

修改这两个文件后，重新运行 `./install.sh` 即可部署更新。

## 开发约定

- 修改 rt 脚本后用 `bash -n rt` 检查语法
- 所有路径使用 `RT_HOME`，不要硬编码 `RT_DIR` 或脚本目录
- 不要引入 Python/Node 等额外运行时依赖，保持纯 Bash
- 配置文件格式是可 source 的 Bash 变量赋值
