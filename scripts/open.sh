#!/usr/bin/env bash
# open.sh —— 打开 Web UI（从日志提取最新 token 地址并调起浏览器）。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

if ! is_running; then
    error "服务未运行，请先启动（菜单选 1）"
    exit 1
fi

URL="$(get_url)"
if [ -z "$URL" ] && [ -f "$URL_FILE" ]; then
    URL="$(cat "$URL_FILE")"
fi
if [ -z "$URL" ]; then
    error "未找到访问地址，服务可能仍在初始化，请稍后再试"
    exit 1
fi

info "打开 Web UI：$URL"
termux-open-url "$URL" 2>/dev/null || warn "无法自动打开，请手动复制地址到浏览器"
