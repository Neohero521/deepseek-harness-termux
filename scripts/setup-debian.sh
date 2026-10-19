#!/bin/bash
# setup-debian.sh —— 在 proot 的 Debian 环境内执行。
#
# 安装 Node.js（>= 20）与全局 @deepseek-ai/dsh。
# koffi 的 Linux/ARM64 预编译二进制会作为 npm 依赖自动安装，无需现场编译。
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

USE_MIRROR="${1:-}"
if [ "$USE_MIRROR" = "--mirror" ]; then
    NPM_REG="https://registry.npmmirror.com"
else
    NPM_REG="https://registry.npmjs.org"
fi

echo "==> [1/5] 更新 apt 并安装基础包..."
apt-get update
apt-get install -y ca-certificates curl gnupg git

echo "==> [2/5] 安装 Node.js（优先使用 apt 源，Debian 13 自带 20.x/22.x）..."
apt-get install -y nodejs npm || true
NODE_MAJOR="$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo 0)"
if [ "$NODE_MAJOR" -lt 20 ]; then
    echo "apt 源 Node 版本过低（当前 v$NODE_MAJOR），改用 NodeSource 安装 22.x..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
fi
echo "Node $(node -v)  npm $(npm -v)"

echo "==> [3/5] 设置 npm 源（$NPM_REG）..."
npm config set registry "$NPM_REG"

echo "==> [4/5] 升级 npm 并全局安装 @deepseek-ai/dsh ..."

# Debian 自带 npm 9，其 cacache 在 proot 下有已知 rename/ENOENT 问题，
# 先升级到新版 npm（Node >=20 兼容 npm 10/11）；升级本身若失败则清缓存重试一次。
npm install -g npm@latest --no-audit --no-fund 2>/dev/null || {
    warn "npm 升级失败，清理缓存重试一次..."
    npm cache clean --force 2>/dev/null || true
    sleep 2
    npm install -g npm@latest --no-audit --no-fund 2>/dev/null || warn "npm 仍升级失败，继续使用现有版本"
}
echo "npm $(npm -v)"

# 安装 dsh；失败自动清缓存重试，第二次起切换官方源兜底。
installed=0
for attempt in 1 2 3; do
    if npm install -g @deepseek-ai/dsh --no-audit --no-fund; then
        installed=1
        break
    fi
    warn "dsh 安装失败（第 $attempt 次），清理缓存后重试..."
    npm cache clean --force 2>/dev/null || true
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
