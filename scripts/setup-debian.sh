#!/bin/bash
# setup-debian.sh —— 在 proot 的 Debian 环境内执行。
#
# 安装 Node.js 22（官方二进制，自带 npm 10）与全局 @deepseek-ai/dsh。
# koffi 的 Linux/ARM64 预编译二进制会作为 npm 依赖自动安装，无需现场编译。
#
# 为什么不用 Debian apt 自带的 nodejs/npm：
#   Debian 13 自带 npm 9.2，其 cacache 在 proot 下会反复报
#   "Invalid response body ... ENOENT rename"，且 npm 升级自身也走同一
#   缓存路径被卡死。改用官方 Node 22 二进制（自带 npm 10）后问题消失。
#
# 用法：
#   bash setup-debian.sh            # 使用官方 npm 源
#   bash setup-debian.sh --mirror   # 使用 npmmirror 国内镜像

set -e
export DEBIAN_FRONTEND=noninteractive

# 本脚本独立运行于 Debian 内（不 source common.sh），自带基础函数
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[*]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

NODE_VER="22.19.0"

USE_MIRROR="${1:-}"
if [ "$USE_MIRROR" = "--mirror" ]; then
    NPM_REG="https://registry.npmmirror.com"
    NODE_BASE="https://npmmirror.com/mirrors/node/v$NODE_VER"
else
    NPM_REG="https://registry.npmjs.org"
    NODE_BASE="https://nodejs.org/download/release/v$NODE_VER"
fi

# CPU 架构 -> Node 官方二进制架构名
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64|amd64)  ARCH="x64" ;;
    armv7l)        ARCH="armv7l" ;;
    *)             ARCH="arm64" ;;
esac

echo "==> [1/5] 更新 apt 并安装基础包..."
apt-get update
apt-get install -y ca-certificates curl xz-utils tar gnupg git

echo "==> [2/5] 安装 Node.js $NODE_VER（官方二进制，含 npm 10）..."
if [ "$(node -v 2>/dev/null || true)" != "v$NODE_VER" ]; then
    PKG="node-v$NODE_VER-linux-$ARCH.tar.xz"
    echo "下载 $NODE_BASE/$PKG ..."
    curl -fsSL --connect-timeout 15 --max-time 600 "$NODE_BASE/$PKG" -o /tmp/node.tar.xz
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1
    rm -f /tmp/node.tar.xz
    hash -r 2>/dev/null || true
fi
echo "Node $(node -v)  npm $(npm -v)"

echo "==> [3/5] 设置 npm 源（$NPM_REG）..."
npm config set registry "$NPM_REG"

echo "==> [4/5] 全局安装 @deepseek-ai/dsh ..."
SPACE="$(df -h / | awk 'NR==2 {print $4}')"
echo "当前可用空间：$SPACE（推荐 500MB 以上）"
rm -rf /root/.npm
installed=0
for attempt in 1 2 3; do
    if npm install -g @deepseek-ai/dsh --no-audit --no-fund; then
        installed=1
        break
    fi
    warn "dsh 安装失败（第 $attempt 次），重建缓存后重试..."
    rm -rf /root/.npm
    sleep 3
    if [ "$attempt" = "1" ] && [ "$NPM_REG" != "https://registry.npmjs.org" ]; then
        warn "切换到官方源重试..."
        npm config set registry https://registry.npmjs.org
    fi
done

if [ "$installed" != "1" ]; then
    echo "==> [x] dsh 安装失败，请检查网络后重新运行：bash /root/setup-debian.sh"
    exit 1
fi

echo "==> [5/5] 验证安装..."
dsh --version

echo "==> Debian 内环境配置完成"
