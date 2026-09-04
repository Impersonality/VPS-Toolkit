#!/usr/bin/env bash
set -euo pipefail

# 安装后的固定路径；在仓库中直接运行时使用当前目录。
INSTALL_BIN="/usr/local/bin/vps"
INSTALL_DIR="/usr/local/lib/vps-toolkit"
CONFIG_FILE="${VPS_TOOLKIT_CONFIG:-/etc/vps-toolkit/config}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -r "$CONFIG_FILE" ]]; then
  # 配置文件由本机管理员维护，可以覆盖下载代理和 GitHub 用户名。
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

if [[ -n "${VPS_TOOLKIT_DIR:-}" ]]; then
  TOOLKIT_DIR="$VPS_TOOLKIT_DIR"
elif [[ -f "$INSTALL_DIR/ssh-key-setup.sh" ]]; then
  TOOLKIT_DIR="$INSTALL_DIR"
else
  TOOLKIT_DIR="$SCRIPT_DIR"
fi

export VPS_GITHUB_PROXY="${VPS_GITHUB_PROXY:-}"
export VPS_GITHUB_USER="${VPS_GITHUB_USER:-Impersonality}"

log() { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die() { printf '[x] %s\n' "$*" >&2; exit 1; }

clear_screen() {
  printf '\033[2J\033[H'
}

# 使用简单 ANSI 光标移动实现选择器，不切换终端屏幕，也不持续刷新。
arrow_menu() {
  local hint="$1"
  shift
  local items=("$@")
  local count=${#items[@]}
  local selected=0
  local key next1 next2 i lines

  draw_menu() {
    for ((i = 0; i < count; i++)); do
      if ((i == selected)); then
        printf '  > %s\n' "${items[$i]}"
      else
        printf '    %s\n' "${items[$i]}"
      fi
    done
    printf '\n  %s\n' "$hint"
    lines=$((count + 2))
  }

  draw_menu
  while true; do
    key=""
    IFS= read -rsn1 key 2>/dev/null || true

    if [[ "$key" == $'\x1b' ]]; then
      next1=""
      next2=""
      IFS= read -rsn1 -t 0.1 next1 2>/dev/null || true
      IFS= read -rsn1 -t 0.1 next2 2>/dev/null || true
      if [[ "$next1" == "[" ]]; then
        case "$next2" in
          A) selected=$(((selected - 1 + count) % count)) ;;
          B) selected=$(((selected + 1) % count)) ;;
        esac
      else
        MENU_RESULT=-1
        return
      fi
    elif [[ -z "$key" ]]; then
      MENU_RESULT=$selected
      return
    fi

    printf '\033[%dA\033[J' "$lines"
    draw_menu
  done
}

# 为 GitHub 地址添加用户配置的代理前缀。
github_url() {
  local url="$1"
  if [[ -n "$VPS_GITHUB_PROXY" && ( "$url" == https://github.com/* || "$url" == https://raw.githubusercontent.com/* ) ]]; then
    printf '%s/%s\n' "${VPS_GITHUB_PROXY%/}" "$url"
  else
    printf '%s\n' "$url"
  fi
}

# 代理失败后回退到原始地址，避免代理临时失效时阻断操作。
download() {
  local url="$1"
  local output="$2"
  local target
  target="$(github_url "$url")"

  if curl -fsSL --connect-timeout 8 "$target" -o "$output"; then
    return
  fi
  if [[ "$target" != "$url" ]]; then
    warn "GitHub 代理失败，尝试直连。"
    curl -fsSL --connect-timeout 8 "$url" -o "$output"
    return
  fi
  return 1
}

run_local() {
  local script="$1"
  shift
  bash "$TOOLKIT_DIR/$script" "$@"
}

run_remote() {
  local name="$1"
  local url="$2"
  shift 2

  local script status=0
  script="$(mktemp)"
  log "正在下载 $name..."
  if ! download "$url" "$script"; then
    rm -f "$script"
    die "$name 下载失败。"
  fi

  bash "$script" "$@" || status=$?
  rm -f "$script"
  return "$status"
}

confirm() {
  local answer
  read -r -p "确认继续？[y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

pause() {
  local key
  printf '\n按 Enter 或 Esc 返回...'
  while true; do
    key=""
    # 静默读取单个按键，避免 Esc 被终端回显为 ^[。
    IFS= read -rsn1 key 2>/dev/null || return
    case "$key" in
      ''|$'\x1b') return ;;
    esac
  done
}

run_and_pause() {
  if ! "$@"; then
    warn "操作执行失败。"
  fi
  pause
}

run_reinstall() {
  local distro="$1"
  local release="$2"
  local password ssh_key ssh_port extra
  local -a args extra_args

  clear_screen
  printf '重装 %s %s\n\n' "$distro" "$release"
  read -r -s -p "密码（可留空）：" password
  printf '\n'
  read -r -p "SSH Key、github:user 或 URL（可留空）：" ssh_key
  read -r -p "SSH 端口（可留空）：" ssh_port
  read -r -p "附加参数（可留空）：" extra

  args=("$distro" "$release")
  [[ -n "$password" ]] && args+=(--password "$password")
  [[ -n "$ssh_key" ]] && args+=(--ssh-key "$ssh_key")
  [[ -n "$ssh_port" ]] && args+=(--ssh-port "$ssh_port")
  if [[ -n "$extra" ]]; then
    read -r -a extra_args <<<"$extra"
    args+=("${extra_args[@]}")
  fi

  printf '\n目标系统：%s %s\n' "$distro" "$release"
  warn "此操作将重装系统。"
  confirm || return 0

  run_remote "reinstall" \
    "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh" \
    "${args[@]}"
}

run_test() {
  case "$1" in
    nodequality) run_remote "NodeQuality" "https://run.NodeQuality.com" ;;
    tcpquality) run_remote "TcpQuality" "https://raw.githubusercontent.com/ibsgss/TcpQuality/main/runTcpQuality.sh" ;;
    tcpfit) run_remote "tcpfit" "https://raw.githubusercontent.com/Kylin010/tcpfit/main/tcpfit.sh" ;;
    fusion) run_remote "融合怪" "https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh" ;;
    unlock) run_remote "解锁测试" "https://check.unlock.media" ;;
  esac
}

update_toolkit() {
  VPS_GITHUB_PROXY="$VPS_GITHUB_PROXY" bash "$TOOLKIT_DIR/install.sh"
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "此操作需要 root 权限。"
  fi
}

uninstall_toolkit() {
  printf '即将卸载 VPS Toolkit。\n'
  confirm || return 1
  as_root rm -f "$INSTALL_BIN"
  as_root rm -rf "$INSTALL_DIR" /etc/vps-toolkit
  log "VPS Toolkit 已卸载。"
}

swap_menu() {
  local items=(
    "[SHOW] 查看当前 Swap"
    "[ADD] 增加 Swap"
    "[DELETE] 删除 Swap"
    "返回"
  )

  while true; do
    clear_screen
    printf 'Swap 管理\n=========\n\n'
    arrow_menu "Up/Down: move | Enter: select | Esc: back" "${items[@]}"

    case "$MENU_RESULT" in
      0) run_and_pause run_local swap-manager.sh show ;;
      1) run_and_pause run_local swap-manager.sh add ;;
      2) run_and_pause run_local swap-manager.sh delete ;;
      3|-1) return ;;
    esac
  done
}

reinstall_menu() {
  local items=(
    "Debian 12"
    "Debian 13"
    "Ubuntu 24.04"
    "返回"
  )

  while true; do
    clear_screen
    printf '重装系统\n========\n\n'
    arrow_menu "Up/Down: move | Enter: select | Esc: back" "${items[@]}"

    case "$MENU_RESULT" in
      0) run_and_pause run_reinstall debian 12 ;;
      1) run_and_pause run_reinstall debian 13 ;;
      2) run_and_pause run_reinstall ubuntu 24.04 ;;
      3|-1) return ;;
    esac
  done
}

test_menu() {
  local items=(
    "NodeQuality"
    "TcpQuality"
    "tcpfit"
    "融合怪"
    "解锁测试"
    "返回"
  )

  while true; do
    clear_screen
    printf '测试脚本\n========\n\n'
    arrow_menu "Up/Down: move | Enter: select | Esc: back" "${items[@]}"

    case "$MENU_RESULT" in
      0) run_and_pause run_test nodequality ;;
      1) run_and_pause run_test tcpquality ;;
      2) run_and_pause run_test tcpfit ;;
      3) run_and_pause run_test fusion ;;
      4) run_and_pause run_test unlock ;;
      5|-1) return ;;
    esac
  done
}

application_menu() {
  local items=(
    "Docker"
    "WARP (fscarmen)"
    "返回"
  )

  while true; do
    clear_screen
    printf '应用安装\n========\n\n'
    arrow_menu "Up/Down: move | Enter: select | Esc: back" "${items[@]}"

    case "$MENU_RESULT" in
      0) run_and_pause run_remote "Docker" "https://get.docker.com" ;;
      1) run_and_pause run_remote "WARP" "https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh" ;;
      2|-1) return ;;
    esac
  done
}

main_menu() {
  local items=(
    "[SSH] SSH 密钥配置"
    "[SWAP] Swap 管理"
    "[ZSH] Zsh 配置"
    "[RCLONE] Rclone 配置"
    "[COMMANDS] 常用命令"
    "[REINSTALL] 重装系统"
    "[TEST] 测试脚本"
    "[SINGBOX] Singbox (233boy)"
    "[APP] 应用安装"
    "[UPDATE] 更新 VPS Toolkit"
    "[UNINSTALL] 卸载"
    "退出"
  )

  while true; do
    clear_screen
    printf 'VPS Toolkit\n===========\n\n'
    arrow_menu "Up/Down: move | Enter: select | Esc: exit" "${items[@]}"

    case "$MENU_RESULT" in
      0) run_and_pause run_local ssh-key-setup.sh ;;
      1) swap_menu ;;
      2) run_and_pause run_local quick-zsh-setup.sh ;;
      3) run_and_pause run_local rclone-setup.sh ;;
      4) run_and_pause run_local common-commands.sh ;;
      5) reinstall_menu ;;
      6) test_menu ;;
      7) run_and_pause run_remote "Singbox" "https://github.com/233boy/sing-box/raw/main/install.sh" ;;
      8) application_menu ;;
      9) run_and_pause update_toolkit ;;
      10)
        if uninstall_toolkit; then
          return
        fi
        ;;
      11|-1) return ;;
    esac
  done
}

if [[ $# -gt 0 ]]; then
  die "请直接运行 vps，通过菜单选择功能。"
fi

main_menu
clear_screen
