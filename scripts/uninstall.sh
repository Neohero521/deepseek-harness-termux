#!/usr/bin/env bash
# uninstall.sh —— 彻底卸载 DeepSeek Harness for Termux。
# 会停止服务、移除 Debian 环境、删除脚本与运行时数据。不会删除 Termux 本身。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

warn "即将执行彻底卸载："
echo "  - 停止 dsh 服务"
echo "  - 移除 proot 的 $DISTRO 环境"
echo "  - 删除脚本目录 $DSH_DIR"
echo "  - 删除运行时数据 $RUN_DIR"
echo "  - 移除 ~/.bashrc 中的菜单自启动"
read -r -p "确认继续？输入 yes 回车：" confirm
if [ "$confirm" != "yes" ]; then
    echo "已取消"
    exit 0
fi

# 1. 停止
bash "$SCRIPTS_DIR/stop.sh" 2>/dev/null || true

# 2. 移除 Debian
if distro_installed; then
    info "移除 $DISTRO 环境..."
    proot-distro remove "$DISTRO"
fi

# 3. 清理 bashrc 钩子
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ]; then
    info "清理 bashrc 钩子..."
    grep -v "deepseek-harness-termux\|DSH_MENU_DONE\|dsh-termux/scripts/menu.sh" "$BASHRC" > "$BASHRC.tmp" || true
    mv "$BASHRC.tmp" "$BASHRC"
fi

# 4. 删除运行时数据与脚本
rm -rf "$RUN_DIR"
rm -rf "$DSH_DIR"

info "卸载完成。"
