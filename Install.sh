#!/usr/bin/env bash
# Install.sh —— DeepSeek Harness for Termux 一键安装引导。
#
# 用法（在 Termux 中执行）：
#   curl -O https://raw.githubusercontent.com/Neohero521/deepseek-harness-termux/main/Install.sh && bash Install.sh

set -e

REPO_URL="https://github.com/Neohero521/deepseek-harness-termux.git"
REPO_DIR="$HOME/dsh-termux"
DISTRO="debian"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[*]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*"; }

# 1. 环境检测
if [ -z "$PREFIX" ] || ! echo "$PREFIX" | grep -q "com.termux"; then
    error "请在 Termux 中运行本脚本（Termux 可从 F-Droid 或官方 GitHub 下载）。"
    exit 1
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   DeepSeek Harness for Termux 安装程序${NC}"
echo -e "${CYAN}========================================${NC}"
echo "  官方项目：https://github.com/deepseek-ai/deepseek-harness"
echo ""

# 2. 询问是否使用国内镜像
read -r -p "是否使用国内镜像加速（npmmirror）？[Y/n] " mirror
mirror_flag=""
if [ "$mirror" != "n" ] && [ "$mirror" != "N" ]; then
    mirror_flag="--mirror"
fi

# 3. 获取/更新脚本仓库
if [ -d "$REPO_DIR/.git" ]; then
    info "已存在脚本仓库，更新中..."
    git -C "$REPO_DIR" pull --ff-only || warn "仓库更新失败，继续使用现有版本"
else
    info "下载脚本仓库..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

# 4. 更新包管理器并安装 Termux 依赖
info "更新包管理器..."
pkg update -y

info "安装 Termux 依赖（proot-distro / termux-api / curl / git）..."
pkg install -y proot-distro termux-api curl git

# 5. 确保 Debian 环境存在（已注册或目录存在均视为已安装）
# 注意：proot-distro list 的输出可能走 stderr，必须 2>&1 保留
distro_exists() {
    proot-distro list 2>&1 | grep -qw "$DISTRO" \
        || [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO" ]
}

if distro_exists; then
    info "$DISTRO 环境已存在，跳过安装"
else
    info "安装 $DISTRO 环境（约几分钟）..."
    if ! proot-distro install "$DISTRO"; then
        if distro_exists; then
            info "检测到 $DISTRO 已注册（安装命令报错但环境可用），继续"
        else
            error "Debian 环境安装失败"
            exit 1
        fi
    fi
fi

# 验证 Debian 可正常登录；若 rootfs 损坏（注册信息在但文件缺失），引导重置
if ! proot-distro login "$DISTRO" -- true 2>/dev/null; then
    warn "$DISTRO 注册信息存在但环境损坏（之前安装中断/清理遗留）"
    read -r -p "现在重置 $DISTRO 并重新下载（约 200MB）？[Y/n] " do_reset
    if [ "$do_reset" = "n" ] || [ "$do_reset" = "N" ]; then
        error "请手动执行 proot-distro reset $DISTRO 后，再重新运行本脚本"
        exit 1
    fi
    info "重置 $DISTRO 环境（重新下载安装，约几分钟）..."
    proot-distro reset "$DISTRO"
    if ! proot-distro login "$DISTRO" -- true 2>/dev/null; then
        error "重置后仍无法登录 $DISTRO"
        exit 1
    fi
fi

# 6. 在 Debian 内安装 Node 与 dsh
info "配置 Debian 内环境（Node.js + dsh）..."
DEBIAN_ROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO"
cp "$REPO_DIR/scripts/setup-debian.sh" "$DEBIAN_ROOT/root/setup-debian.sh"
proot-distro login "$DISTRO" -- bash /root/setup-debian.sh $mirror_flag

# 7. 配置 bashrc 菜单自启动
BASHRC="$HOME/.bashrc"
if ! grep -q "deepseek-harness-termux" "$BASHRC" 2>/dev/null; then
    info "配置管理菜单自启动..."
    cat >> "$BASHRC" <<'EOF'
# deepseek-harness-termux
if [ -f "$HOME/dsh-termux/scripts/menu.sh" ] && [ -z "$DSH_MENU_DONE" ]; then
    export DSH_MENU_DONE=1
    bash "$HOME/dsh-termux/scripts/menu.sh"
fi
EOF
fi

# 8. 完成
echo -e "${CYAN}========================================${NC}"
info "安装完成！"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "  重启 Termux 会自动进入管理菜单；或立即运行："
echo "    bash $REPO_DIR/scripts/menu.sh"
echo ""
echo "  选择「1. 启动服务并打开界面」，等待约 1 分钟后浏览器自动打开。"
echo "  Web UI 默认端口：3080（地址中带一次性 token，由脚本自动提取）。"
