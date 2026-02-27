# VPS Toolkit

[English](README.md) | 中文

## 中文

这是一个用于存放 VPS 简单管理脚本的项目，旨在简化新购服务器后的常见配置任务。

### 脚本列表

- **quick-zsh-setup.sh**: 快速在 VPS 上安装并配置 Zsh、Oh My Zsh 以及常用插件（自动建议、语法高亮）。
- **swap-manager.sh**: 轻松管理 VPS 上的 Swap 空间（查看、添加、删除）。
- **ssh-key-setup.sh**: 从 GitHub 获取 SSH 公钥，添加到 `authorized_keys`，并启用 SSH 密钥登录。
- **speedtest-install.sh**: 安装 Ookla 官方 Speedtest CLI 测速工具。安装前自动检测系统兼容性（如 Ubuntu 24.04 不受支持会提示）。
- **rclone-setup.sh**: 在 Debian/Ubuntu 系统上安装 rclone 并自动配置预设的 `rclone.conf`。如已有配置文件会自动备份。

### 使用方法

#### 方式 1：一键运行（推荐）

无需下载整个项目，直接运行脚本：

**Zsh 快速安装：**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/quick-zsh-setup.sh)
```

**Swap 管理：**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/swap-manager.sh)
```

**SSH 密钥配置：**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/ssh-key-setup.sh)
```

**Speedtest 测速安装：**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/speedtest-install.sh)
```

**Rclone 安装配置：**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/rclone-setup.sh)
```

#### 方式 2：克隆仓库并运行

克隆仓库并运行相应的脚本：

```bash
git clone https://github.com/Impersonality/VPS-Toolkit.git
cd VPS-Toolkit

# Zsh 安装
chmod +x quick-zsh-setup.sh
./quick-zsh-setup.sh

# Swap 管理
chmod +x swap-manager.sh
./swap-manager.sh

# SSH 密钥配置
chmod +x ssh-key-setup.sh
sudo ./ssh-key-setup.sh

# Speedtest 测速安装
chmod +x speedtest-install.sh
sudo ./speedtest-install.sh

# Rclone 安装配置
chmod +x rclone-setup.sh
sudo ./rclone-setup.sh
```
