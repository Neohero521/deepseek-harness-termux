#!/usr/bin/env bash
# stop.sh —— 停止 dsh web 服务并解除唤醒锁。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

info "停止 dsh 服务..."

# 1. 按 PID 文件停止
if [ -f "$PID_FILE" ]; then
    pid="$(cat "$PID_FILE")"
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
fi

# 2. 在 Debian 内终止 dsh 进程（兜底）
proot-distro login "$DISTRO" -- pkill -f "dsh" 2>/dev/null || true

# 3. Termux 侧终止 proot 登录进程（兜底）
pkill -f "proot-distro login $DISTRO -- dsh web" 2>/dev/null || true

sleep 1
termux-wake-unlock 2>/dev/null || true
info "已停止"
