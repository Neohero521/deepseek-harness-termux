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

# 5. 安装 Debian 环境
if proot-distro list | awk '{print $1}' | grep -qx "$DISTRO"; then
    info "$DISTRO 环境已存在，跳过安装"
else
    info "安装 $DISTRO 环境（约几分钟）..."
    proot-distro install "$DISTRO"
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
