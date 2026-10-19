#!/usr/bin/env bash
# common.sh —— 公共变量与函数，供其余脚本 source。

# 脚本所在目录与仓库根目录
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSH_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"

# 运行时目录（Termux HOME 下，便于备份与清理）
RUN_DIR="$HOME/.dsh-run"
LOG_FILE="$RUN_DIR/dsh.log"
PID_FILE="$RUN_DIR/dsh.pid"
URL_FILE="$RUN_DIR/dsh.url"

# proot-distro 中使用的发行版别名
DISTRO="debian"

# dsh web 监听端口
DSH_PORT="3080"

# 颜色
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''
fi

info()  { echo -e "${GREEN}[*]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*"; }
title() { echo -e "${CYAN}== $* ==${NC}"; }

# 是否在 Termux 中运行
is_termux() {
    [ -n "$PREFIX" ] && echo "$PREFIX" | grep -q "com.termux"
}

# proot 发行版是否已安装
distro_installed() {
    [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO" ]
}

# dsh 服务是否在运行（按 PID 文件 + 进程存活判断）
is_running() {
    [ -f "$PID_FILE" ] || return 1
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null)"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# 从日志中提取带 token 的访问地址（dsh 每次启动会生成新 token）
get_url() {
    grep -o "http://127.0.0.1:$DSH_PORT/?token=[A-Za-z0-9_]*" "$LOG_FILE" 2>/dev/null | tail -1
}

# 端口是否可连
port_ready() {
    curl -s -o /dev/null --max-time 2 "http://127.0.0.1:$DSH_PORT/"
}
