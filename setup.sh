#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf '\e[32m:: %s\e[0m\n' "$*"; }
warn()  { printf '\e[33m!! %s\e[0m\n' "$*"; }

info "Remote Toolkit — Setup"
printf '\n'

# Check dependencies
missing=()
for cmd in ssh sshfs sshpass tmux; do
  if command -v "$cmd" >/dev/null 2>&1; then
    info "$cmd — OK"
  else
    warn "$cmd — MISSING"
    missing+=("$cmd")
  fi
done

if command -v fusermount3 >/dev/null 2>&1 || command -v fusermount >/dev/null 2>&1; then
  info "fusermount — OK"
else
  warn "fusermount — MISSING (comes with sshfs)"
fi

printf '\n'

if [[ ${#missing[@]} -gt 0 ]]; then
  warn "Missing dependencies. Install with:"
  printf '  sudo apt install -y %s\n' "${missing[*]}"
  printf '\n'
  printf '  Then re-run: ./setup.sh\n\n'
  exit 1
fi

# Create default config if needed
if [[ ! -f "$SCRIPT_DIR/rt.conf" ]]; then
  cp "$SCRIPT_DIR/rt.conf.example" "$SCRIPT_DIR/rt.conf"
  info "Created rt.conf from template."
  info "  Edit it: $SCRIPT_DIR/rt.conf"
else
  info "rt.conf already exists."
fi

# Make rt executable
chmod +x "$SCRIPT_DIR/rt"
info "rt is executable."

printf '\n'
info "Setup complete!"
printf '\n'
printf '  Next steps:\n'
printf '    1. Edit rt.conf (or create rt.conf.<profile> for named profiles)\n'
printf '    2. Push SSH key:  ./rt setup-key --password "your-password"\n'
printf '    3. Connect:       ./rt connect\n'
printf '\n'

# Suggest PATH addition
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$SCRIPT_DIR"; then
  printf '  Optional — add to PATH:\n'
  printf '    echo '\''export PATH="%s:$PATH"'\'' >> ~/.bashrc\n' "$SCRIPT_DIR"
  printf '\n'
fi
