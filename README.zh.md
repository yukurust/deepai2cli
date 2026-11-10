# DeepAI Code CLI 工具集

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md) | [日本語](README.ja.md) | 中文

直接在终端和 [opencode](https://opencode.ai) 中使用 DeepAI 的模型以及内置的 **Pi coding agent**——沿用你已有的 DeepAI Code 登录状态和已保存的账号设置。**无需重新输入 API key。**

## 安装

```sh
curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh
```

安装到此结束:安装脚本只把命令文件下载到 `~/.local/bin`(以及把 `/deepai` 命令下载到 `~/.config/opencode/command`)——**不需要克隆仓库,也不需要 git**。变体:

```sh
URL=https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh
curl -fsSL "$URL" | sh                       # 安装
curl -fsSL "$URL" | sh -s -- --dry-run       # 只显示将要执行的操作
curl -fsSL "$URL" | sh -s -- --uninstall     # 删除已安装的文件
curl -fsSL "$URL" -o install.sh && sh install.sh   # 先检查脚本再执行
```

更新只需重新执行 curl 命令。想固定版本,把 URL 中的 `main` 换成 tag/commit。安装脚本会检查各项前提,**并在 DeepAI Code 应用缺失时明确告知**。如果 `PATH` 上已存在另一个 `pi`,会保留它并只跳过 pi 侧的命令——因此**只用 opencode 的场景也能无冲突安装**。请确保 `~/.local/bin` 在 `PATH` 中(`export PATH="$HOME/.local/bin:$PATH"`)。

## 用法

打开 `opencode` 或 `pi` 之前先执行一次 `deepai-ready`(**两者共用的必经前段**)。然后按需使用:

| 命令 | 作用 |
| --- | --- |
| `deepai-ready` | 准备:DeepAI Code 未启动则启动并等待其 API 代理,同步 opencode 配置(不启动任何东西) |
| `pi` | 以独立会话运行 Pi(`pi "指示"` = 执行一次,`pi --print "…"` = 脚本用) |
| `deepai-pi` | `pi` 的友好包装 |
| `deepai-opencode` | `deepai-ready` + 启动 opencode,一步完成 |
| `deepai-up` | 只负责启动 DeepAI Code 并等待代理(`deepai-ready` 的内部组件,也可单独用) |
| `/deepai …` | opencode 命令:执行一次 DeepAI CLI(Pi) |

```sh
deepai-ready && opencode                          # 或者:deepai-ready && pi
deepai-opencode                                   # 同上,一条命令
opencode run --model deepai/glm-5.3-flash "…"     # 在 opencode 中选用 DeepAI 的模型
orca agent launch --agent pi --prompt "…" --json  # 从 Orca 打开独立的 pi 会话
```

各部分的内部原理见[工作原理](#工作原理)。

## 前提条件

- macOS(依赖 DeepAI Code 应用的路径;使用系统自带的 `curl` 和 `python3`)
- 已安装 [opencode](https://opencode.ai)(使用 opencode 侧时)
- 已登录 DeepAI Code 应用

## 工作原理

### DeepAI Code 的本地代理

所有模型调用都经过 DeepAI Code 应用内的本地 HTTP 代理。登录状态保存在 `~/.deepai-code/userdata/deepai/pi/deepai/models.json`(`providers.deepai`:`baseUrl` + `apiKey` + `models`),并且**应用每次(重)启动都会轮换代理端口和 API key**。这就是"以前能用却突然 `ECONNREFUSED`"的原因,也是各工具不缓存、每次重新读取 `models.json` 的原因。

### deepai-ready / deepai-up

`deepai-ready` 是唯一的准备入口,且不启动任何东西。它调用 `deepai-up`(代理不通时用 `open -g -j` 隐藏启动应用,并边重读 `models.json` 边等待代理响应——自动跟随轮换),然后同步 opencode 配置。`deepai-up` 是幂等的("已启动"立即退出),因此各组件可以任意组合、互不干扰,也可单独运行。`pi` 刻意不做这些:未准备好时提示运行 `deepai-ready` 后退出,以保持准备入口唯一。

### opencode 配置同步

同步只更新 `~/.config/opencode/opencode.jsonc` 中的 **`providers.deepai`**(从 `models.json` 取模型列表和认证信息)。你的设置、其他提供商、默认模型都保持不变,只需用 `/models` 或 `--model` 选择 `deepai/…`。JSONC 注释不会保留;首次修改前会保存一份备份 `opencode.jsonc.bak`(**只此一份**,不覆盖也不增多)。认证信息仅存于该文件(权限 600)。模型名称与 DeepAI Code 应用一致,模型级 API 差异(如 `gpt-6-astra` 的 Responses API)也会自动适配。想在列表中隐藏其他提供商,添加 `{ "enabled_providers": ["deepai"] }`。

### pi

`pi` 运行 DeepAI Code 应用内置的 Pi coding agent(与 [pi.dev](https://pi.dev/) 同一引擎),使用 DeepAI Code 的已保存账号。参数原样传给 pi CLI(`pi [options] [--] [@files...] [messages...]`)。每次运行都是**独立会话**(每个会话一个 JSONL 文件;`--session-id` / `--session` 可继续)。默认:模型 `deepai/mimo-2.6-pro`(可用 `DEEPAI_MODEL` 覆盖),工具 `read,bash,edit,write,grep,find,ls`。独立会话会提示 `DeepAI tools are unavailable`——那些应用级工具(线程、委派)需要 DeepAI Code 的本地连接,代理本身不受影响。

### Orca

Orca 把 `pi` 识别为 TUI 代理(`detectCmd: pi`,提示词经 argv 传入),所以 `orca agent launch --agent pi` 会打开独立的 pi 会话(chat,或 `--surface terminal` 直接运行 CLI)。但 pi 的启动时模型选择会被 Orca 拒绝("Agent pi does not support launch-time model selection")。**从 Orca 进行模型选择和执行请走 opencode**(`opencode models` 的列表会进入 Orca 的模型选择器,`opencode run --model deepai/…` 执行)。也可以会话内 `/model deepai/…` 切换,或在 Orca 终端用 `DEEPAI_MODEL=… pi` 启动。可在 Orca 自动化中配置为启动 opencode 前先运行 `deepai-ready`。

### /deepai(opencode)

`/deepai <任务>` 通过 opencode 的会话模型执行一次 DeepAI CLI(Pi);`!deepai-pi` 则不消耗 opencode 的模型。

## 排查:模型缺失或 `Model unavailable`

1. `deepai-up --status` —— 本地代理是否存活?(没有就执行 `deepai-ready`)
2. `deepai-ready` —— 重新同步配置
3. 仍然不行:检查 `~/.deepai-code/userdata/deepai/pi/deepai/models.json` 和 `~/.config/opencode/opencode.jsonc` 的 `baseUrl` 是否一致

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `pi` | 以独立会话运行 Pi CLI(Orca 的 `--agent pi` 使用的入口) |
| `deepai-pi` | `pi` 的友好包装 |
| `deepai-up` | 在后台启动 DeepAI Code 并等待其本地代理就绪 |
| `deepai-ready` | opencode / pi 的前段:启动 DeepAI Code、等待代理、同步 opencode 配置 |
| `deepai-opencode` | `deepai-ready` + 启动 opencode |
| `install.sh` | 幂等安装脚本(把命令下载到 `~/.local/bin`) |
| `opencode/command/deepai.md` | opencode 的 `/deepai` 命令定义 |

## 许可证

[MIT](LICENSE)
