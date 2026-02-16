#!/bin/sh
set -eu

GITHUB_USER="Impersonality"

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

# ── 获取 GitHub 公钥 ──────────────────────────────────
fetch_keys() {
  username="$1"
  url="https://github.com/${username}.keys"
  log "正在从 $url 获取公钥..."

  keys="$(curl -fsSL "$url" 2>/dev/null)" || die "无法获取公钥，请检查用户名或网络。"

  if [ -z "$keys" ]; then
    die "该 GitHub 用户没有公开的 SSH 公钥。"
  fi

  echo "$keys"
}

# ── 选择公钥 ──────────────────────────────────────────
select_key() {
  keys="$1"
  total="$(echo "$keys" | wc -l)"

  echo ""
  echo "==============================="
  echo " 可用的 SSH 公钥（共 $total 个）"
  echo "==============================="

  i=1
  echo "$keys" | while IFS= read -r line; do
    # 显示类型和注释（用户标识），如 ssh-rsa administrator@DESKTOP-xxx
    key_type="$(echo "$line" | awk '{print $1}')"
    comment="$(echo "$line" | awk '{print $NF}')"
    if [ "$comment" = "$key_type" ] || [ -z "$comment" ]; then
      comment="(无注释)"
    fi
    printf "  %d) %s  %s\n" "$i" "$key_type" "$comment"
    i=$((i + 1))
  done

  echo "  a) 全部添加"
  echo "==============================="
  printf "请选择 [1-%d / a]：" "$total"
  read -r choice

  case "$choice" in
    a|A)
      SELECTED_KEYS="$keys"
      ;;
    ''|*[!0-9]*)
      die "无效输入。"
      ;;
    *)
      if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
        die "序号超出范围。"
      fi
      SELECTED_KEYS="$(echo "$keys" | sed -n "${choice}p")"
      ;;
  esac
}

# ── 安装公钥到 authorized_keys ────────────────────────
install_keys() {
  auth_dir="$HOME/.ssh"
  auth_file="$auth_dir/authorized_keys"

  mkdir -p "$auth_dir"
  chmod 700 "$auth_dir"
  touch "$auth_file"
  chmod 600 "$auth_file"

  added=0
  skipped=0

  # 使用临时文件保存计数，因为管道中的变量修改不会传回
  tmp_added="$(mktemp)"
  tmp_skipped="$(mktemp)"
  echo 0 > "$tmp_added"
  echo 0 > "$tmp_skipped"

  echo "$SELECTED_KEYS" | while IFS= read -r key; do
    [ -z "$key" ] && continue
    if grep -qF "$key" "$auth_file" 2>/dev/null; then
      echo $(( $(cat "$tmp_skipped") + 1 )) > "$tmp_skipped"
    else
      printf '%s\n' "$key" >> "$auth_file"
      echo $(( $(cat "$tmp_added") + 1 )) > "$tmp_added"
    fi
  done

  added="$(cat "$tmp_added")"
  skipped="$(cat "$tmp_skipped")"
  rm -f "$tmp_added" "$tmp_skipped"

  if [ "$added" -gt 0 ]; then
    log "已添加 $added 个公钥到 $auth_file"
  fi
  if [ "$skipped" -gt 0 ]; then
    warn "跳过 $skipped 个已存在的公钥"
  fi
}

# ── 启用 SSH 公钥登录 ─────────────────────────────────
enable_pubkey_auth() {
  sshd_config="/etc/ssh/sshd_config"

  if [ ! -f "$sshd_config" ]; then
    die "未找到 $sshd_config，请确认已安装 OpenSSH Server。"
  fi

  changed=0

  # PubkeyAuthentication yes
  if grep -qE '^\s*PubkeyAuthentication\s+yes' "$sshd_config"; then
    log "PubkeyAuthentication 已启用"
  else
    if grep -qE '^\s*#?\s*PubkeyAuthentication' "$sshd_config"; then
      sed -i 's/^[[:space:]]*#*[[:space:]]*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"
    else
      printf '\nPubkeyAuthentication yes\n' >> "$sshd_config"
    fi
    log "已设置 PubkeyAuthentication yes"
    changed=1
  fi

  # AuthorizedKeysFile（确保包含默认路径）
  if grep -qE '^\s*AuthorizedKeysFile' "$sshd_config"; then
    log "AuthorizedKeysFile 已配置"
  else
    if grep -qE '^\s*#\s*AuthorizedKeysFile' "$sshd_config"; then
      sed -i 's/^[[:space:]]*#[[:space:]]*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' "$sshd_config"
      log "已启用 AuthorizedKeysFile 配置"
      changed=1
    fi
  fi

  # 重启 sshd
  if [ "$changed" -eq 1 ]; then
    log "正在重启 sshd 服务..."
    if command -v systemctl >/dev/null 2>&1; then
      systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || warn "sshd 重启失败，请手动重启。"
    elif command -v service >/dev/null 2>&1; then
      service sshd restart 2>/dev/null || service ssh restart 2>/dev/null || warn "sshd 重启失败，请手动重启。"
    else
      warn "无法自动重启 sshd，请手动执行：systemctl restart sshd"
    fi
    log "sshd 配置已更新并重启"
  else
    log "sshd 配置无需修改"
  fi
}

# ── 主流程 ────────────────────────────────────────────
main() {
  require_root
  require_cmd curl

  log "GitHub 用户：$GITHUB_USER"

  keys="$(fetch_keys "$GITHUB_USER")"
  select_key "$keys"
  install_keys
  enable_pubkey_auth

  echo ""
  log "全部完成！"
  warn "请在新终端中测试 SSH 密钥登录，确认成功后再关闭当前会话。"
}

main "$@"
