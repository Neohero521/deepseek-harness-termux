# DeepSeek Harness for Termux

在安卓设备上一键部署 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`，基于 Cordis、"一切皆插件"的 AI Agent 框架）。

仿照 [SillyTavern-Termux](https://github.com/print-yuhuan/SillyTavern-Termux) 的一键部署模式，把环境准备、依赖安装、启动管理全部脚本化。

## 快速开始

### 1. 安装 Termux

请从 **F-Droid** 或 **Termux 官方 GitHub** 下载安装（**不要用 Google Play 版**，已停止维护）。

### 2. 一键安装

打开 Termux，粘贴并执行：

```bash
curl -O https://raw.githubusercontent.com/Neohero521/deepseek-harness-termux/main/Install.sh && bash Install.sh
```

安装过程中会询问是否使用国内镜像（默认使用 npmmirror）。首次安装约需 **5–15 分钟**（下载 Debian 环境与 dsh 依赖，约 300–500 MB）。

### 3. 启动使用

安装完成后重启 Termux 即自动进入管理菜单，或手动运行：

```bash
bash ~/dsh-termux/scripts/menu.sh
```

选择 **「1. 启动服务并打开界面」**，等待约 1 分钟（初始化 Cordis 插件树），浏览器会自动打开 Web UI。

## 功能特性

- 一键完成：环境检测 → 安装 proot Debian → 安装 Node.js → 安装 dsh → 配置菜单自启动
- 管理菜单：启动 / 停止 / 重启 / 打开界面 / 查看日志 / 更新 / 修复 / 卸载
- 自动处理 **token 安全围栏**：dsh 每次启动生成带 token 的地址，脚本自动提取并打开
- 自动启用 **唤醒锁**（termux-wake-lock），防止锁屏后服务被杀
- 支持国内镜像（npmmirror）加速

## 为什么需要 proot（而不是直接在 Termux 跑）

dsh 依赖 `koffi`（原生 FFI 库），koffi 官方只发布 **Linux glibc / Windows / macOS** 的预编译二进制，**没有 Android bionic 版本**。在 Termux 中直接安装会回退到源码编译，并依次撞上 bionic 缺失的系统调用（`statx`、`renameat2` 等）。

因此本项目通过 `proot-distro` 在 Termux 内运行一个 Debian（glibc）环境，koffi 直接使用官方 Linux ARM64 预编译包，**全程无需编译**。

## 系统要求

- Android 7.0 及以上
- Termux（F-Droid / 官方 GitHub 版）
- 至少 1 GB 可用存储空间
- 稳定网络（首次建议 WiFi）

## 常用命令

| 操作 | 命令 |
|---|---|
| 打开管理菜单 | `bash ~/dsh-termux/scripts/menu.sh` |
| 启动服务 | `bash ~/dsh-termux/scripts/start.sh` |
| 停止服务 | `bash ~/dsh-termux/scripts/stop.sh` |
| 打开 Web UI | `bash ~/dsh-termux/scripts/open.sh` |
| 更新 dsh | `bash ~/dsh-termux/scripts/update.sh` |
| 彻底卸载 | `bash ~/dsh-termux/scripts/uninstall.sh` |

## 常见问题

**Q：启动后一分钟内没任何输出？**
A：正常现象，dsh 首次启动需初始化插件树。脚本会自动轮询等待就绪，请勿中途退出。

**Q：浏览器打开显示 401？**
A：dsh 有 token 安全围栏，必须访问带 `?token=...` 的地址。请用菜单「打开 Web UI」或 start.sh 自动打开，不要手动输入裸地址。

**Q：锁屏后服务断了？**
A：脚本已自动启用 wake-lock；仍建议尽量让 Termux 保持前台，并关闭 Termux 的电池优化。

**Q：dsh 启动失败？**
A：菜单选「7. 修复环境」重新安装 Node 与 dsh，或查看「5. 运行日志」。

## 免责声明

本项目为第三方部署脚本，与 DeepSeek 官方无关。DeepSeek Harness 处于 developer preview 阶段，可能存在破坏性变更。请自行评估运行 Agent（含文件与命令工具）的安全风险。

## License

MIT
