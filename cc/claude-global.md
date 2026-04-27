<!-- remote-toolkit start -->
## Remote Server Management

The `rt` command drives remote servers via Mutagen sync + SSH. Multiple servers via profiles.

- Setup: `rt setup-key --password 'pw'` then `rt connect` (or `rt -p <profile> ...`)
- Local working tree: `~/work/` (default) or `~/work/<profile>/` — edit files directly, auto-syncs to remote
- Run cmds: `rt exec "cmd"` (auto-flushes sync) / `rt exec --bg --name N "long cmd"`
- Slurm (if `SLURM_ENABLED=1`): `rt slurm submit foo.sbatch` / `rt slurm queue` / `rt slurm logs <id>`
- Status: `rt status --all`
- Full guide: `/remote` slash command. Quick ref: `rt help`

Rules: No interactive cmds (vim, top, REPL). Long cmds use `--bg` (any host) or `slurm submit` (Slurm hosts). Never sudo-install — ask user. Config at `~/.config/remote-toolkit/`.

When the user mentions a remote server, run `rt status --all` to see profiles. Ask which to use if unclear.
<!-- remote-toolkit end -->
