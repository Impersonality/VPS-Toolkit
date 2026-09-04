#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="Impersonality/VPS-Toolkit"
BRANCH="main"
INSTALL_BIN="/usr/local/bin/vps"
INSTALL_DIR="/usr/local/lib/vps-toolkit"
CONFIG_DIR="/etc/vps-toolkit"
ARCHIVE_URL="https://github.com/${REPOSITORY}/archive/refs/heads/${BRANCH}.tar.gz"
GITHUB_PROXY="${VPS_GITHUB_PROXY:-}"

log() { printf '[+] %s\n' "$*"; }
die() { printf '[x] %s\n' "$*" >&2; exit 1; }

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Root privileges are required."
  fi
}

# 用户设置代理时，将完整 GitHub URL 追加到代理前缀后。
download_url="$ARCHIVE_URL"
if [[ -n "$GITHUB_PROXY" ]]; then
  download_url="${GITHUB_PROXY%/}/${ARCHIVE_URL}"
fi

command -v curl >/dev/null 2>&1 || die "curl is required."
command -v tar >/dev/null 2>&1 || die "tar is required."

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

log "Downloading VPS Toolkit..."
if ! curl -fsSL --connect-timeout 8 "$download_url" -o "$tmp_dir/toolkit.tar.gz"; then
  if [[ "$download_url" == "$ARCHIVE_URL" ]]; then
    die "Failed to download VPS Toolkit."
  fi
  log "GitHub proxy failed, trying the original URL..."
  curl -fsSL --connect-timeout 8 "$ARCHIVE_URL" -o "$tmp_dir/toolkit.tar.gz"
fi
tar -xzf "$tmp_dir/toolkit.tar.gz" -C "$tmp_dir"
source_dir="$tmp_dir/VPS-Toolkit-${BRANCH}"

scripts=(
  quick-zsh-setup.sh
  rclone-setup.sh
  ssh-key-setup.sh
  swap-manager.sh
  common-commands.sh
  install.sh
)

as_root install -d "$INSTALL_DIR" "$CONFIG_DIR" "$(dirname "$INSTALL_BIN")"
as_root install -m 0755 "$source_dir/toolkit.sh" "$INSTALL_BIN"
for script in "${scripts[@]}"; do
  as_root install -m 0755 "$source_dir/$script" "$INSTALL_DIR/$script"
done
as_root install -m 0644 "$source_dir/ssh-key-comments.md" "$INSTALL_DIR/ssh-key-comments.md"

if [[ ! -f "$CONFIG_DIR/config" ]]; then
  as_root install -m 0644 "$source_dir/config.example" "$CONFIG_DIR/config"
  if [[ -n "$GITHUB_PROXY" ]]; then
    as_root sed -i "s|VPS_GITHUB_PROXY=\"\"|VPS_GITHUB_PROXY=\"$GITHUB_PROXY\"|" "$CONFIG_DIR/config"
  fi
fi

log "Installed: $INSTALL_BIN"
log "Run: vps"
