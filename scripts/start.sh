#!/usr/bin/env bash
# start.sh —— 启动 dsh web 服务（后台运行、等待就绪、自动打开浏览器）。
#
# 关键点：dsh 首次启动需初始化整个 Cordis 插件树，约 1 分钟，期间无任何输出，
# 属正常现象；就绪后日志会打印带 token 的地址。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

mkdir -p "$RUN_DIR"

if is_running; then
    warn "服务已在运行"
    URL="$(get_url)"
    if [ -n "$URL" ]; then
        echo "访问地址：$URL"
        termux-open-url "$URL" 2>/dev/null || true
    fi
    exit 0
fi

if ! distro_installed; then
    error "未找到 $DISTRO 环境，请先运行 Install.sh"
    exit 1
fi

info "启用唤醒锁（防止锁屏后进程被杀）..."
termux-wake-lock 2>/dev/null || warn "termux-wake-lock 不可用（需安装 termux-api）"

info "启动 dsh 服务（首次初始化约需 1 分钟，期间无输出，请勿退出）..."
: > "$LOG_FILE"
nohup proot-distro login "$DISTRO" -- dsh web --no-open > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

# 轮询等待就绪（最多约 150 秒）
ready=0
for _ in $(seq 1 75); do
    if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        error "服务进程意外退出，日志如下："
        cat "$LOG_FILE"
        rm -f "$PID_FILE"
        termux-wake-unlock 2>/dev/null || true
        exit 1
    fi
    URL="$(get_url)"
    if [ -n "$URL" ]; then
        ready=1
        echo "$URL" > "$URL_FILE"
        break
    fi
    printf "."
    sleep 2
done
echo ""

if [ "$ready" = "1" ]; then
    info "启动成功！"
    echo "Web UI 地址：$URL"
    echo "正在打开浏览器..."
    termux-open-url "$URL" 2>/dev/null || warn "无法自动打开，请手动复制上面的地址到浏览器"
else
    warn "等待超时（150 秒），进程仍在后台初始化，稍后可运行 open.sh 打开，或查看日志："
    echo "  tail -f $LOG_FILE"
fi
