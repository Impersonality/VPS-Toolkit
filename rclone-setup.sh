#!/bin/sh
set -eu

# ── 日志 ──────────────────────────────────────────────
log()  { printf '\033[1;32m[+] %s\033[0m\n' "$*" >&2; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

# ── 配置 ──────────────────────────────────────────────
RCLONE_CONF_URL="https://gist.githubusercontent.com/Impersonality/f81cc06df5a1255b0cc34c9b54007729/raw/rclone.conf"
RCLONE_CONF_DIR="/root/.config/rclone"
RCLONE_CONF_PATH="${RCLONE_CONF_DIR}/rclone.conf"

# ── 前置检查 ──────────────────────────────────────────
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "请用 root 运行：sudo sh $0"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令：$1，请先安装。"
}

# ── 检测操作系统 ──────────────────────────────────────
detect_os() {
  OS_ID=""

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"
  elif command -v lsb_release >/dev/null 2>&1; then
    OS_ID="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
  else
    die "无法检测操作系统，请确认 /etc/os-release 存在。"
  fi

  case "$OS_ID" in
    debian|ubuntu) log "检测到系统：$OS_ID" ;;
    *) die "此脚本仅支持 Debian/Ubuntu 系统，当前系统：$OS_ID" ;;
  esac
}

# ── 安装 rclone ───────────────────────────────────────
install_rclone() {
  if command -v rclone >/dev/null 2>&1; then
    log "rclone 已安装，版本信息："
    rclone version | head -1
    log "跳过安装，继续配置..."
    return 0
  fi

  log "正在使用官方脚本安装 rclone..."
  curl -fsSL https://rclone.org/install.sh | bash

  if command -v rclone >/dev/null 2>&1; then
    log "rclone 安装成功！"
    rclone version | head -1
  else
    die "rclone 安装失败，请检查网络连接和安装日志。"
  fi
}

# ── 下载配置文件 ──────────────────────────────────────
setup_config() {
  log "正在配置 rclone..."

  # 创建配置目录
  if [ ! -d "$RCLONE_CONF_DIR" ]; then
    mkdir -p "$RCLONE_CONF_DIR"
    log "已创建配置目录：$RCLONE_CONF_DIR"
  fi

  # 备份已有配置
  if [ -f "$RCLONE_CONF_PATH" ]; then
    BACKUP_PATH="${RCLONE_CONF_PATH}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$RCLONE_CONF_PATH" "$BACKUP_PATH"
    warn "已备份原有配置到：$BACKUP_PATH"
  fi

  # 下载配置文件
  log "正在从 Gist 下载 rclone.conf..."
  if curl -fsSL "$RCLONE_CONF_URL" -o "$RCLONE_CONF_PATH"; then
    chmod 600 "$RCLONE_CONF_PATH"
    log "配置文件已写入：$RCLONE_CONF_PATH"
  else
    die "下载 rclone.conf 失败，请检查网络连接。"
  fi
}

# ── 验证配置 ──────────────────────────────────────────
verify_config() {
  log "正在验证配置..."

  REMOTES="$(rclone listremotes 2>/dev/null || true)"
  if [ -n "$REMOTES" ]; then
    log "已配置的远程存储："
    echo "$REMOTES" | while IFS= read -r remote; do
      printf '    %s\n' "$remote"
    done
  else
    die "未检测到远程存储配置，请检查配置文件。"
  fi
}

# ── 主流程 ────────────────────────────────────────────
main() {
  require_root
  require_cmd curl

  detect_os
  install_rclone
  setup_config
  verify_config

  echo ""
  log "全部完成！使用 'rclone listremotes' 查看已配置的远程存储。"
}

main "$@"
