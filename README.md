# VPS Toolkit

[English](#english) | [中文](README_CN.md)

<a name="english"></a>
## English

A collection of simple scripts for VPS management, designed to streamline common tasks on a newly purchased server.

### Scripts

- **toolkit.sh**: **Unified entry point** — an interactive menu that gives you access to SSH key setup, swap management, Zsh setup, `rclone` config download, a small common-commands cheatsheet, and Speedtest install. Just run one command!
- **quick-zsh-setup.sh**: Quickly install and configure Zsh, Oh My Zsh, and useful plugins (autosuggestions, syntax highlighting) on your VPS.
- **swap-manager.sh**: Easily manage swap space (view, add, delete) on your VPS.
- **ssh-key-setup.sh**: Fetch SSH public keys from GitHub, add them to `authorized_keys`, enable SSH key authentication, and disable password login for enhanced security.
- **speedtest-install.sh**: Install the official Ookla Speedtest CLI. Automatically checks OS compatibility before installation (e.g. Ubuntu 24.04 is not supported).
- **rclone-setup.sh**: Install rclone and configure it with a predefined `rclone.conf` on Debian/Ubuntu systems. Backs up any existing configuration automatically.

### Usage

Run the unified toolkit menu with a single command:

```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/toolkit.sh)
```

Or run individual scripts directly:

```bash
# Quick Zsh Setup
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/quick-zsh-setup.sh)

# Swap Manager
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/swap-manager.sh)

# SSH Key Setup
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/ssh-key-setup.sh)

# Speedtest Install
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/speedtest-install.sh)

# Rclone Setup
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/rclone-setup.sh)
```
