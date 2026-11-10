# DeepAI Code CLI for opencode

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

opencode から、DeepAI Code のモデルと、DeepAI Code アプリに内蔵された Pi coding agent を使うための設定一式です。DeepAI Code のログイン状態・モデル設定をそのまま利用します。APIキーの再入力は不要です。

## できること

- **opencode のモデルとして DeepAI のモデルを選択して実行**(22 モデル、既定は `deepai/mimo-2.6-pro`)
- **選択できるモデルは DeepAI と omlx のみ**(`enabled_providers`)
- opencode の `/deepai` コマンドで DeepAI Code CLI(Pi)を 1 回実行
- ターミナルから `deepai-pi` で対話セッション / 非対話 1 回実行
- 会話ごとに独立した Pi セッション ID を作成

ローカルモデル(oMLX の Qwen3.8-Flash-Next)はこの PC のマシンパワーを使うため既定から外してあり、選択しない限り実行されません(モデル一覧には残っているので、必要なら選択して使えます)。

## 使い方

### opencode 内でモデルを選択する

opencode のモデル切替(`/models`)に DeepAI のモデルが出ます。

| 操作 | 方法 |
| --- | --- |
| 対話中に切替 | `/models` を開いて `deepai/…` を選択 |
| 起動時に指定 | `opencode run --model deepai/glm-5.3-flash "…"` |
| 一覧確認 | `opencode models` |

選択できるモデルは `deepai/*`(22 種)と `omlx/*`(ローカル 1 種)だけに絞ってあります。`~/.config/opencode/opencode.jsonc` の `enabled_providers` で制御しているため、Google や opencode の無料モデルは一覧に出ず、指定しても `Model unavailable` になります。

### Orca からも同じモデルだけを選ぶ

Orca の `opencode` / `opencode2` エージェントは、モデル一覧を `opencode models` の出力から取得します（10 分で再取得）。そのため上記の `enabled_providers` がそのまま効き、Orca のモデル選択にも `deepai/*` と `omlx/*` だけが並びます。Orca 側に別のモデル設定は不要です。

反映されない場合は、Orca を再起動するかモデル選択を開いて再取得させます（`~/Library/Application Support/Orca/agent-model-catalog.json` はキャッシュです）。

主なモデル: `mimo-2.6-pro`(既定) / `claude-opus-5-5` / `claude-fable-5-2` / `glm-5.3-flash` / `deepseek-v4.1-flash`(アプリ表記: **DeepSeek V4.1 Flash 1017**) / `qwen-3.8-flash` / `qwen-3.8-max-prime` / `minimax-m3` / `gemini-4-argon` / `gpt-6.1-sol` / `kimi-k3` など 22 種。

モデル名は DeepAI Code 本体の表示に合わせます(`deepseek-v4.1-flash` は「DeepSeek V4.1 Flash 1017」)。モデル単位で Responses API を使うもの(`gpt-6-astra`)は、そのモデルだけ provider package を上書きします。

### DeepAI Code CLI(Pi)を実行する

```sh
/deepai このプロジェクトの構成を調べて改善案を出して   # opencode のコマンド
!deepai-pi --print -- "一文で要約して"                # opencode のシェル実行(モデル不使用)
deepai-pi                                            # ターミナルで対話セッション
deepai-pi --print -- "一文で要約して"                 # 非対話で 1 回実行
deepai-pi --model glm-5.3-flash --print -- "…"       # モデル指定
```

`/deepai` は opencode のセッションモデルを経由して CLI を起動します。モデルを実行したくない場合は `!deepai-pi` を使ってください。

### opencode の設定を DeepAI Code に追従させる

```sh
opencode-deepai-launch    # 起動と同時に、最新のモデル一覧・認証情報で設定を更新
```

DeepAI Code のアカウントやモデル設定(`models.json`)を更新したときは、このコマンドを一度実行すると `~/.config/opencode/opencode.jsonc` の DeepAI 設定(モデル一覧・認証情報)に反映されます。DeepAI 側でモデルが追加された場合も同じ手順で増えます。

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
