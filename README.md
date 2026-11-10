# DeepAI Code CLI Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

English | [日本語](README.ja.md) | [中文](README.zh.md)

Use DeepAI's models and the built-in **Pi coding agent** right from your terminal and [opencode](https://opencode.ai) — reusing your existing DeepAI Code login and saved account settings. **No API key re-entry required.**

## What you get

- **Run DeepAI Code's built-in Pi coding agent from the terminal** (`deepai-pi`, interactive / one-shot)
- **Use DeepAI models inside opencode** (the model list is generated automatically from DeepAI Code's settings)
- A `/deepai` command in opencode to run the DeepAI CLI (Pi) once
- A fresh, independent Pi session ID per conversation

## Usage

### Run the DeepAI CLI (Pi) from the terminal

```sh
deepai-pi                                            # start an interactive session
deepai-pi "Investigate this project's structure"     # start with an initial prompt
deepai-pi --print -- "Summarize in one sentence"     # one-shot, non-interactive
deepai-pi --model glm-5.3-flash --print -- "…"       # pick a specific model
```

| Option | Description |
| --- | --- |
| `-p, --print` | Non-interactive mode. Processes the prompt and exits |
| `-m, --model <id>` | DeepAI model ID (default: `mimo-2.6-pro`) |
| `--session-id <id>` | Set the session ID (default: a new one per run) |
| `-h, --help` | Show help |

### Use DeepAI models inside opencode

DeepAI models show up in opencode's model picker (`/models`).

| How | What to do |
| --- | --- |
| Switch mid-session | Open `/models` and pick `deepai/…` |
| Choose at launch | `opencode run --model deepai/glm-5.3-flash "…"` |
| List models | `opencode models` |

The model list is imported automatically from DeepAI Code's settings (`models.json`). When DeepAI Code adds a model, re-running `opencode-deepai-launch` picks it up. The default model is `deepai/mimo-2.6-pro`. Model names match what the DeepAI Code app displays (e.g. `deepseek-v4.1-flash` shows as "DeepSeek V4.1 Flash 1017"). Models that use the Responses API per model (`gpt-6-astra`) get their provider package overridden individually.

Main models: `mimo-2.6-pro` (default) / `claude-opus-5-5` / `claude-fable-5-2` / `glm-5.3-flash` / `deepseek-v4.1-flash` / `qwen-3.8-flash` / `qwen-3.8-max-prime` / `minimax-m3` / `gemini-4-argon` / `gpt-6.1-sol` / `kimi-k3`, and more.

To show only DeepAI models in the picker, add this to `~/.config/opencode/opencode.jsonc` (other providers' models will disappear from the list, and specifying them will fail with `Model unavailable`):

```json
{ "enabled_providers": ["deepai"] }
```

### Run the DeepAI CLI (Pi) from within opencode

```sh
/deepai Investigate this project's structure and suggest improvements   # opencode command
!deepai-pi --print -- "Summarize in one sentence"                       # opencode shell (no model used)
```

`/deepai` launches the CLI through opencode's session model. If you don't want to consume model tokens, use `!deepai-pi` instead.

### Keep opencode's config in sync with DeepAI Code

```sh
opencode-deepai-launch    # updates the model list and credentials at startup
```

When you update your DeepAI Code account or model settings (`models.json`), run this once to sync the DeepAI section of `~/.config/opencode/opencode.jsonc` (model list and credentials).

## Setup

```sh
mkdir -p ~/.local/bin ~/.config/opencode/command
ln -sf "$PWD/deepai-pi" ~/.local/bin/deepai-pi
ln -sf "$PWD/opencode/command/deepai.md" ~/.config/opencode/command/deepai.md
opencode-deepai-launch   # adds the DeepAI provider to ~/.config/opencode/opencode.jsonc
```

Make sure `~/.local/bin` is on your `PATH` (`export PATH="$HOME/.local/bin:$PATH"`).

Credentials are stored only in `~/.config/opencode/opencode.jsonc`, with file permissions set to 600. `opencode-deepai-launch` imports the model list and credentials from DeepAI Code's settings, sets the default model to `deepai/mimo-2.6-pro`, and launches opencode.

## Requirements

- macOS (the DeepAI Code app path is assumed)
- [opencode](https://opencode.ai) installed
- DeepAI Code app running and signed in (responses go through DeepAI Code's local proxy)
- If models don't show up, check `~/.deepai-code/userdata/deepai/pi/deepai/models.json` and `~/.config/opencode/opencode.jsonc`

## Repository layout

| Path | Role |
| --- | --- |
| `deepai-pi` | Wrapper that runs the Pi CLI built into DeepAI Code (interactive / one-shot) |
| `opencode-deepai-launch` | Generates opencode's config from DeepAI Code's settings and launches it |
| `opencode/command/deepai.md` | opencode `/deepai` command definition |

## License

[MIT](LICENSE)
