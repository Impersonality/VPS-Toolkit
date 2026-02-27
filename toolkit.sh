#!/usr/bin/env bash
set -euo pipefail

# ── 配置 ──────────────────────────────────────────────
REPO_BASE="https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main"

# ── 颜色 ──────────────────────────────────────────────
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_DIM='\033[2m'

# ── 日志 ──────────────────────────────────────────────
log()  { printf "${C_GREEN}[+] %s${C_RESET}\n" "$*" >&2; }
warn() { printf "${C_YELLOW}[!] %s${C_RESET}\n" "$*" >&2; }
die()  { printf "${C_RED}[x] %s${C_RESET}\n" "$*" >&2; exit 1; }

# ── 清屏 ──────────────────────────────────────────────
cls() { printf '\033[2J\033[H'; }

# ── 读取按键（支持 ESC 检测）─────────────────────────
# 返回值存入 KEY_PRESSED
read_key() {
  KEY_PRESSED=""
  # 读取一个字符（-s 不回显，-n1 读一个字符）
  IFS= read -rsn1 KEY_PRESSED 2>/dev/null || true

  # 如果是 ESC (0x1B)，检查是否还有后续字符（方向键等）
  if [ "$KEY_PRESSED" = $'\x1b' ]; then
    # 短暂等待后续字符
    if IFS= read -rsn1 -t 0.1 _extra 2>/dev/null; then
      # 有后续字符 → 是方向键/功能键序列，忽略剩余部分
      IFS= read -rsn1 -t 0.1 _ 2>/dev/null || true
      KEY_PRESSED="IGNORE"
    else
      # 纯 ESC 键
      KEY_PRESSED="ESC"
    fi
  fi
}

# ── 运行远程脚本 ──────────────────────────────────────
run_remote_script() {
  local script_name="$1"
  local url="${REPO_BASE}/${script_name}"

  echo ""
  log "正在下载并运行 ${script_name}..."
  echo ""

  # 下载脚本内容后用 bash 执行
  local tmp_script
  tmp_script="$(mktemp)"
  if curl -fsSL "$url" -o "$tmp_script" 2>/dev/null; then
    bash "$tmp_script"
  else
    warn "下载 ${script_name} 失败，请检查网络连接。"
  fi
  rm -f "$tmp_script"

  echo ""
  printf "${C_DIM}按任意键返回主菜单...${C_RESET}"
  read_key
}

# ── 显示主菜单 ────────────────────────────────────────
show_menu() {
  cls
  echo ""
  printf "${C_CYAN}${C_BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║          VPS Toolkit  主菜单          ║"
  echo "  ╚══════════════════════════════════════╝"
  printf "${C_RESET}"
  echo ""
  printf "  ${C_GREEN}1${C_RESET}) SSH 密钥配置\n"
  printf "  ${C_GREEN}2${C_RESET}) Swap 管理\n"
  printf "  ${C_GREEN}3${C_RESET}) Zsh 一键配置\n"
  printf "  ${C_GREEN}4${C_RESET}) Rclone 配置\n"
  printf "  ${C_GREEN}5${C_RESET}) Speedtest 安装\n"
  echo ""
  printf "  ${C_RED}0${C_RESET}) 退出  ${C_DIM}(ESC 也可退出)${C_RESET}\n"
  echo ""
  printf "  ${C_CYAN}请选择 [0-5]：${C_RESET}"
}

# ── 主循环 ────────────────────────────────────────────
main() {
  # 前置检查
  if ! command -v curl >/dev/null 2>&1; then
    die "缺少 curl，请先安装：apt install curl"
  fi

  while true; do
    show_menu
    read_key

    case "$KEY_PRESSED" in
      1)
        run_remote_script "ssh-key-setup.sh"
        ;;
      2)
        run_remote_script "swap-manager.sh"
        ;;
      3)
        run_remote_script "quick-zsh-setup.sh"
        ;;
      4)
        run_remote_script "rclone-setup.sh"
        ;;
      5)
        run_remote_script "speedtest-install.sh"
        ;;
      0|ESC)
        cls
        log "再见！"
        exit 0
        ;;
      *)
        # 无效输入，继续循环
        ;;
    esac
  done
}

main "$@"
