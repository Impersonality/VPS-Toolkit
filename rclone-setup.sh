#!/bin/sh
set -eu

# ── 日志 ──────────────────────────────────────────────
log()  { printf '\033[1;32m[+] %s\033[0m\n' "$*" >&2; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

# ── 配置 ──────────────────────────────────────────────
GIST_ID="f81cc06df5a1255b0cc34c9b54007729"
GIST_FILE="rclone.conf"
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

  # 输入 GitHub Token
  printf '\033[1;36m请输入 GitHub Personal Access Token (gist 权限)：\033[0m' >&2
  read -r GITHUB_TOKEN
  if [ -z "$GITHUB_TOKEN" ]; then
    die "Token 不能为空。"
  fi

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

  # 通过 GitHub API 下载 Gist 配置文件
  log "正在通过 GitHub API 拉取 rclone.conf..."

  # 第一步：获取 Gist 元数据，提取 raw_url
  GIST_META="$(curl -fsSL \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/gists/${GIST_ID}" 2>/dev/null)" || die "API 请求失败，请检查 Token 是否正确且具有 gist 权限。"

  RAW_URL="$(printf '%s' "$GIST_META" | grep -o '"raw_url"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"raw_url"[[:space:]]*:[[:space:]]*"//; s/"$//')"

  if [ -z "$RAW_URL" ]; then
    die "无法从 Gist 中获取 raw_url，请检查 Gist ID 和 Token。"
  fi

  # 第二步：下载 raw 文件内容
  HTTP_CODE="$(curl -sL -w '%{http_code}' \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "$RAW_URL" \
    -o "$RCLONE_CONF_PATH")"

  if [ "$HTTP_CODE" != "200" ]; then
    rm -f "$RCLONE_CONF_PATH"
    die "下载配置文件失败 (HTTP $HTTP_CODE)。"
  fi

  chmod 600 "$RCLONE_CONF_PATH"
  log "配置文件已写入：$RCLONE_CONF_PATH"
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
