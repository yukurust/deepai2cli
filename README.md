# DeepAI Code CLI Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

English | [日本語](README.ja.md) | [中文](README.zh.md)

Use DeepAI's models and the built-in **Pi coding agent** right from your terminal and [opencode](https://opencode.ai) — reusing your existing DeepAI Code login and saved account settings. **No API key re-entry required.**

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

Re-running the curl command updates the files. To lock the version, replace `main` with a tag or commit in the URL. The installer checks the prerequisites, **tells you when the DeepAI Code app is missing**, and keeps an existing `pi` on your `PATH` (skipping the pi-side commands) so an opencode-only setup installs cleanly. Make sure `~/.local/bin` is on your `PATH` (`export PATH="$HOME/.local/bin:$PATH"`).

## Usage

Run `deepai-ready` before opening `opencode` or `pi` — it is the one preparation step both need. Then use whichever commands you like:

| Command | What it does |
| --- | --- |
| `deepai-ready` | Prepare: start DeepAI Code if needed, wait for its API proxy, sync opencode's config — launches nothing |
| `pi` | Run Pi as an independent session (`pi "prompt"` = one-shot, `pi --print "…"` for scripts) |
| `deepai-pi` | Friendlier wrapper around `pi` |
| `deepai-opencode` | `deepai-ready` + start opencode, in one step |
| `deepai-up` | Only start DeepAI Code and wait for its proxy (used inside `deepai-ready`) |
| `/deepai …` | opencode command: run the DeepAI CLI (Pi) once |

```sh
deepai-ready && opencode                          # or: deepai-ready && pi
deepai-opencode                                   # the same, in one command
opencode run --model deepai/glm-5.3-flash "…"     # pick any DeepAI model in opencode
orca agent launch --agent pi --prompt "…" --json  # open an independent pi session from Orca
```

What each piece does internally is described in [How it works](#how-it-works).

## Requirements

- macOS (the DeepAI Code app path is assumed; the built-in `curl` and `python3` are used)
- [opencode](https://opencode.ai) installed (for the opencode side)
- Signed in to the DeepAI Code app

## How it works

### DeepAI Code's local proxy

Every model call goes through a local HTTP proxy inside the DeepAI Code app. The login state lives in `~/.deepai-code/userdata/deepai/pi/deepai/models.json` (`providers.deepai`: `baseUrl` + `apiKey` + `models`). **Every time the app (re)starts, the proxy port and the API key rotate** — which is why a previously working setup suddenly breaks with `ECONNREFUSED`, and why the tools re-read `models.json` on every run instead of caching it.

### deepai-ready / deepai-up

`deepai-ready` is the single preparation step and launches nothing. It calls `deepai-up` — start the app hidden (`open -g -j`) if the proxy is down, then poll `models.json` until the proxy answers (so it follows the rotation) — and then syncs opencode's config. `deepai-up` is idempotent ("already running" exits immediately), so the pieces compose and never conflict; it is also available standalone. `pi` deliberately does none of this: if the proxy is not ready it exits with `run deepai-ready first`, keeping one single entry point for preparation.

### opencode config sync

The sync updates **only `providers.deepai`** in `~/.config/opencode/opencode.jsonc` (model list + credentials taken from `models.json`). Your settings, other providers and your default model are untouched; pick `deepai/…` models with `/models` or `--model`. JSONC comments are not preserved, and before the first change exactly one backup `opencode.jsonc.bak` is saved (created once, never overwritten — no backups accumulate). Credentials live only in that file (permissions 600). Model names mirror the DeepAI Code app (e.g. `mimo-2.6-pro`, `claude-opus-5-5`, `glm-5.3-flash`, `deepseek-v4.1-flash`, `gpt-6.1-sol`, `kimi-k3`), and per-model API quirks (like `gpt-6-astra`'s Responses API) are mapped automatically. To hide other providers from the picker, add `{ "enabled_providers": ["deepai"] }`.

### pi

`pi` runs the Pi coding agent bundled inside the DeepAI Code app — the same engine as [pi.dev](https://pi.dev/) — with DeepAI Code's saved account. Arguments pass straight through to the Pi CLI (`pi [options] [--] [@files...] [messages...]`). Each invocation is its own **independent session** (one JSONL file per session; `--session-id` / `--session` continue an existing one). Defaults: model `deepai/mimo-2.6-pro` (`DEEPAI_MODEL` overrides), tools `read,bash,edit,write,grep,find,ls`. Standalone sessions print `DeepAI tools are unavailable` — those app-level tools (threads, delegation) need the DeepAI Code app's local connection; the agent itself works normally.

### Orca

Orca knows `pi` as a TUI agent (`detectCmd: pi`, prompt passed via argv), so `orca agent launch --agent pi` opens an independent pi session (a chat, or `--surface terminal` to run the CLI). Launch-time model selection for pi is refused by Orca ("Agent pi does not support launch-time model selection") — **use opencode for model selection from Orca** (`opencode models` feeds Orca's model picker; `opencode run --model deepai/…` runs them), or switch inside the session (`/model deepai/…`) / start with `DEEPAI_MODEL=… pi` from an Orca terminal. Wire `deepai-ready` into an Orca automation to run before opencode launches.

### /deepai (opencode)

`/deepai <task>` runs the DeepAI CLI (Pi) once through opencode's session model; `!deepai-pi` runs it without involving opencode's model.

## Troubleshooting: models missing or `Model unavailable`

1. `deepai-up --status` — is the local proxy alive? (run `deepai-ready` if not)
2. `deepai-ready` — re-sync the config
3. Still broken: check that `baseUrl` matches between `~/.deepai-code/userdata/deepai/pi/deepai/models.json` and `~/.config/opencode/opencode.jsonc`

## Repository layout

| Path | Role |
| --- | --- |
| `pi` | Runs the Pi CLI as an independent session (the entry point Orca's `--agent pi` uses) |
| `deepai-pi` | Friendlier wrapper around `pi` |
| `deepai-up` | Starts DeepAI Code in the background and waits for its local proxy |
| `deepai-ready` | Pre-flight before opencode/pi: start DeepAI Code, wait for the proxy, sync opencode's config |
| `deepai-opencode` | `deepai-ready` + start opencode |
| `install.sh` | Idempotent installer (downloads the commands into `~/.local/bin`) |
| `opencode/command/deepai.md` | opencode `/deepai` command definition |

## License

[MIT](LICENSE)
