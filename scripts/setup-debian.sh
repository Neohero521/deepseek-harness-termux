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

USE_MIRROR="${1:-}"
if [ "$USE_MIRROR" = "--mirror" ]; then
    NPM_REG="https://registry.npmmirror.com"
else
    NPM_REG="https://registry.npmjs.org"
fi

echo "==> [1/5] 更新 apt 并安装基础包..."
apt-get update
apt-get install -y ca-certificates curl gnupg git

echo "==> [2/5] 安装 Node.js（优先使用 apt 源，Debian 13 自带 22.x）..."
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

echo "==> [4/5] 全局安装 @deepseek-ai/dsh（koffi 预编译版自动安装，不编译）..."
npm install -g @deepseek-ai/dsh

echo "==> [5/5] 验证安装..."
dsh --version

echo "==> Debian 内环境配置完成"
