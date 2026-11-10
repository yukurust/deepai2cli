# DeepAI Code CLI Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

English | [日本語](README.ja.md) | [中文](README.zh.md)

Use DeepAI's models and the built-in **Pi coding agent** right from your terminal and [opencode](https://opencode.ai) — reusing your existing DeepAI Code login and saved account settings. **No API key re-entry required.**

## What you get

- **Run DeepAI Code's built-in Pi coding agent from the terminal** (`deepai-pi`, interactive / one-shot)
- **Use DeepAI models inside opencode** (the model list is generated automatically from DeepAI Code's settings)
- **Start DeepAI Code in the background** (`deepai-up`; waits for the API proxy and auto-starts the app when needed)
- **Refresh opencode's config without launching** (`opencode-deepai-launch --prepare`; plain `opencode` works afterwards)
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

### Run pi as an independent session

```sh
pi                          # interactive; a fresh independent session per launch
pi "Investigate this repo"  # start with an initial prompt
pi --print "Summarize …"    # one-shot
```

`pi` is the engine behind `deepai-pi`. Arguments pass straight through to the Pi CLI (`pi [options] [--] [@files...] [messages...]`). Defaults: model `deepai/mimo-2.6-pro` (`DEEPAI_MODEL` overrides), a fresh independent session per invocation (`--session-id` / `--session` continue an existing one), and the tools `read,bash,edit,write,grep,find,ls`.

### Connect to pi from Orca

Orca knows `pi` as an agent (`detectCmd: pi`, prompt passed via argv), so with `pi` on your `PATH`:

```sh
orca agent launch --agent pi --prompt "…" --json        # chat session (--surface terminal runs the CLI)
orca terminal wait --for tui-idle --timeout-ms 600000   # wait for the agent CLI to go idle
orca terminal read --terminal <handle> --json           # read the output
```

Orca refuses launch-time model selection for pi (`orca agent launch --agent pi --model …` → "Agent pi does not support launch-time model selection"), and this stays as-is by design: **use opencode for model selection and execution from Orca**. `opencode models` feeds Orca's model picker with the DeepAI models, and `opencode run --model deepai/…` runs them. pi sessions run with their configured model; switch inside the session with `/model deepai/glm-5.3-flash`, or start one with `DEEPAI_MODEL=glm-5.3-flash pi` from an Orca terminal.

Each launch is its own independent pi session. Standalone sessions print `DeepAI tools are unavailable` — those app-level tools need the DeepAI Code app's local connection; the agent itself works normally.

### Start opencode from pi (or anywhere)

```sh
deepai-opencode            # sync config, then start opencode
deepai-opencode run "…"    # arguments pass through to opencode
```

### Start DeepAI Code in the background

```sh
deepai-up              # if not running, start it hidden and wait for the API proxy
deepai-up --status     # check status only (exit 0 when ready)
```

DeepAI Code's local proxy **changes its port and API key every time the app starts**. `deepai-up` re-reads `models.json` on every attempt, so it follows the rotation.

### Keep opencode's config in sync with DeepAI Code

```sh
opencode-deepai-launch --prepare   # refresh config only; plain `opencode` works afterwards
opencode-deepai-launch             # refresh config and launch opencode
```

When you update your DeepAI Code account or model settings (`models.json`), **or after restarting DeepAI Code**, run this once to sync the DeepAI section of `~/.config/opencode/opencode.jsonc` (model list and credentials). `--prepare` also starts DeepAI Code in the background when needed and exits without launching opencode — after it finishes, plain `opencode` can be used anytime.

#### Pairing with Orca automations

Configure Orca to run `opencode-deepai-launch --prepare` right before launching opencode, and opencode always starts with a working DeepAI provider (even right after DeepAI Code restarts):

```sh
opencode-deepai-launch --prepare && exec opencode "$@"   # e.g. inside a wrapper
```

### Troubleshooting: models missing or `Model unavailable`

1. `deepai-up --status` — is the local proxy alive? (run `deepai-up` if not)
2. `opencode-deepai-launch --prepare` — re-sync the config
3. Still broken: check that `baseUrl` matches between `~/.deepai-code/userdata/deepai/pi/deepai/models.json` and `~/.config/opencode/opencode.jsonc`

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh
```

That is the whole install: the installer downloads just the command files into `~/.local/bin` (and the `/deepai` command into `~/.config/opencode/command`) — **no repository checkout, no git**. Variants:

```sh
URL=https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh
curl -fsSL "$URL" | sh                       # install
curl -fsSL "$URL" | sh -s -- --dry-run       # show what it would do first
curl -fsSL "$URL" | sh -s -- --uninstall     # remove the installed files
curl -fsSL "$URL" -o install.sh && sh install.sh   # inspect the script before running
```

Re-running the curl command updates the files. To lock the version, replace `main` with a tag or commit in the URL. The installer checks the prerequisites and refuses to run when a different `pi` command is already on your `PATH`. Make sure `~/.local/bin` is on your `PATH` (`export PATH="$HOME/.local/bin:$PATH"`).

Credentials are stored only in `~/.config/opencode/opencode.jsonc`, with file permissions set to 600. `opencode-deepai-launch` imports the model list and credentials from DeepAI Code's settings, sets the default model to `deepai/mimo-2.6-pro`, and launches opencode.

## Requirements

- macOS (the DeepAI Code app path is assumed; the built-in `curl` and `python3` are used)
- [opencode](https://opencode.ai) installed
- Signed in to the DeepAI Code app (responses go through its local proxy; if the app is not running, `deepai-up` / `opencode-deepai-launch` start it in the background)
- Restarting DeepAI Code rotates the local proxy's port and API key and invalidates generated config — run `opencode-deepai-launch --prepare` before using opencode again
- If models don't show up, see "Troubleshooting" above

## Repository layout

| Path | Role |
| --- | --- |
| `pi` | Runs the Pi CLI as an independent session (the entry point Orca's `--agent pi` uses) |
| `deepai-pi` | Friendlier wrapper around `pi` (interactive / one-shot) |
| `deepai-up` | Starts DeepAI Code in the background and waits for its local proxy |
| `deepai-opencode` | Syncs config, then starts opencode |
| `opencode-deepai-launch` | Generates opencode's config from DeepAI Code's settings and launches it (`--prepare` refreshes config only) |
| `install.sh` | Idempotent installer (downloads the commands into `~/.local/bin`; no checkout needed) |
| `opencode/command/deepai.md` | opencode `/deepai` command definition |

## License

[MIT](LICENSE)
