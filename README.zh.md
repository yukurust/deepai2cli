# DeepAI Code CLI 工具集

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md) | [日本語](README.ja.md) | 中文

直接在终端和 [opencode](https://opencode.ai) 中使用 DeepAI 的模型以及内置的 **Pi coding agent**——沿用你已有的 DeepAI Code 登录状态和已保存的账号设置。**无需重新输入 API key。**

## 功能

- **在终端运行 DeepAI Code 内置的 Pi coding agent**(`deepai-pi`,支持交互式 / 单次执行)
- **在 opencode 中选择 DeepAI 的模型运行**(模型列表从 DeepAI Code 的设置自动生成)
- 通过 opencode 的 `/deepai` 命令执行一次 DeepAI CLI(Pi)
- 每次会话都会生成独立的 Pi 会话 ID

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

### 让 opencode 的设置跟随 DeepAI Code

```sh
opencode-deepai-launch    # 启动时同步最新的模型列表和认证信息
```

更新了 DeepAI Code 的账号或模型设置(`models.json`)后,运行一次该命令,即可把 `~/.config/opencode/opencode.jsonc` 中的 DeepAI 设置(模型列表和认证信息)同步为最新。

## 安装(复现步骤)

```sh
mkdir -p ~/.local/bin ~/.config/opencode/command
ln -sf "$PWD/deepai-pi" ~/.local/bin/deepai-pi
ln -sf "$PWD/opencode/command/deepai.md" ~/.config/opencode/command/deepai.md
opencode-deepai-launch   # 向 ~/.config/opencode/opencode.jsonc 添加 DeepAI 提供商
```

请确保 `~/.local/bin` 已加入 `PATH`(`export PATH="$HOME/.local/bin:$PATH"`)。

认证信息仅保存在 `~/.config/opencode/opencode.jsonc` 中,文件权限设为 600。`opencode-deepai-launch` 会从 DeepAI Code 的设置中导入模型列表和认证信息,将默认模型设为 `deepai/mimo-2.6-pro` 并启动 opencode。

## 前提条件

- macOS(依赖 DeepAI Code 应用的路径)
- 已安装 [opencode](https://opencode.ai)
- DeepAI Code 应用已启动并登录(响应经由 DeepAI Code 的本地代理)
- 如果模型无法选择,请检查 `~/.deepai-code/userdata/deepai/pi/deepai/models.json` 和 `~/.config/opencode/opencode.jsonc`

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `deepai-pi` | 运行 DeepAI Code 内置 Pi CLI 的包装脚本(交互式 / 单次执行) |
| `opencode-deepai-launch` | 从 DeepAI Code 的设置生成 opencode 配置并启动 |
| `opencode/command/deepai.md` | opencode 的 `/deepai` 命令定义 |

## 许可证

[MIT](LICENSE)
