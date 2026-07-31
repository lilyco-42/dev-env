#!/bin/sh
# dev-env — 跨平台一键安装引导
# 适用: termux (Android) / linux / macos / ios (iSH, Alpine)
# 用法:
#   curl -fsSL https://github.com/lilyco-42/dev-env/releases/latest/download/install.sh | sh
set -e

REPO="lilyco-42/dev-env"
URL="https://github.com/${REPO}/releases/latest/download/dev-env.nu"
BIN_DIR="${HOME}/.local/bin"

echo "==> dev-env 安装引导"

has() { command -v "$1" >/dev/null 2>&1; }

sudo_sh() {
  if [ "$(id -u)" = "0" ]; then
    "$@"
  elif has sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

install_nu() {
  if has nu; then return; fi
  echo "==> 安装 nushell ..."
  if has pkg; then
    pkg install -y nushell
  elif has apt-get; then
    sudo_sh apt-get update
    sudo_sh apt-get install -y nushell
  elif has dnf; then
    sudo_sh dnf install -y nushell
  elif has pacman; then
    sudo_sh pacman -S --noconfirm nushell
  elif has apk; then
    sudo_sh apk add nushell
  elif has brew; then
    brew install nushell
  elif has cargo; then
    cargo install nu --locked
  else
    echo "!! 无法自动安装 nushell, 请手动安装后重试" >&2
    exit 1
  fi
}

download() {
  echo "==> 下载 dev-env.nu ..."
  mkdir -p "${BIN_DIR}"
  if has curl; then
    curl -fsSL "${URL}" -o "${BIN_DIR}/dev-env.nu"
  elif has wget; then
    wget -qO "${BIN_DIR}/dev-env.nu" "${URL}"
  else
    echo "!! 需要 curl 或 wget" >&2
    exit 1
  fi
  chmod +x "${BIN_DIR}/dev-env.nu"
}

install_nu
download
echo "==> 运行 dev-env ($*)"
exec nu "${BIN_DIR}/dev-env.nu" "$@"
