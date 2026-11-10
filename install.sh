#!/bin/sh
# deepai2cli インストーラ(冪等・macOS・リポジトリの取得なし)。
#
# 必要なファイルだけを直接ダウンロードして ~/.local/bin 等に配置します。
# git もリポジトリのクローンも使いません。
#
# 使い方(これが唯一のインストール方法):
#   curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh
#
#   # 実行内容を固定したい場合は main ではなくタグ/コミットを指定:
#   curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/<tag>/install.sh | sh
#
#   # 実行前に中身を確認したい場合(2 ステップ):
#   curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh -o install.sh
#   sh install.sh
#
# オプション:
#   --dry-run    何をするかだけ表示して終了(何も書き換えない)
#   --uninstall  配置したファイルを削除
#   -h, --help   このヘルプを表示
#
# ダウンロード元は DEEPAI2CLI_URL_BASE で変更できます
# (既定: https://raw.githubusercontent.com/yukurust/deepai2cli/main)。
# 更新は curl コマンドの再実行です。
#
# 配置されるコマンド:
#   pi                     pi を独立セッションで起動(Orca の --agent pi からも使われる)
#   deepai-pi              pi のフレンドリーなラッパー
#   deepai-up              DeepAI Code をバックグラウンド起動して準備待ち
#   deepai-ready           opencode / pi を開く前の準備(起動・接続・設定同期)
#   deepai-opencode        準備してから opencode を起動
#
# 前提:
#   - macOS / DeepAI Code アプリ(サインイン済み)/ [opencode](https://opencode.ai)
#   - 既に別の `pi` コマンドがある場合は pi 系だけスキップして残りをインストールする
set -eu

BIN_DIR="$HOME/.local/bin"
COMMAND_DIR="$HOME/.config/opencode/command"
SCRIPTS="pi deepai-pi deepai-up deepai-ready deepai-opencode"
URL_BASE="${DEEPAI2CLI_URL_BASE:-https://raw.githubusercontent.com/yukurust/deepai2cli/main}"
DEEPAI_APP="${DEEPAI_APP:-/Applications/DeepAI Code.app}"

usage() {
  cat <<'EOF'
deepai2cli インストーラ(冪等・macOS・リポジトリの取得なし)

  curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh

必要なファイルだけを直接ダウンロードして ~/.local/bin 等に配置します。

オプション:
  --dry-run    何をするかだけ表示して終了(何も書き換えない)
  --uninstall  配置したファイルを削除
  -h, --help   このヘルプを表示

更新は curl コマンドの再実行、削除は:
  curl -fsSL https://raw.githubusercontent.com/yukurust/deepai2cli/main/install.sh | sh -s -- --uninstall
EOF
}

DRY_RUN=0
UNINSTALL=0
case "${1:-}" in
  '') ;;
  --dry-run) DRY_RUN=1 ;;
  --uninstall) UNINSTALL=1 ;;
  -h|--help) usage; exit 0 ;;
  *) echo "install.sh: 不明なオプションです: $1" >&2; usage >&2; exit 2 ;;
esac

# このスクリプトがリポジトリ内に置かれている場合はその場のファイルを使う
# (開発用。ネットワーク不要)。それ以外(curl | sh 等)はダウンロードする。
SELF_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || SELF_DIR=''
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/pi" ] && [ -f "$SELF_DIR/deepai-ready" ]; then
  LOCAL_DIR="$SELF_DIR"
else
  LOCAL_DIR=''
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "install.sh(dry-run): $*"
  else
    "$@"
  fi
}

fetch() {
  # fetch <url|local-path> <dest> <mode>
  src="$1" dest="$2" mode="$3"
  if [ -n "$LOCAL_DIR" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "install.sh(dry-run): cp $src $dest (mode $mode)"
    else
      cp "$src" "$dest"
      chmod "$mode" "$dest"
    fi
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "install.sh(dry-run): curl -fsSL $URL_BASE/$src -o $dest (mode $mode)"
    return
  fi
  tmp="$dest.tmp.$$"
  if ! curl -fsSL "$URL_BASE/$src" -o "$tmp"; then
    # 失敗時に一時ファイルを残さない。
    rm -f "$tmp"
    echo "install.sh: ダウンロードに失敗しました: $URL_BASE/$src" >&2
    exit 1
  fi
  mv "$tmp" "$dest"
  chmod "$mode" "$dest"
}

if [ "$(uname -s)" != 'Darwin' ]; then
  echo 'install.sh: このツールは macOS 専用です。' >&2
  exit 1
fi

if [ "$UNINSTALL" -eq 1 ]; then
  for name in $SCRIPTS; do
    run rm -f "$BIN_DIR/$name"
  done
  run rm -f "$COMMAND_DIR/deepai.md"
  echo 'install.sh: 配置したファイルを削除しました。'
  exit 0
fi

# --- 事前チェック(致命的でないものは警告に留める) ---
DEEPAI_MISSING=0
if [ ! -d "$DEEPAI_APP" ]; then
  DEEPAI_MISSING=1
  echo "install.sh: 警告: DeepAI Code アプリが見つかりません: $DEEPAI_APP" >&2
fi
for cmd in python3 curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "install.sh: 必須コマンドがありません: $cmd" >&2
    exit 1
  fi
done
if ! command -v opencode >/dev/null 2>&1; then
  echo 'install.sh: 警告: opencode が見つかりません。https://opencode.ai からインストールしてください。' >&2
fi

# `pi` の名前衝突チェック(Orca は detectCmd: pi で探すため、この名前が必須)。
# 別の pi がある場合は pi 系(pi / deepai-pi / /deepai)だけをスキップして
# 残り(opencode 系)をインストールする。opencode のみの利用では pi は不要。
SKIP_PI=0
EXISTING_PI="$(command -v pi || true)"
if [ -n "$EXISTING_PI" ] && [ "$EXISTING_PI" != "$BIN_DIR/pi" ]; then
  SKIP_PI=1
  echo "install.sh: 注意: $EXISTING_PI に別の pi があります。" >&2
  echo 'install.sh: 既存の pi を優先し、pi 系(pi / deepai-pi / /deepai コマンド)はスキップします。' >&2
  echo 'install.sh: pi 系も使う場合は、既存の pi を外すか PATH の順で ~/.local/bin を先にしてから再実行してください。' >&2
fi

# --- 配置 ---
run mkdir -p "$BIN_DIR" "$COMMAND_DIR"
for name in $SCRIPTS; do
  case "$name" in
    pi|deepai-pi) [ "$SKIP_PI" -eq 1 ] && continue ;;
  esac
  if [ -n "$LOCAL_DIR" ]; then
    fetch "$LOCAL_DIR/$name" "$BIN_DIR/$name" 755
  else
    fetch "$name" "$BIN_DIR/$name" 755
  fi
done
if [ "$SKIP_PI" -eq 0 ]; then
  if [ -n "$LOCAL_DIR" ]; then
    fetch "$LOCAL_DIR/opencode/command/deepai.md" "$COMMAND_DIR/deepai.md" 644
  else
    fetch "opencode/command/deepai.md" "$COMMAND_DIR/deepai.md" 644
  fi
fi

# --- 終了案内 ---
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo "install.sh: 注意: $BIN_DIR が PATH にありません。シェル設定に次を追加してください:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo 'install.sh: 完了。次のステップ:'
echo '  deepai-up --status                 # DeepAI Code のプロキシ確認(未起動なら自動起動)'
echo '  deepai-ready                       # opencode / pi を開く前の準備(起動・接続・設定同期)'
if [ "$SKIP_PI" -eq 1 ]; then
  echo 'install.sh: (pi 系は既存の pi を優先してスキップしました)'
else
  echo '  pi                                 # pi を独立セッションで起動'
  echo '  orca agent launch --agent pi       # Orca から pi に接続'
fi
if [ "$DEEPAI_MISSING" -eq 1 ]; then
  echo ''
  echo 'install.sh: ★ DeepAI Code アプリが未インストールです。'
  echo 'install.sh:   pi / DeepAI モデルの利用には DeepAI Code アプリ(サインイン済み)が必要です。'
  echo 'install.sh:   導入してサインイン後、deepai-ready を実行してください。'
fi
