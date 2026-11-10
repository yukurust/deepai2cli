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

更新只需重新执行 curl 命令。想固定版本,把 URL 中的 `main` 换成 tag/commit。安装脚本会检查各项前提,**并在 DeepAI Code 应用缺失时明确告知**(pi 和 DeepAI 模型都需要它;请先安装并登录,再执行 `opencode-deepai-launch --prepare`)。如果 `PATH` 上已存在另一个 `pi`,会保留它并只跳过 pi 侧的命令(`pi` / `deepai-pi` / `/deepai`)——因此**只用 opencode 的场景可以与已有的 pi 共存安装**。请确保 `~/.local/bin` 在 `PATH` 中(`export PATH="$HOME/.local/bin:$PATH"`)。

## 用法

### 在终端运行 DeepAI CLI(Pi)

```sh
deepai-pi                                            # 开始交互式会话
deepai-pi "调查一下这个项目的结构"                     # 附带初始指令开始
deepai-pi --print -- "用一句话总结"                    # 单次非交互式执行
deepai-pi --model glm-5.3-flash --print -- "…"        # 指定模型
```

| 选项 | 说明 |
| --- | --- |
| `-p, --print` | 非交互模式。处理完提示词后退出 |
| `-m, --model <id>` | DeepAI 的模型 ID(默认:`mimo-2.6-pro`) |
| `--session-id <id>` | 指定会话 ID(默认:每次运行新建) |
| `-h, --help` | 显示帮助 |

### 在 opencode 中使用 DeepAI 的模型

DeepAI 的模型会出现在 opencode 的模型切换(`/models`)列表中。

| 操作 | 方法 |
| --- | --- |
| 对话中切换 | 打开 `/models` 并选择 `deepai/…` |
| 启动时指定 | `opencode run --model deepai/glm-5.3-flash "…"` |
| 查看列表 | `opencode models` |

模型列表从 DeepAI Code 的设置(`models.json`)自动导入。DeepAI Code 新增模型后,重新运行 `opencode-deepai-launch` 即可同步。默认模型是 `deepai/mimo-2.6-pro`。模型名称与 DeepAI Code 应用中的显示保持一致(例如 `deepseek-v4.1-flash` 显示为「DeepSeek V4.1 Flash 1017」)。按模型使用 Responses API 的模型(`gpt-6-astra`)会单独覆盖该模型的 provider package。

主要模型:`mimo-2.6-pro`(默认)/ `claude-opus-5-5` / `claude-fable-5-2` / `glm-5.3-flash` / `deepseek-v4.1-flash` / `qwen-3.8-flash` / `qwen-3.8-max-prime` / `minimax-m3` / `gemini-4-argon` / `gpt-6.1-sol` / `kimi-k3` 等。

如果想把模型列表限定为只有 DeepAI,在 `~/.config/opencode/opencode.jsonc` 中添加以下内容(其他提供商的模型将不再出现在列表中,即使指定也会报 `Model unavailable`):

```json
{ "enabled_providers": ["deepai"] }
```

### 在 opencode 内运行 DeepAI CLI(Pi)

```sh
/deepai 调查一下这个项目的结构并给出改进方案    # opencode 命令
!deepai-pi --print -- "用一句话总结"           # opencode 的 shell 执行(不消耗模型)
```

`/deepai` 会通过 opencode 的会话模型来启动 CLI。如果不想消耗模型,请使用 `!deepai-pi`。

### 以独立会话运行 pi

```sh
pi                          # 交互式;每次启动都是独立的新会话
pi "调查一下这个项目"         # 附带初始指令开始
pi --print "用一句话总结"     # 单次非交互式执行
```

`pi` 是 `deepai-pi` 的本体,参数原样传给 pi CLI(`pi [options] [--] [@files...] [messages...]`)。默认:模型 `deepai/mimo-2.6-pro`(可用 `DEEPAI_MODEL` 覆盖)、每次运行独立会话(`--session-id` / `--session` 可继续既有会话)、工具 `read,bash,edit,write,grep,find,ls`。

### 从 Orca 连接 pi

Orca 把 `pi` 识别为一种代理(`detectCmd: pi`,提示词通过 argv 传入)。只要 `pi` 在 `PATH` 上:

```sh
orca agent launch --agent pi --prompt "…" --json        # 聊天会话(--surface terminal 则直接运行 CLI)
orca terminal wait --for tui-idle --timeout-ms 600000   # 等待代理 CLI 空闲
orca terminal read --terminal <handle> --json           # 读取输出
```

pi 的启动时模型选择在 Orca 侧保持未接入(`orca agent launch --agent pi --model …` 会以 "Agent pi does not support launch-time model selection" 拒绝),这是既定安排。**从 Orca 进行模型选择和执行请走 opencode**(`opencode models` 的列表会进入 Orca 的模型选择器,用 `opencode run --model deepai/…` 执行)。pi 会话使用其配置的模型;切换用会话内 `/model deepai/glm-5.3-flash`,或在 Orca 终端用 `DEEPAI_MODEL=glm-5.3-flash pi` 启动。

每次启动都是独立的 pi 会话。独立运行的 pi 会提示 `DeepAI tools are unavailable`——那些应用级工具(线程、委派)需要 DeepAI Code 的本地连接,代理本身不受影响。

### 从 pi(或任何地方)启动 opencode

```sh
deepai-opencode            # 同步配置后启动 opencode
deepai-opencode run "…"    # 参数全部透传给 opencode
```

### 在后台启动 DeepAI Code

```sh
deepai-up              # 未启动则隐藏启动,并等待 API 代理就绪
deepai-up --status     # 只检查状态(就绪时 exit 0)
```

DeepAI Code 的本地代理**每次应用启动都会更换端口和 API key**。`deepai-up` 每次都会重新读取 `models.json`,因此能跟随轮换。

### 让 opencode 的设置跟随 DeepAI Code

```sh
opencode-deepai-launch --prepare   # 只更新配置,之后可直接使用普通的 `opencode`
opencode-deepai-launch             # 更新配置并启动 opencode
```

更新了 DeepAI Code 的账号或模型设置(`models.json`),或者**重启 DeepAI Code 之后**,运行一次该命令,即可把 `~/.config/opencode/opencode.jsonc` 中的 DeepAI 设置(模型列表和认证信息)同步为最新。`--prepare` 在 DeepAI Code 未启动时会先在后台启动它,然后退出而不启动 opencode——之后随时可以直接用普通的 `opencode`。文件中的其他设置、其他提供商和默认模型都会保持不变(JSONC 注释不会保留)。备份只保留工具引入前的一份 `opencode.jsonc.bak`(只创建一次,不覆盖也不增多)。认证信息仅保存在 `~/.config/opencode/opencode.jsonc`(权限 600)。

#### 与 Orca 自动化配合

在 Orca 中配置为启动 opencode 之前执行 `opencode-deepai-launch --prepare`,这样即使 DeepAI Code 刚重启过,opencode 也能在 DeepAI 提供商可用的状态下启动:

```sh
opencode-deepai-launch --prepare && exec opencode "$@"   # 例:包装脚本的内容
```

### 排查:模型缺失或 `Model unavailable`

1. `deepai-up --status` —— 本地代理是否存活?(没有就执行 `deepai-up`)
2. `opencode-deepai-launch --prepare` —— 重新同步配置
3. 仍然不行:检查 `~/.deepai-code/userdata/deepai/pi/deepai/models.json` 和 `~/.config/opencode/opencode.jsonc` 的 `baseUrl` 是否一致

## 功能

- **在终端运行 DeepAI Code 内置的 Pi coding agent**(`deepai-pi`,支持交互式 / 单次执行)
- **在 opencode 中选择 DeepAI 的模型运行**(模型列表从 DeepAI Code 的设置自动生成)
- **在后台启动 DeepAI Code**(`deepai-up`,等待 API 代理就绪,未启动时自动拉起)
- **只更新 opencode 的配置**(`opencode-deepai-launch --prepare`,之后普通的 `opencode` 即可使用)
- 通过 opencode 的 `/deepai` 命令执行一次 DeepAI CLI(Pi)
- 每次会话都会生成独立的 Pi 会话 ID

## 前提条件

- macOS(依赖 DeepAI Code 应用的路径;使用系统自带的 `curl` 和 `python3`)
- 已安装 [opencode](https://opencode.ai)
- 已登录 DeepAI Code 应用(响应经由 DeepAI Code 的本地代理;未启动时 `deepai-up` / `opencode-deepai-launch` 会尝试在后台启动它)
- 注意:重启 DeepAI Code 会轮换本地代理的端口和 API key,使已生成的配置失效——再次使用 opencode 前请执行 `opencode-deepai-launch --prepare`
- 如果模型无法选择,请参考上文的「排查」一节

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `pi` | 以独立会话运行 Pi CLI(Orca 的 `--agent pi` 使用的入口) |
| `deepai-pi` | `pi` 的友好包装(交互式 / 单次执行) |
| `deepai-up` | 在后台启动 DeepAI Code 并等待其本地代理就绪 |
| `deepai-opencode` | 同步配置后启动 opencode |
| `opencode-deepai-launch` | 从 DeepAI Code 的设置生成 opencode 配置并启动(`--prepare` 只更新配置) |
| `install.sh` | 幂等安装脚本(把命令下载到 `~/.local/bin`;无需克隆仓库) |
| `opencode/command/deepai.md` | opencode 的 `/deepai` 命令定义 |

## 许可证

[MIT](LICENSE)
