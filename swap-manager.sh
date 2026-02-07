#!/bin/sh
set -eu

SWAP_FILE="/swapfile"
FSTAB_LINE="$SWAP_FILE none swap sw 0 0"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "请用 root 运行：sudo sh $0"
    exit 1
  fi
}

show_swap() {
  echo "当前 swap 信息："
  if command -v swapon >/dev/null 2>&1; then
    swapon --show
  else
    cat /proc/swaps
  fi
  echo
  if command -v free >/dev/null 2>&1; then
    free -h
  fi
}

# 判断 /swapfile 是否已启用
is_swap_active() {
  awk -v swap_file="$SWAP_FILE" 'NR > 1 && $1 == swap_file {found=1} END {exit !found}' /proc/swaps
}

# 获取 /swapfile 当前大小（单位 MB）
current_swapfile_mb() {
  if [ -f "$SWAP_FILE" ]; then
    bytes="$(stat -c %s "$SWAP_FILE" 2>/dev/null || wc -c < "$SWAP_FILE")"
    echo $((bytes / 1024 / 1024))
  else
    echo 0
  fi
}

# 写入并启用新的 /swapfile
create_swapfile() {
  size_mb="$1"
  rm -f "$SWAP_FILE"

  if command -v fallocate >/dev/null 2>&1; then
    if ! fallocate -l "${size_mb}M" "$SWAP_FILE"; then
      dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$size_mb"
    fi
  else
    dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$size_mb"
  fi

  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" >/dev/null
  swapon "$SWAP_FILE"
}

# 确保 /etc/fstab 有 swapfile 持久化配置
ensure_fstab() {
  if [ ! -f /etc/fstab ]; then
    return
  fi

  if grep -qE "^[[:space:]]*$SWAP_FILE[[:space:]]" /etc/fstab; then
    sed -i "\|^[[:space:]]*$SWAP_FILE[[:space:]]|c\\$FSTAB_LINE" /etc/fstab
  else
    printf '%s\n' "$FSTAB_LINE" >> /etc/fstab
  fi
}

# 从 /etc/fstab 删除 swapfile 配置
remove_fstab_entry() {
  if [ ! -f /etc/fstab ]; then
    return
  fi

  tmp_file="$(mktemp)"
  grep -vE "^[[:space:]]*$SWAP_FILE[[:space:]]" /etc/fstab > "$tmp_file" || true
  cat "$tmp_file" > /etc/fstab
  rm -f "$tmp_file"
}

increase_swap() {
  printf "请输入要增加的 swap 大小（单位 M）："
  read -r add_mb

  case "$add_mb" in
    ''|*[!0-9]*)
      echo "输入无效：请输入正整数。"
      return
      ;;
  esac

  if [ "$add_mb" -le 0 ]; then
    echo "输入无效：请输入大于 0 的值。"
    return
  fi

  current_mb="$(current_swapfile_mb)"
  target_mb=$((current_mb + add_mb))

  echo "准备调整：$current_mb M -> $target_mb M"

  if is_swap_active; then
    swapoff "$SWAP_FILE"
  fi

  create_swapfile "$target_mb"
  ensure_fstab

  echo "已增加 swap，总大小：${target_mb}M"
  show_swap
}

delete_swap() {
  if is_swap_active; then
    swapoff "$SWAP_FILE"
  fi

  rm -f "$SWAP_FILE"
  remove_fstab_entry

  echo "已删除 $SWAP_FILE（如存在）。"
  show_swap
}

show_menu() {
  echo "=============================="
  echo "Swap 管理菜单"
  echo "1. 查看当前 swap"
  echo "2. 增加 swap（单位 M）"
  echo "3. 删除 swap"
  echo "=============================="
}

main() {
  require_root
  show_menu
  printf "请输入选项 [1-3]："
  read -r choice

  case "$choice" in
    1) show_swap ;;
    2) increase_swap ;;
    3) delete_swap ;;
    *) echo "无效选项。"; exit 1 ;;
  esac
}

main "$@"
