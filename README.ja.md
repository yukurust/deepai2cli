# DeepAI Code CLI tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[English](README.md) | 日本語 | [中文](README.zh.md)

DeepAI Code のログイン状態・モデル設定(保存済みアカウント)をそのまま利用して、ターミナルから DeepAI のモデルと Pi coding agent を使うためのツール一式です。APIキーの再入力は不要です。

## インストール

```sh
curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh
```

これだけで完了です。インストーラは必要なコマンドファイルだけを `~/.local/bin`(と `/deepai` コマンドを `~/.config/opencode/command`)にダウンロードします。**リポジトリの取得も git も不要**です。派生パターン:

```sh
URL=https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh
curl -fsSL "$URL" | sh                       # インストール
curl -fsSL "$URL" | sh -s -- --dry-run       # 何をするかだけ表示
curl -fsSL "$URL" | sh -s -- --uninstall     # 配置したファイルを削除
curl -fsSL "$URL" -o install.sh && sh install.sh   # 中身を確認してから実行
```

更新は curl コマンドの再実行です。実行内容を固定したい場合は URL の `main` をタグ/コミットに置き換えてください。インストーラは前提チェックを実施し、**DeepAI Code アプリが未導入の場合はその旨を明確に案内**します。既に別の `pi` が PATH にある場合はその `pi` を残したまま pi 系だけをスキップするので、**opencode のみの利用でも衝突せずに導入できます**。`~/.local/bin` を PATH に含めておいてください(`export PATH="$HOME/.local/bin:$PATH"`)。

## 使い方

`opencode` か `pi` を開く前に `deepai-ready` を一度実行してください(**両方に共通の必須の前段**です)。あとは使いたいコマンドをどうぞ:

| コマンド | やること |
| --- | --- |
| `deepai-ready` | 準備: DeepAI Code が未起動なら起動して API プロキシの応答を待ち、opencode の設定を同期(何も起動しない) |
| `pi` | pi を独立セッションで実行(`pi "指示"` = 1 回実行、`pi --print "…"` = スクリプト向け) |
| `deepai-pi` | `pi` のフレンドリーなラッパー |
| `deepai-opencode` | `deepai-ready` + opencode 起動を1コマンドで |
| `deepai-up` | DeepAI Code の起動とプロキシ待ちだけ(`deepai-ready` の内部部品、単独でも可) |
| `/deepai …` | opencode のコマンド: DeepAI CLI(Pi)を1回実行 |

```sh
deepai-ready && opencode                          # または: deepai-ready && pi
deepai-opencode                                   # 上と同じを1コマンドで
opencode run --model deepai/glm-5.3-flash "…"     # opencode で DeepAI のモデルを選択
orca agent launch --agent pi --prompt "…" --json  # Orca から独立 pi セッションを開く
```

それぞれの内部の仕組みは[仕組み](#仕組み)にまとめています。

## 前提

- macOS(DeepAI Code アプリのパス前提。標準の `curl`・`python3` を使用)
- [opencode](https://opencode.ai) がインストール済み(opencode 側を使う場合)
- DeepAI Code アプリにサインイン済み

## 仕組み

### DeepAI Code のローカルプロキシ

モデルへの呼び出しはすべて DeepAI Code アプリ内のローカル HTTP プロキシを通ります。ログイン状態は `~/.deepai-code/userdata/deepai/pi/deepai/models.json`(`providers.deepai`: `baseUrl` + `apiKey` + `models`)にあり、**アプリの起動(再起動)ごとにプロキシのポートと API キーがローテーション**されます。これが「以前動いていたのに急に `ECONNREFUSED` になる」正体で、ツール類がキャッシュせず毎回 `models.json` を読み直す理由です。

### deepai-ready / deepai-up

`deepai-ready` は準備の唯一の入口で、何も起動しません。`deepai-up`(プロキシが無ければ `open -g -j` でアプリを非表示起動し、`models.json` を読み直しながら応答を待つ=ローテーションに追従)を呼んだうえで、opencode の設定を同期します。`deepai-up` は冪等(起動済みなら即終了)なので、部品同士は干渉せず何度組み合わせても安全で、単独実行もできます。`pi` はこれを意図的に行いません(未準備なら `deepai-ready` を案内して終了)。準備の入口を1つに保つためです。

### opencode の設定同期

同期が変更するのは `~/.config/opencode/opencode.jsonc` の **`providers.deepai` だけ**(モデル一覧と認証情報を `models.json` から取得)。あなたの設定・他プロバイダ・既定モデルはそのまま残るので、`/models` や `--model` で `deepai/…` を選ぶだけです。JSONC のコメントは保持されず、初回変更前にバックアップ `opencode.jsonc.bak` を**1枚だけ**保存します(1回きり・上書きなし・増殖なし)。認証情報は同ファイルのみ(権限 600)。モデル名は DeepAI Code 本体の表示に合わせ、モデルごとの API 差(`gpt-6-astra` の Responses API 等)も自動で吸収します。他プロバイダを一覧から消したい場合は `{ "enabled_providers": ["deepai"] }` を追記してください。

### pi

`pi` は DeepAI Code アプリに同梱された Pi coding agent([pi.dev](https://pi.dev/) と同じエンジン)を、DeepAI Code の保存済みアカウントで動かします。引数は pi CLI にそのまま渡ります(`pi [options] [--] [@files...] [messages...]`)。実行ごとに**独立したセッション**(セッションごとに JSONL ファイル。`--session-id` / `--session` で継続可)。既定はモデル `deepai/mimo-2.6-pro`(`DEEPAI_MODEL` で変更可)、ツール `read,bash,edit,write,grep,find,ls` です。独立セッションでは `DeepAI tools are unavailable` と表示されますが、これはアプリ連携ツール(スレッド・委任)が DeepAI Code のローカル接続を必要とするためで、エージェント自体は通常どおり動作します。

### Orca

Orca は `pi` を TUI エージェントとして認識します(`detectCmd: pi`、プロンプトは argv で渡る)。そのため `orca agent launch --agent pi` で独立した pi セッションが開けます(chat、または `--surface terminal` で CLI 直起動)。ただし pi の起動時モデル指定は Orca が拒否します("Agent pi does not support launch-time model selection")。**Orca からのモデル選択・実行は opencode 経由**を使ってください(`opencode models` の一覧が Orca のモデルピッカーに渡り、`opencode run --model deepai/…` で実行されます)。セッション内切替(`/model deepai/…`)や Orca ターミナルからの `DEEPAI_MODEL=… pi` も可能です。opencode 起動前に `deepai-ready` を実行する自動化を Orca に設定できます。

### /deepai(opencode)

`/deepai <タスク>` は opencode のセッションモデル経由で DeepAI CLI(Pi)を1回実行します。`!deepai-pi` なら opencode のモデルを消費しません。

## トラブルシュート: モデルが出ない・`Model unavailable`

1. `deepai-up --status` — ローカルプロキシは生きているか(無ければ `deepai-ready`)
2. `deepai-ready` — 設定を再同期
3. それでもダメなら `~/.deepai-code/userdata/deepai/pi/deepai/models.json` と `~/.config/opencode/opencode.jsonc` の `baseUrl` が一致しているか確認

## リポジトリ構成

| パス | 役割 |
| --- | --- |
| `pi` | Pi CLI を独立セッションで実行(Orca の `--agent pi` が使う入口) |
| `deepai-pi` | `pi` のフレンドリーなラッパー |
| `deepai-up` | DeepAI Code をバックグラウンド起動し、ローカルプロキシの応答を待つ |
| `deepai-ready` | opencode / pi の前段: DeepAI Code の起動・接続待ち・opencode 設定の同期 |
| `deepai-opencode` | `deepai-ready` + opencode 起動 |
| `install.sh` | 冪等なインストーラ(コマンドを `~/.local/bin` にダウンロード) |
| `opencode/command/deepai.md` | opencode の `/deepai` コマンド定義 |

## ライセンス

[MIT](LICENSE)
