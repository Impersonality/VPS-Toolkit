#!/usr/bin/env bash
set -euo pipefail

# 这些命令是个人 VPS 的操作备忘，只展示，不自动执行。
cat <<'EOF'
Common commands
===============

1. List the R2 backup directory
rclone tree r2:kg3773/vps-backup --level 1

2. Stop containers, create an archive, then restart containers
containers=$(docker ps -q); [ -n "$containers" ] && printf "%s\n" "$containers" | xargs -r docker stop; tar -czvf /root/vps_docker_backup.tar.gz -C /root docker_local Softwares; [ -n "$containers" ] && printf "%s\n" "$containers" | xargs -r docker start

3. Upload the archive
rclone copy /root/vps_docker_backup.tar.gz r2:kg3773/vps-backup/

4. Download the archive
rclone copy r2:kg3773/vps-backup/vps_docker_backup.tar.gz /root/

5. Weekly backup cron
0 3 * * 1 /bin/sh -c 'containers=$(/usr/bin/docker ps -q); [ -n "$containers" ] && echo "$containers" | /usr/bin/xargs -r /usr/bin/docker stop; /usr/bin/tar -czvf /root/vps_docker_backup.tar.gz -C /root docker_local Softwares && /usr/bin/rclone copy /root/vps_docker_backup.tar.gz r2:kg3773/vps-backup/ --config /root/.config/rclone/rclone.conf; [ -n "$containers" ] && echo "$containers" | /usr/bin/xargs -r /usr/bin/docker start' >> /var/log/rclone-backup.log 2>&1
EOF
