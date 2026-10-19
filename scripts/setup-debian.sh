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

echo "==> [4/5] 安装 @deepseek-ai/dsh ..."

# 磁盘空间检查
SPACE="$(df -h / | awk 'NR==2 {print $4}')"
echo "当前可用空间：$SPACE（推荐 500MB 以上）"

# proot 环境下 Debian 自带 npm 9 的 cacache 会反复报 ENOENT rename
# （Invalid response body），且 npm 升级自身也走同一机制被卡死。
# 因此依次尝试：pnpm（corepack）→ 手动解压 npm 11 → 原 npm 重试。
rm -rf /root/.npm
installed=0

# 路径 1：pnpm —— corepack 随 Node 自带，下载与缓存不依赖 npm cacache
if command -v corepack >/dev/null 2>&1; then
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    corepack enable 2>/dev/null || true
    if command -v pnpm >/dev/null 2>&1; then
        echo "尝试用 pnpm 安装（corepack 自带）..."
        if pnpm add -g @deepseek-ai/dsh --strict-peer-dependencies=false; then
            installed=1
        else
            warn "pnpm 安装失败，改用 npm 11"
        fi
    fi
fi

# 路径 2：手动下载 npm 11 tarball 并解压替换（绕过 npm 自身的安装机制）
if [ "$installed" != "1" ]; then
    echo "尝试手动升级 npm 到 11.x..."
    rm -rf /tmp/npm-fix && mkdir -p /tmp/npm-fix
    REG="$NPM_REG"
    if curl -fsSL "$REG/npm/-/npm-11.3.0.tgz" -o /tmp/npm-fix/npm.tgz \
        && [ -s /tmp/npm-fix/npm.tgz ]; then
        rm -rf /usr/local/lib/node_modules/npm
        mkdir -p /usr/local/lib/node_modules/npm
        tar -xzf /tmp/npm-fix/npm.tgz -C /usr/local/lib/node_modules/npm --strip-components=1
        ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
        echo "npm 已升级为 $(npm -v)"
        if npm install -g @deepseek-ai/dsh --no-audit --no-fund; then
            installed=1
        else
            warn "npm 11 安装失败，重建缓存后用原 npm 再试"
        fi
    else
        warn "npm tarball 下载失败（$REG）"
    fi
fi

# 路径 3：原 npm 重建缓存重试
if [ "$installed" != "1" ]; then
    for attempt in 1 2; do
        rm -rf /root/.npm
        sleep 2
        warn "dsh 安装失败（第 $attempt 次），重建缓存后重试..."
        if npm install -g @deepseek-ai/dsh --no-audit --no-fund; then
            installed=1
            break
        fi
    done
fi

if [ "$installed" != "1" ]; then
    echo "==> [x] dsh 安装失败，请检查网络后重新运行：bash /root/setup-debian.sh"
    exit 1
fi

echo "==> [5/5] 验证安装..."
dsh --version

echo "==> Debian 内环境配置完成"
