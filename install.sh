#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RT_HOME="${RT_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/remote-toolkit}"
BIN_DIR="$HOME/.local/bin"
CLAUDE_DIR="$HOME/.claude"

_color() { [[ -t 1 ]] && printf '\e[%sm' "$1" || true; }
_reset() { _color 0; }
info()  { _color 32; printf ':: %s\n' "$*"; _reset; }
warn()  { _color 33; printf '!! %s\n' "$*"; _reset; }

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
  [[ "$(basename "$SHELL")" == "zsh" ]] && SHELL_RC="$HOME/.zshrc"
  if ! grep -q 'export PATH="$HOME/.local/bin' "$SHELL_RC" 2>/dev/null; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_RC"
    warn "$BIN_DIR not in PATH. Added to $SHELL_RC."
    warn "Run: source $SHELL_RC"
  fi
fi

# ── 4. Claude Code integration ───────────────────────────────────
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"

# 4a. Global CLAUDE.md — append/update remote-toolkit section
MARKER_START="<!-- remote-toolkit start -->"
MARKER_END="<!-- remote-toolkit end -->"
RT_SECTION=$(cat "$SCRIPT_DIR/cc/claude-global.md")

if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  if grep -qF "$MARKER_START" "$CLAUDE_DIR/CLAUDE.md"; then
    # Replace in-place between markers (preserves any user-added headings/content
    # surrounding the markers, e.g., a parent "# Tools" section).
    # Pass section via file path (not -v) to avoid awk's "newline in string"
    # warnings on multi-line values under BSD awk.
    tmpfile=$(mktemp)
    awk -v secfile="$SCRIPT_DIR/cc/claude-global.md" \
        -v start="$MARKER_START" \
        -v end="$MARKER_END" '
      BEGIN {
        while ((getline line < secfile) > 0) section = section line "\n"
        sub(/\n$/, "", section)
        close(secfile)
      }
      $0 == start { print section; in_block = 1; next }
      $0 == end   { in_block = 0; next }
      !in_block   { print }
    ' "$CLAUDE_DIR/CLAUDE.md" > "$tmpfile"
    mv "$tmpfile" "$CLAUDE_DIR/CLAUDE.md"
  else
    printf '\n%s\n' "$RT_SECTION" >> "$CLAUDE_DIR/CLAUDE.md"
  fi
  info "Updated $CLAUDE_DIR/CLAUDE.md (remote-toolkit section)"
else
  printf '%s\n' "$RT_SECTION" > "$CLAUDE_DIR/CLAUDE.md"
  info "Created $CLAUDE_DIR/CLAUDE.md"
fi

# 4b. Slash command /remote
cp "$SCRIPT_DIR/cc/remote.md" "$CLAUDE_DIR/commands/remote.md"
info "Installed $CLAUDE_DIR/commands/remote.md (/remote slash command)"

# ── 5. Summary ────────────────────────────────────────────────────
printf '\n'
info "Installation complete!"
info "  Config:   $RT_HOME/"
info "  Command:  rt (via $BIN_DIR/rt)"
info "  CC integration: $CLAUDE_DIR/CLAUDE.md + /remote"
printf '\n'
info "Next steps:"
info "  1. Edit $RT_HOME/rt.conf with your server details (REMOTE_HOST, REMOTE_DIR)"
info "  2. rt setup-key --password 'your-password'"
info "  3. rt connect    # starts Mutagen sync"
info ""
info "For HPC/Slurm hosts, also set SLURM_ENABLED=1 in the profile config."
printf '\n'
