#!/usr/bin/env bash
# menu.sh —— DeepSeek Harness for Termux 管理菜单。

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPTS_DIR/common.sh"

pause() {
    echo ""
    read -r -p "按回车返回菜单..." _
}

while true; do
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   DeepSeek Harness for Termux${NC}"
    echo -e "${CYAN}========================================${NC}"
    if is_running; then
        echo -e "   状态：${GREEN}运行中${NC}   端口 $DSH_PORT"
    else
        echo -e "   状态：${RED}未运行${NC}"
    fi
    echo -e "${CYAN}----------------------------------------${NC}"
    echo "   1. 启动服务并打开界面"
    echo "   2. 停止服务"
    echo "   3. 重启服务"
    echo "   4. 打开 Web UI"
    echo "   5. 查看运行日志"
    echo "   6. 更新 dsh"
    echo "   7. 修复环境（重新安装 Node 与 dsh）"
    echo "   8. 彻底卸载"
    echo "   0. 退出菜单"
    echo -e "${CYAN}----------------------------------------${NC}"
    read -r -p "请选择: " choice

    case "$choice" in
        1)
            bash "$SCRIPTS_DIR/start.sh"
            pause
            ;;
        2)
            bash "$SCRIPTS_DIR/stop.sh"
            pause
            ;;
        3)
            bash "$SCRIPTS_DIR/stop.sh"
            bash "$SCRIPTS_DIR/start.sh"
            pause
            ;;
        4)
            bash "$SCRIPTS_DIR/open.sh"
            pause
            ;;
        5)
            title "最近 40 行日志（Ctrl+C 退出查看）"
            tail -n 40 "$LOG_FILE" 2>/dev/null || warn "暂无日志"
            pause
            ;;
        6)
            bash "$SCRIPTS_DIR/update.sh"
            pause
            ;;
        7)
            title "修复环境"
            read -r -p "是否使用国内镜像？[Y/n] " mirror
            mirror_flag=""
            if [ "$mirror" != "n" ] && [ "$mirror" != "N" ]; then
                mirror_flag="--mirror"
            fi
            if distro_installed; then
                cp "$SCRIPTS_DIR/setup-debian.sh" "$(distro_root)/root/setup-debian.sh"
                proot-distro login "$DISTRO" -- bash /root/setup-debian.sh $mirror_flag
            else
                error "未找到 $DISTRO 环境，请重新运行 Install.sh"
            fi
            pause
            ;;
        8)
            bash "$SCRIPTS_DIR/uninstall.sh"
            exit 0
            ;;
        0)
            info "已退出菜单（可运行 menu.sh 重新打开）"
            exit 0
            ;;
        *)
            warn "无效选择"
            sleep 1
            ;;
    esac
done
