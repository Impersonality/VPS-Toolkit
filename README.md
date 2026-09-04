# VPS Toolkit

[English](#english) | [中文](README_CN.md)

<a name="english"></a>

A small, locally installed menu for VPS setup and maintenance. Run `vps`, move
with the Up and Down keys, press Enter to execute, and press Esc to go back. It
does not use a Go TUI or switch to an alternate terminal screen.

## Install

```bash
bash <(curl -fsSL https://sh.3773774.xyz)
```

GitHub fallback:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/install.sh)
```

Run the menu after installation:

```bash
vps
```

The toolkit is stored locally. Normal actions do not download the toolkit
again, and update and uninstall actions are available from the menu. After
installation, `vps` is the only command you need to remember.

## Menu Controls

- `Up` / `Down`: move between items
- `Enter`: execute the selected item
- `Esc`: return to the previous menu, or exit from the main menu

## GitHub Proxy

Set a proxy prefix in `/etc/vps-toolkit/config` when GitHub is not directly
reachable:

```bash
VPS_GITHUB_PROXY="https://ghfast.top/"
```

Example installation through the same proxy:

```bash
curl -fsSL "https://ghfast.top/https://raw.githubusercontent.com/Impersonality/VPS-Toolkit/main/install.sh" \
  | VPS_GITHUB_PROXY="https://ghfast.top/" bash
```

The proxy is used only for public GitHub files. The authenticated GitHub Gist
request used by the rclone setup is sent directly to GitHub to avoid exposing
the token to a public proxy.

Public proxy services are not controlled by this project. Scripts executed as
root should only be downloaded through a proxy you trust.

## Included Features

- SSH public key setup
- Swap management
- Zsh and Oh My Zsh setup
- rclone installation and private Gist configuration
- Personal backup command reference
- Debian 12, Debian 13 and Ubuntu 24.04 reinstall presets
- NodeQuality, TcpQuality, tcpfit, Fusion Monster and unlock tests
- Singbox installer from 233boy
- Docker and WARP installers
