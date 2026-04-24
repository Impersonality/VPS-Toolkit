# VPS Toolkit

[English](README.md) | 中文

## 中文

这是一个用于存放 VPS 简单管理脚本的项目，旨在简化新购服务器后的常见配置任务。

### 脚本列表

- **toolkit.sh**: **统一入口** — 交互式菜单，一条命令即可访问 SSH 密钥配置、Swap 管理、Zsh 一键配置、Rclone配置下载、常用命令小抄和 Speedtest 安装。
- **quick-zsh-setup.sh**: 快速在 VPS 上安装并配置 Zsh、Oh My Zsh 以及常用插件（自动建议、语法高亮）。
- **swap-manager.sh**: 轻松管理 VPS 上的 Swap 空间（查看、添加、删除）。
- **ssh-key-setup.sh**: 从 GitHub 获取 SSH 公钥，添加到 `authorized_keys`，启用 SSH 密钥登录，并关闭密码登录以增强安全性。
- **speedtest-install.sh**: 安装 Ookla 官方 Speedtest CLI 测速工具。安装前自动检测系统兼容性（如 Ubuntu 24.04 不受支持会提示）。
- **rclone-setup.sh**: 在 Debian/Ubuntu 系统上安装 rclone 并自动配置预设的 `rclone.conf`。如已有配置文件会自动备份。

### 使用方法

运行统一菜单入口，一条命令搞定：

```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/toolkit.sh)
```

也可以单独运行各脚本：

```bash
# Zsh 快速安装
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/quick-zsh-setup.sh)

# Swap 管理
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/swap-manager.sh)

# SSH 密钥配置
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/ssh-key-setup.sh)

# Speedtest 测速安装
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/speedtest-install.sh)

# Rclone 安装配置
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/rclone-setup.sh)
```
