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

# ── 箭头键菜单选择器 ─────────────────────────────────
# 用法: arrow_menu "提示文字" "选项1" "选项2" ...
# 结果存入全局变量 MENU_RESULT (0-based 索引)，ESC 返回 -1
arrow_menu() {
  local hint="$1"
  shift
  local items=("$@")
  local count=${#items[@]}
  local sel=0
  local i lines

  # 隐藏光标
  printf '\033[?25l'
  # 确保退出时恢复光标
  trap 'printf "\033[?25h"' RETURN

  _draw() {
    for ((i = 0; i < count; i++)); do
      if ((i == sel)); then
        printf "  ${C_CYAN}${C_BOLD} ▸ %s${C_RESET}\n" "${items[$i]}"
      else
        printf "     %s\n" "${items[$i]}"
      fi
    done
    printf "\n  ${C_DIM}%s${C_RESET}\n" "$hint"
    lines=$((count + 2))
  }

  _draw

  while true; do
    local key=""
    IFS= read -rsn1 key 2>/dev/null || true

    if [[ "$key" == $'\x1b' ]]; then
      local s1="" s2=""
      IFS= read -rsn1 -t 0.1 s1 2>/dev/null || true
      IFS= read -rsn1 -t 0.1 s2 2>/dev/null || true
      if [[ "$s1" == "[" ]]; then
        case "$s2" in
          A) sel=$(( (sel - 1 + count) % count )) ;;
          B) sel=$(( (sel + 1) % count )) ;;
        esac
      else
        # 纯 ESC 键
        MENU_RESULT=-1
        return
      fi
    elif [[ "$key" == "" ]]; then
      # Enter 键
      MENU_RESULT=$sel
      return
    fi

    # 重绘菜单
    printf "\033[%dA\033[J" "$lines"
    _draw
  done
}

# ── 运行远程脚本 ──────────────────────────────────────
run_remote_script() {
  local script_name="$1"
  local url="${REPO_BASE}/${script_name}"

  echo ""
  log "正在下载并运行 ${script_name}..."
  echo ""

  local tmp_script
  tmp_script="$(mktemp)"
  if curl -fsSL "$url" -o "$tmp_script" 2>/dev/null; then
    bash "$tmp_script" || true
  else
    warn "下载 ${script_name} 失败，请检查网络连接。"
  fi
  rm -f "$tmp_script"

  echo ""
  printf "  ${C_DIM}按回车键返回主菜单...${C_RESET}"
  read -r </dev/tty
}

# ── 主循环 ────────────────────────────────────────────
main() {
  if ! command -v curl >/dev/null 2>&1; then
    die "缺少 curl，请先安装：apt install curl"
  fi

  local items=(
    "SSH 密钥配置"
    "Swap 管理"
    "Zsh 一键配置"
    "Rclone 配置"
    "Speedtest 安装"
    "退出"
  )

  local scripts=(
    "ssh-key-setup.sh"
    "swap-manager.sh"
    "quick-zsh-setup.sh"
    "rclone-setup.sh"
    "speedtest-install.sh"
  )

  local last_idx=$(( ${#items[@]} - 1 ))

  while true; do
    cls
    printf "\n"
    printf "  ${C_CYAN}${C_BOLD}"
    printf "  ╔══════════════════════════════════════╗\n"
    printf "  ║          VPS Toolkit  主菜单          ║\n"
    printf "  ╚══════════════════════════════════════╝"
    printf "${C_RESET}\n\n"

    arrow_menu "↑↓ 移动  Enter 确认  ESC 退出" "${items[@]}"

    if [[ $MENU_RESULT -eq -1 ]] || [[ $MENU_RESULT -eq $last_idx ]]; then
      cls
      log "再见！"
      exit 0
    fi

    run_remote_script "${scripts[$MENU_RESULT]}"
  done
}

main "$@"
