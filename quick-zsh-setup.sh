#!/usr/bin/env bash
set -euo pipefail

# 统一插件列表，避免在多个位置重复写死。
PLUGINS=(git zsh-autosuggestions zsh-syntax-highlighting)
PLUGIN_LINE="plugins=(${PLUGINS[*]})"

log() { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

# 校验命令是否存在，不存在则直接退出。
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

# 仅处理本脚本目标发行版：Debian/Ubuntu (apt) 与 Alpine (apk)。
run_pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    local pre=()
    [ "$(id -u)" -eq 0 ] || pre=(sudo)
    "${pre[@]}" apt-get update
    "${pre[@]}" apt-get install -y zsh git curl
  elif command -v apk >/dev/null 2>&1; then
    local pre=()
    [ "$(id -u)" -eq 0 ] || pre=(sudo)
    "${pre[@]}" apk update
    "${pre[@]}" apk add --no-cache zsh git curl
  else
    die "Unsupported package manager. Please install zsh/git/curl manually."
  fi
}

# 确保 zsh/git/curl 存在；缺失时自动安装。
ensure_tools() {
  local missing=()
  for cmd in zsh git curl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    log "Installing: ${missing[*]}"
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
      die "Need root or sudo privileges to install packages."
    fi
    run_pkg_install
  fi

  require_cmd zsh
  require_cmd git
  require_cmd curl
}

# 无人值守安装 oh-my-zsh，保留已有 .zshrc。
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    log "oh-my-zsh already installed"
  fi
}

# 安装所需插件（已存在则跳过），保证幂等。
install_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ ! -d "$custom/plugins/zsh-autosuggestions" ]; then
    log "Installing zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$custom/plugins/zsh-autosuggestions"
  fi

  if [ ! -d "$custom/plugins/zsh-syntax-highlighting" ]; then
    log "Installing zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$custom/plugins/zsh-syntax-highlighting"
  fi
}

# 写入插件配置：
# - 若已有 plugins=()，则替换为目标列表；
# - 若不存在，则追加一行。
configure_zshrc() {
  local zshrc="$HOME/.zshrc"

  if [ ! -f "$zshrc" ]; then
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$zshrc"
  fi

  if grep -qE '^plugins=\(' "$zshrc"; then
    sed -i.bak -E \
      "s/^plugins=\\(.+\\)\$/$PLUGIN_LINE/" \
      "$zshrc"
  else
    cp "$zshrc" "${zshrc}.bak"
    printf '\n%s\n' "$PLUGIN_LINE" >>"$zshrc"
  fi
  rm -f "${zshrc}.bak"
}

# 尝试切换默认 shell 到 zsh；失败时给出手动提示，不中断流程。
set_default_shell() {
  local zsh_bin
  local user_name
  zsh_bin="$(command -v zsh)"
  user_name="$(id -un)"

  if [ "${SHELL:-}" != "$zsh_bin" ] && command -v chsh >/dev/null 2>&1; then
    if chsh -s "$zsh_bin" "$user_name" 2>/dev/null; then
      log "Default shell changed to zsh"
    else
      warn "Could not change default shell automatically. Run: chsh -s $zsh_bin"
    fi
  fi
}

# 主流程：依赖 -> oh-my-zsh -> 插件 -> .zshrc -> 默认 shell
main() {
  ensure_tools
  install_oh_my_zsh
  install_plugins
  configure_zshrc
  set_default_shell

  log "Done. Re-login or run: zsh"
}

main "$@"
