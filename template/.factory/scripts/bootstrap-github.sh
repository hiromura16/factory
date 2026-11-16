#!/usr/bin/env bash
# ファクトリーの稼働キューに使うラベルをプレビューまたは作成します。

set -euo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

command -v gh >/dev/null 2>&1 || {
  echo "エラー: ファクトリーのラベルの確認・作成にはghが必要です" >&2
  exit 2
}
gh auth status >/dev/null 2>&1 || {
  echo "エラー: ghが未認証です" >&2
  exit 2
}

labels=(
  "factory:ready-to-implement|0E8A16|1回の実装実行の対象"
  "factory:ready-to-spec|FBCA04|対話による製品・設計判断が必要"
  "factory:needs-info|D93F0B|明示された質問への回答待ち"
  "factory:wait-to-implement|C5DEF5|内容は把握済みだが依存事項の解消待ち"
  "factory:in-progress|1D76DB|実装実行が担当を確保済み"
  "factory:awaiting-review|5319E7|PRを作成済み。人による判断が必要"
  "factory:verified|0E8A16|独立検証に合格"
  "factory:rejected|B60205|独立検証で阻害要因を検出"
  "factory:monitor|BFDADC|ファクトリーモニターが起票"
)

if [ "$APPLY" -eq 0 ]; then
  echo "次のラベルを作成または更新します:"
  printf '  %s\n' "${labels[@]%%|*}"
  echo
  echo "書き込むには--applyを付けて再実行してください。"
  exit 0
fi

for entry in "${labels[@]}"; do
  IFS='|' read -r name color description <<< "$entry"
  gh label create "$name" --color "$color" --description "$description" --force
done

echo "ファクトリーのラベルを準備しました。"

