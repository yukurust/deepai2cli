# DeepAI Code CLI tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

DeepAI Code のログイン状態・モデル設定(保存済みアカウント)をそのまま利用して、ターミナルから DeepAI のモデルと Pi coding agent を使うためのツール一式です。APIキーの再入力は不要です。

## できること

- **ターミナルから DeepAI Code 内蔵の Pi coding agent を実行**(`deepai-pi`、対話 / 非対話)
- **opencode のモデルとして DeepAI のモデルを選択して実行**(モデル一覧は DeepAI Code の設定から自動生成)
- opencode の `/deepai` コマンドで DeepAI CLI(Pi)を 1 回実行
- 会話ごとに独立した Pi セッション ID を作成

## 使い方

### ターミナルから DeepAI CLI(Pi)を実行する

```sh
deepai-pi                                            # 対話セッションを開始
deepai-pi "このプロジェクトの構成を調べて"            # 最初の指示を付けて開始
deepai-pi --print -- "一文で要約して"                 # 非対話で 1 回実行
deepai-pi --model glm-5.3-flash --print -- "…"       # モデル指定
```

| オプション | 説明 |
| --- | --- |
| `-p, --print` | 非対話モード。プロンプトを処理して終了する |
| `-m, --model <id>` | DeepAI のモデル ID(既定: `mimo-2.6-pro`) |
| `--session-id <id>` | セッション ID を指定する(既定: 実行ごとに新規発行) |
| `-h, --help` | ヘルプを表示 |

### opencode 内で DeepAI のモデルを選択する

opencode のモデル切替(`/models`)に DeepAI のモデルが出ます。

| 操作 | 方法 |
| --- | --- |
| 対話中に切替 | `/models` を開いて `deepai/…` を選択 |
| 起動時に指定 | `opencode run --model deepai/glm-5.3-flash "…"` |
| 一覧確認 | `opencode models` |

モデル一覧は DeepAI Code の設定(`models.json`)から自動で取り込まれ、DeepAI Code にモデルが追加されると `opencode-deepai-launch` の再実行で増えます。既定モデルは `deepai/mimo-2.6-pro` です。モデル名は DeepAI Code 本体の表示に合わせます(例: `deepseek-v4.1-flash` は「DeepSeek V4.1 Flash 1017」)。モデル単位で Responses API を使うもの(`gpt-6-astra`)は、そのモデルだけ provider package を上書きします。

主なモデル: `mimo-2.6-pro`(既定) / `claude-opus-5-5` / `claude-fable-5-2` / `glm-5.3-flash` / `deepseek-v4.1-flash` / `qwen-3.8-flash` / `qwen-3.8-max-prime` / `minimax-m3` / `gemini-4-argon` / `gpt-6.1-sol` / `kimi-k3` など。

モデル一覧を DeepAI だけに絞りたい場合は、`~/.config/opencode/opencode.jsonc` に次を追記します(他のプロバイダのモデルが一覧に出なくなり、指定しても `Model unavailable` になります)。

```json
{ "enabled_providers": ["deepai"] }
```

### DeepAI CLI(Pi)を opencode から実行する

```sh
/deepai このプロジェクトの構成を調べて改善案を出して   # opencode のコマンド
!deepai-pi --print -- "一文で要約して"                # opencode のシェル実行(モデル不使用)
```

`/deepai` は opencode のセッションモデルを経由して CLI を起動します。モデルを実行したくない場合は `!deepai-pi` を使ってください。

### opencode の設定を DeepAI Code に追従させる

```sh
opencode-deepai-launch    # 起動と同時に、最新のモデル一覧・認証情報で設定を更新
```

DeepAI Code のアカウントやモデル設定(`models.json`)を更新したときは、このコマンドを一度実行すると `~/.config/opencode/opencode.jsonc` の DeepAI 設定(モデル一覧・認証情報)に反映されます。

## セットアップ(再現手順)

```sh
mkdir -p ~/.local/bin ~/.config/opencode/command
ln -sf "$PWD/deepai-pi" ~/.local/bin/deepai-pi
ln -sf "$PWD/opencode/command/deepai.md" ~/.config/opencode/command/deepai.md
opencode-deepai-launch   # ~/.config/opencode/opencode.jsonc に DeepAI プロバイダを追加
```

`~/.local/bin` を PATH に含めておいてください(`export PATH="$HOME/.local/bin:$PATH"`)。

認証情報は `~/.config/opencode/opencode.jsonc` に保持し、ファイルの権限は 600 にしています。`opencode-deepai-launch` は DeepAI Code の設定からモデル一覧と認証を取り込み、既定モデルを `deepai/mimo-2.6-pro` にして起動します。

## 前提

- macOS(DeepAI Code アプリのパスを前提にしています)
- [opencode](https://opencode.ai) がインストール済みであること
- DeepAI Code アプリが起動済みで、サインインしていること(応答は DeepAI Code のローカルプロキシ経由です)
- モデルが選択できない場合は `~/.deepai-code/userdata/deepai/pi/deepai/models.json` と `~/.config/opencode/opencode.jsonc` を確認してください

## リポジトリ構成

| パス | 役割 |
| --- | --- |
| `deepai-pi` | DeepAI Code 内蔵 Pi CLI を実行するラッパー(対話 / 非対話) |
| `opencode-deepai-launch` | DeepAI Code の設定から opencode の設定を生成して起動する |
| `opencode/command/deepai.md` | opencode の `/deepai` コマンド定義 |

## ライセンス

[MIT](LICENSE)
