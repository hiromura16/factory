#!/usr/bin/env bash
# install.sh - ファクトリーテンプレートを対象リポジトリへコピーします。
#
#   ./install.sh              # 現在のディレクトリにインストール
#   ./install.sh /path/repo   # 指定リポジトリにインストール
#   ./install.sh --dry-run    # 実行予定の操作を表示
#   ./install.sh --with-issue-trigger /path/repo
#
# 既存ファイルは上書きしません。安全に再実行でき、スキップした内容を表示します。

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/template" && pwd)"
DRY=0
WITH_ISSUE_TRIGGER=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --with-issue-trigger) WITH_ISSUE_TRIGGER=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "エラー: 未知のオプション: $arg" >&2; exit 2 ;;
    *)
      [ -z "$TARGET" ] || { echo "エラー: 対象ディレクトリは1つ指定してください" >&2; exit 2; }
      TARGET="$arg"
      ;;
  esac
done

TARGET="${TARGET:-$PWD}"
[ -d "$TARGET" ] || { echo "エラー: ディレクトリが存在しません: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || {
  echo "警告: $TARGET はGitリポジトリではありません。" >&2
  echo "         クラウドセッションはGitHubリモートからクローンするため、リモートが必要です。" >&2
}

echo "ファクトリーテンプレート -> $TARGET"
[ "$DRY" -eq 1 ] && echo "（ドライラン）"
echo

COPIED=0; SKIPPED=0

copy() {
  local rel="$1" src="$SRC/$1" dst="$TARGET/$1"
  if [ -e "$dst" ]; then
    printf '  スキップ %s（既存）\n' "$rel"; SKIPPED=$((SKIPPED+1)); return
  fi
  printf '  作成     %s\n' "$rel"; COPIED=$((COPIED+1))
  [ "$DRY" -eq 1 ] && return
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

# テンプレートを走査します。ドットで始まるファイルも含めます。
# カウンターをループ後も保持するため、パイプではなくプロセス置換を使います。
while IFS= read -r rel; do
  if [ "$rel" = ".github/workflows/factory-fire.yml" ] && [ "$WITH_ISSUE_TRIGGER" -eq 0 ]; then
    continue
  fi
  copy "$rel"
done < <(cd "$SRC" && find . -type f | sed 's|^\./||' | sort)

if [ "$DRY" -eq 0 ]; then
  chmod +x "$TARGET/.claude/scripts/gates.sh"    2>/dev/null || true
  chmod +x "$TARGET/.claude/hooks/block-merge.sh" 2>/dev/null || true
  chmod +x "$TARGET/.factory/scripts/doctor.sh" 2>/dev/null || true
  chmod +x "$TARGET/.factory/scripts/bootstrap-github.sh" 2>/dev/null || true
  chmod +x "$TARGET/.factory/scripts/prove-test.sh" 2>/dev/null || true
fi

cat <<'EOF'

次の順序で進めてください:

  セットアップガイド: docs/factory/README.md

  1. docs/factory/CHARTER.md
     TIER、LOAD_BEARINGのglob、AUTOMATABLEを設定します。
     ファクトリーが扱える作業を決める唯一の手順です。
     全項目を確認してからCHARTER_STATUSをreadyにしてください。

  2. .factory/gates.conf と ./.claude/scripts/gates.sh full
     必須ゲートがこのリポジトリに合っていることを確認します。
     必須ゲートをスキップするとMISCONFIGUREDとなり、無人実行を阻止します。

  3. CLAUDE.md
     <PROJECT NAME>見出しとコマンドブロックを置き換えます。
     ファクトリールールの節はそのまま維持してください。

  4. 初期設定と診断:
       ./.factory/scripts/bootstrap-github.sh        # ラベルのプレビュー
       ./.factory/scripts/bootstrap-github.sh --apply
       ./.factory/scripts/doctor.sh

     デフォルトブランチにGitHubルールセットまたはブランチ保護を設定します。
     フックは多層防御であり、リポジトリ側の強制措置の代わりにはなりません。

  5. コミットしてpushします。
     クラウドセッションはローカルではなくリモートからクローンします。

  6. ローカルのドライラン:
       claude
       /factory
       "factory-triageスキルを報告のみで実行してください。何も書き込まないでください。"

  7. クラウドのドライラン:
       claude --cloud "factory-triageスキルを実行し、予定する作業を報告してください。
                       何も書き込まないでください。"

  8. ルーチン1だけを作成します。ROUTINES.mdを参照してください。
     数日間運用してから、残りを追加します。

  即時Issueトリガーは任意で、既定ではインストールしません。
  定期ポーリングでは遅い場合だけ、--with-issue-triggerを付けて再実行してください。

EOF

echo
echo "作成: $COPIED   スキップ: $SKIPPED"
