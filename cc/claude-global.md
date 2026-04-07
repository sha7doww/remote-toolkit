<!-- remote-toolkit start -->
## Remote Server Management

The `rt` command is available globally for managing remote servers via SSHFS + SSH.

- Connect: `rt connect` / `rt -p <profile> connect`
- Remote files: `~/remote/` (default) or `~/remote/<profile>/`
- Run commands: `rt exec "cmd"` / `rt exec --bg --name NAME "long cmd"`
- Status: `rt status --all`
- Full guide: use `/remote` slash command
- Quick ref: `rt help`

Rules: No interactive commands (vim, top, python REPL). Commands >30s must use `--bg`. Never sudo-install deps — ask the user. Config at ~/.config/remote-toolkit/.

When the user mentions a remote server or asks to work remotely, run `rt status --all` to see available profiles. Ask which profile to use if unclear.
<!-- remote-toolkit end -->
