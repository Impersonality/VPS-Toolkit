# VPS Toolkit

[English](README.md) | 中文

一个安装到本地的轻量 VPS 工具箱。运行 `vps` 后使用上下方向键选择功能，
按 Enter 执行，按 Esc 返回上一级。菜单不依赖 Go TUI，也不切换终端屏幕。

## 安装

```bash
bash <(curl -fsSL https://sh.3773774.xyz)
```

GitHub 直连备用地址：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/install.sh)
```

安装后运行：

```bash
vps
```

工具和自有脚本都保存在本机，普通操作不会重复下载项目文件。更新和卸载也在
菜单中完成，安装后只需要记住 `vps`。

## 菜单操作

- `Up` / `Down`：上下移动
- `Enter`：执行当前功能
- `Esc`：返回上一级，在主菜单中退出

主菜单直接提供 SSH、Swap、Zsh、Rclone、常用命令、Singbox、更新和卸载。
系统重装、测试脚本和应用安装保留各自的二级菜单。

## GitHub 加速

无法直连 GitHub 时，可以在 `/etc/vps-toolkit/config` 中设置代理前缀：

```bash
VPS_GITHUB_PROXY="https://ghfast.top/"
```

首次安装也可以使用相同代理：

```bash
curl -fsSL "https://ghfast.top/https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/install.sh" \
  | VPS_GITHUB_PROXY="https://ghfast.top/" bash
```

代理只处理公开的 GitHub 文件。Rclone 配置使用带 Token 的 GitHub Gist API，
为了避免向公共代理泄露 Token，该请求仍然直连 GitHub。

公共加速服务不受本项目控制。脚本会以 root 权限执行，请只使用你信任的代理。

## 功能

- SSH 公钥配置
- Swap 查看、增加和删除
- Zsh、Oh My Zsh 和常用插件安装
- Rclone 安装及私有 Gist 配置
- 个人备份命令备忘
- Debian 12、Debian 13、Ubuntu 24.04 重装
- NodeQuality、TcpQuality、tcpfit、融合怪和解锁测试
- Singbox（233boy）
- Docker 和 WARP（fscarmen）

## 配置

配置文件位于 `/etc/vps-toolkit/config`：

```bash
# GitHub 代理，留空表示直连。
VPS_GITHUB_PROXY=""

# SSH Key 功能读取该用户的公开密钥。
VPS_GITHUB_USER="Impersonality"
```
