#!/usr/bin/env bash
# update.sh —— 更新全局 dsh 到最新版本。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

if ! distro_installed; then
    error "未找到 $DISTRO 环境，请先运行 Install.sh"
    exit 1
fi

info "更新 dsh..."
proot-distro login "$DISTRO" -- npm install -g @deepseek-ai/dsh
info "当前版本："
proot-distro login "$DISTRO" -- dsh --version
