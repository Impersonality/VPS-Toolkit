#!/bin/sh
set -eu

# ── 日志 ──────────────────────────────────────────────
log()  { printf '\033[1;32m[+] %s\033[0m\n' "$*" >&2; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

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
# 返回小写的 OS_ID（如 ubuntu / debian / centos）和 OS_VERSION_ID（如 22.04）
detect_os() {
  OS_ID=""
  OS_VERSION_ID=""
  OS_CODENAME=""

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"
    OS_VERSION_ID="${VERSION_ID:-}"
    OS_CODENAME="$(echo "${VERSION_CODENAME:-}" | tr '[:upper:]' '[:lower:]')"
  elif command -v lsb_release >/dev/null 2>&1; then
    OS_ID="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
    OS_VERSION_ID="$(lsb_release -sr)"
    OS_CODENAME="$(lsb_release -sc | tr '[:upper:]' '[:lower:]')"
  else
    die "无法检测操作系统，请确认 /etc/os-release 存在。"
  fi

  if [ -z "$OS_ID" ]; then
    die "无法识别发行版。"
  fi

  log "检测到系统：$OS_ID $OS_VERSION_ID ($OS_CODENAME)"
}

# ── 兼容性黑名单 ──────────────────────────────────────
# Ookla Speedtest CLI 的 packagecloud 仓库对部分发行版版本尚未提供支持。
# 在此维护不支持的 OS_ID + OS_VERSION_ID 或 OS_CODENAME 组合。
# 如未来 Ookla 增加支持，从列表中移除即可。
UNSUPPORTED_LIST="
ubuntu:24.04:noble
ubuntu:24.10:oracular
"

check_compatibility() {
  for entry in $UNSUPPORTED_LIST; do
    u_id="$(echo "$entry"  | cut -d: -f1)"
    u_ver="$(echo "$entry"  | cut -d: -f2)"
    u_code="$(echo "$entry" | cut -d: -f3)"

    # 匹配 ID + (版本号 或 代号)
    if [ "$OS_ID" = "$u_id" ]; then
      if [ "$OS_VERSION_ID" = "$u_ver" ] || [ "$OS_CODENAME" = "$u_code" ]; then
        die "当前系统 $OS_ID $OS_VERSION_ID ($OS_CODENAME) 不受 Ookla Speedtest CLI 官方仓库支持，无法安装。"
      fi
    fi
  done

  log "兼容性检查通过"
}

# ── 检测包管理器 ──────────────────────────────────────
detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
  else
    die "不支持的包管理器，请手动安装 Ookla Speedtest CLI。"
  fi

  log "包管理器：$PKG_MANAGER"
}

# ── 清理冲突包 ────────────────────────────────────────
remove_conflicts() {
  case "$PKG_MANAGER" in
    apt)
      if dpkg -l speedtest-cli 2>/dev/null | grep -q '^ii'; then
        log "正在移除冲突的 speedtest-cli（非官方版本）..."
        apt-get remove -y speedtest-cli >/dev/null 2>&1 || true
      fi
      ;;
    yum|dnf)
      if rpm -qa | grep -q speedtest; then
        log "正在移除冲突的 speedtest 旧包..."
        rpm -qa | grep speedtest | xargs -I {} "$PKG_MANAGER" -y remove {} >/dev/null 2>&1 || true
      fi
      ;;
  esac
}

# ── 添加 Ookla 仓库并安装 ────────────────────────────
install_speedtest() {
  case "$PKG_MANAGER" in
    apt)
      log "正在添加 Ookla APT 仓库..."
      curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
      log "正在安装 speedtest..."
      apt-get install -y speedtest
      ;;
    yum|dnf)
      log "正在添加 Ookla YUM/DNF 仓库..."
      curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | bash
      log "正在安装 speedtest..."
      "$PKG_MANAGER" install -y speedtest
      ;;
  esac
}

# ── 验证安装 ──────────────────────────────────────────
verify_install() {
  if command -v speedtest >/dev/null 2>&1; then
    log "安装成功！版本信息："
    speedtest --version
  else
    die "安装后未找到 speedtest 命令，请检查安装日志。"
  fi
}

# ── 主流程 ────────────────────────────────────────────
main() {
  require_root
  require_cmd curl

  detect_os
  check_compatibility
  detect_pkg_manager
  remove_conflicts
  install_speedtest
  verify_install

  echo ""
  log "全部完成！运行 'speedtest' 即可测速。"
}

main "$@"
