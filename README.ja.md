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

更新は curl コマンドの再実行です。実行内容を固定したい場合は URL の `main` をタグ/コミットに置き換えてください。インストーラは前提チェックを実施し、**DeepAI Code アプリが未導入の場合はその旨を明確に案内します**(`pi` と DeepAI モデルの利用に必要。導入・サインイン後に `deepai-ready` を実行してください)。既に別の `pi` が PATH にある場合はその `pi` を残したまま pi 系(`pi` / `deepai-pi` / `/deepai` コマンド)だけをスキップするので、**opencode のみの利用では既存の pi と衝突せずにインストールできます**。`~/.local/bin` を PATH に含めておいてください(`export PATH="$HOME/.local/bin:$PATH"`)。

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

モデル一覧は DeepAI Code の設定(`models.json`)から自動で取り込まれ、DeepAI Code にモデルが追加されると `deepai-ready` の再実行で増えます。既定モデルは `deepai/mimo-2.6-pro` です。モデル名は DeepAI Code 本体の表示に合わせます(例: `deepseek-v4.1-flash` は「DeepSeek V4.1 Flash 1017」)。モデル単位で Responses API を使うもの(`gpt-6-astra`)は、そのモデルだけ provider package を上書きします。

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

### pi を独立セッションとして実行する

```sh
pi                          # 対話セッション(実行ごとに独立した新規セッション)
pi "このプロジェクトを調査して"  # 最初の指示を付けて開始
pi --print "一文で要約して"    # 非対話で 1 回実行
```

`pi` は `deepai-pi` の実体で、引数は pi CLI にそのまま渡ります(`pi [options] [--] [@files...] [messages...]`)。既定はモデル `deepai/mimo-2.6-pro`(`DEEPAI_MODEL` で変更可)、実行ごとの独立セッション(`--session-id` / `--session` で既存セッションを継続)、ツール `read,bash,edit,write,grep,find,ls` です。

### Orca から pi に接続する

Orca は `pi` をエージェントとして認識します(`detectCmd: pi`、プロンプトは argv で渡る)。`pi` が PATH にあれば:

```sh
orca agent launch --agent pi --prompt "…" --json        # チャットセッション(--surface terminal で CLI 直起動)
orca terminal wait --for tui-idle --timeout-ms 600000   # エージェント CLI のアイドル待ち
orca terminal read --terminal <handle> --json           # 出力の読み取り
```

pi の起動時モデル指定は Orca 側で未対応のままとします(`orca agent launch --agent pi --model …` は "Agent pi does not support launch-time model selection" で拒否)。**Orca からのモデル選択・実行は opencode 経由**を使ってください(`opencode models` の一覧が Orca のモデルピッカーに渡り、`opencode run --model deepai/…` で実行されます)。pi セッションは設定のモデルで動き、切替はセッション内の `/model deepai/glm-5.3-flash` か、Orca ターミナルからの `DEEPAI_MODEL=glm-5.3-flash pi` で行います。

起動ごとに独立した pi セッションになります。スタンドアロンの pi では `DeepAI tools are unavailable` と表示されますが、これはアプリ連携ツール(スレッド・委任)が DeepAI Code のローカル接続を必要とするためで、エージェント自体は通常どおり動作します。

### pi から(どこからでも)opencode を起動する

```sh
deepai-opencode            # 設定を同期してから opencode を起動
deepai-opencode run "…"    # 引数はすべて opencode に渡る
```

### DeepAI Code をバックグラウンドで起動する

```sh
deepai-up              # 未起動なら非表示で起動し、API プロキシの応答を待つ
deepai-up --status     # 状態だけ確認(ready なら exit 0)
```

DeepAI Code のローカルプロキシは **アプリの起動ごとにポートと API キーが変わります**。`deepai-up` は `models.json` を毎回読み直して現行ポートへ接続を試みるため、ローテーション後も正しく追従します。

### opencode / pi を開く前に準備する

```sh
deepai-ready    # DeepAI Code の起動・API プロキシ待ち・opencode 設定の同期まで行う
```

`opencode` を開く前に実行してください(`pi` は任意。`pi` は内部でプロキシを待ちます)。**opencode も pi も起動しません**: 実行後は素の `opencode` をいつでも直接起動できます。DeepAI Code のアカウントやモデル設定(`models.json`)を更新したとき、あるいは **DeepAI Code を再起動したときは、このコマンドを一度実行**すると `~/.config/opencode/opencode.jsonc` の DeepAI 設定(モデル一覧・認証情報)に反映されます。ファイル内の他の設定・他プロバイダ・既定モデルはそのまま残ります(JSONC のコメントは保持されません)。バックアップはツール導入前のファイル1枚を `opencode.jsonc.bak` として保存するだけで、上書きも増殖もしません。認証情報は `~/.config/opencode/opencode.jsonc`(権限 600)のみに保持されます。起動・待機は `deepai-up` に委譲しているので、両者が干渉することはありません。

#### Orca の自動化と組み合わせる

Orca で opencode を起動する直前に `deepai-ready` を実行する設定にすると、DeepAI Code 未起動・再起動後も使える状態になってから opencode が立ち上がります。

```sh
deepai-ready && exec opencode "$@"   # 例: ラッパーの中身
```

### モデル一覧が古い・モデルが選択できないとき

1. `deepai-up --status` でプロキシが生きているか確認(未起動なら `deepai-up`)
2. `deepai-ready` で設定を再同期
3. それでもダメなら `~/.deepai-code/userdata/deepai/pi/deepai/models.json` と `~/.config/opencode/opencode.jsonc` の `baseUrl` が一致しているか確認

## できること

- **ターミナルから DeepAI Code 内蔵の Pi coding agent を実行**(`deepai-pi`、対話 / 非対話)
- **opencode のモデルとして DeepAI のモデルを選択して実行**(モデル一覧は DeepAI Code の設定から自動生成)
- **DeepAI Code をバックグラウンド(非表示)で起動**(`deepai-up`、未起動なら待機付きで自動起動)
- **opencode / pi を開く前の準備**(`deepai-ready`、何も起動せずに準備だけ完了)
- opencode の `/deepai` コマンドで DeepAI CLI(Pi)を 1 回実行
- 会話ごとに独立した Pi セッション ID を作成

## 前提

- macOS(DeepAI Code アプリのパスを前提。標準の `curl`・`python3` を使用)
- [opencode](https://opencode.ai) がインストール済みであること
- DeepAI Code アプリにサインイン済みであること(応答は DeepAI Code のローカルプロキシ経由。未起動なら `deepai-up` / `deepai-ready` がバックグラウンドで起動を試みます)
- 注意: DeepAI Code を再起動するとローカルプロキシのポートと API キーがローテーションされ、生成済み設定は無効になります。opencode を使う前に `deepai-ready` を実行してください
- モデルが選択できない場合は「モデル一覧が古い・モデルが選択できないとき」を参照してください

## リポジトリ構成

| パス | 役割 |
| --- | --- |
| `pi` | Pi CLI を独立セッションで実行(Orca の `--agent pi` が使う入口) |
| `deepai-pi` | `pi` のフレンドリーなラッパー(対話 / 非対話) |
| `deepai-up` | DeepAI Code をバックグラウンド起動し、ローカルプロキシの応答を待つ |
| `deepai-opencode` | 設定を同期してから opencode を起動 |
| `deepai-ready` | opencode / pi を開く前の準備(DeepAI Code の起動・接続・opencode 設定の同期。起動はしない) |
| `install.sh` | 冪等なインストーラ(コマンドを `~/.local/bin` にダウンロード。リポジトリ不要) |
| `opencode/command/deepai.md` | opencode の `/deepai` コマンド定義 |

## ライセンス

[MIT](LICENSE)
