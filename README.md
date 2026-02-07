# VPS Toolkit

[English](#english) | [中文](#chinese)

<a name="english"></a>
## English

A collection of simple scripts for VPS management, designed to streamline common tasks on a newly purchased server.

### Scripts

- **quick-zsh-setup.sh**: Quickly install and configure Zsh, Oh My Zsh, and useful plugins (autosuggestions, syntax highlighting) on your VPS.
- **swap-manager.sh**: Easily manage swap space (view, add, delete) on your VPS.

### Usage

#### Option 1: One-line Installation (Recommended)

Run the script directly without downloading the repository:

**Quick Zsh Setup:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/quick-zsh-setup.sh)
```

**Swap Manager:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/swap-manager.sh)
```

#### Option 2: Clone & Run

Clone the repository and run the desired script:

```bash
git clone https://github.com/Impersonality/VPS-Toolkit.git
cd VPS-Toolkit

# For Zsh setup
chmod +x quick-zsh-setup.sh
./quick-zsh-setup.sh

# For Swap management
chmod +x swap-manager.sh
./swap-manager.sh
```

---

<a name="chinese"></a>
## 中文

这是一个用于存放 VPS 简单管理脚本的项目，旨在简化新购服务器后的常见配置任务。

### 脚本列表

- **quick-zsh-setup.sh**: 快速在 VPS 上安装并配置 Zsh、Oh My Zsh 以及常用插件（自动建议、语法高亮）。
- **swap-manager.sh**: 轻松管理 VPS 上的 Swap 空间（查看、添加、删除）。

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
```
