# VPS Toolkit

[English](#english) | [中文](README_CN.md)

<a name="english"></a>
## English

A collection of simple scripts for VPS management, designed to streamline common tasks on a newly purchased server.

### Scripts

- **toolkit.sh**: **Unified entry point** — an interactive menu that gives you access to all tools below. Just run one command!
- **quick-zsh-setup.sh**: Quickly install and configure Zsh, Oh My Zsh, and useful plugins (autosuggestions, syntax highlighting) on your VPS.
- **swap-manager.sh**: Easily manage swap space (view, add, delete) on your VPS.
- **ssh-key-setup.sh**: Fetch SSH public keys from GitHub, add them to `authorized_keys`, and enable SSH key authentication on your VPS.
- **speedtest-install.sh**: Install the official Ookla Speedtest CLI. Automatically checks OS compatibility before installation (e.g. Ubuntu 24.04 is not supported).
- **rclone-setup.sh**: Install rclone and configure it with a predefined `rclone.conf` on Debian/Ubuntu systems. Backs up any existing configuration automatically.

### Usage

#### Option 1: One-line Installation (Recommended)

Run the unified toolkit menu with a single command:

```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/toolkit.sh)
```

Or run individual scripts directly:

**Quick Zsh Setup:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/quick-zsh-setup.sh)
```

**Swap Manager:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/swap-manager.sh)
```

**SSH Key Setup:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/ssh-key-setup.sh)
```

**Speedtest Install:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/speedtest-install.sh)
```

**Rclone Setup:**
```bash
bash <(curl -L https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/rclone-setup.sh)
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

# For SSH key setup
chmod +x ssh-key-setup.sh
sudo ./ssh-key-setup.sh

# For Speedtest install
chmod +x speedtest-install.sh
sudo ./speedtest-install.sh

# For Rclone setup
chmod +x rclone-setup.sh
sudo ./rclone-setup.sh
```
