#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { printf '\e[32m:: %s\e[0m\n' "$*"; }

info "Remote Toolkit — Setup"
printf '\n'

# Check dependencies via rt check
chmod +x "$SCRIPT_DIR/rt"
if ! "$SCRIPT_DIR/rt" check; then
  exit 1
fi

# Create default config if needed
if [[ ! -f "$SCRIPT_DIR/rt.conf" ]]; then
  cp "$SCRIPT_DIR/rt.conf.example" "$SCRIPT_DIR/rt.conf"
  info "Created rt.conf from template. Edit it with your server details."
else
  info "rt.conf already exists."
fi

printf '\nNext steps:\n'
printf '  1. Edit rt.conf (or create rt.conf.<profile> for named profiles)\n'
printf '  2. Push SSH key:  ./rt setup-key --password "your-password"\n'
printf '  3. Connect:       ./rt connect\n\n'

# Suggest PATH addition
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$SCRIPT_DIR"; then
  printf 'Optional — add to PATH:\n'
  printf '  echo '\''export PATH="%s:$PATH"'\'' >> ~/.bashrc\n\n' "$SCRIPT_DIR"
fi
