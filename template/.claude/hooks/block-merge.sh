#!/usr/bin/env bash
# block-merge.sh - ファクトリーのシェルコマンドを多層防御の一環として検査します。
#
# 一般的なシェル経由のマージやファクトリー方針の迂回を検出します。
# これは強制境界ではありません。ツールフックで全ホスト/API経路は網羅できません。
# GitHubルールセットでデフォルトブランチを保護し、エージェントに迂回権限を与えないでください。
#
# .claude/settings.jsonでBashのPreToolUseフックとして登録します。
# 標準入力からツール呼び出しのJSONを読みます。終了コード2で呼び出しを阻止し、
# 標準エラー出力をエージェントへフィードバックします。

set -uo pipefail

INPUT="$(cat)"

# jqがなくてもコマンドを抽出します（クラウドにはjqがありますが、
# ローカルにはない場合があります。このフック自体が障害原因になってはいけません）。
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
else
  CMD="$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')"
fi

[ -z "$CMD" ] && exit 0

block() {
  echo "ファクトリーのフックがブロックしました: $1" >&2
  echo "" >&2
  echo "マージは人が判断します。docs/factory/CHARTER.mdを参照してください。" >&2
  echo "PRを作成して停止してください。別経路でマージしようとしてはいけません。" >&2
  exit 2
}

# さまざまな表記のマージ操作を検出します。
case "$CMD" in
  *"gh pr merge"*)          block "gh pr merge" ;;
  *"mergePullRequest"*)     block "GitHubマージAPI" ;;
  *"/pulls/"*"/merge"*)    block "GitHubマージAPI" ;;
  *"git merge "*)           block "git merge" ;;
  *"git push --force"*)     block "強制push" ;;
  *"git push -f"*)          block "強制push" ;;
esac

# 一般的な保護ブランチへの直接pushを検出します。デフォルトブランチが別名なら、
# その実際の名前をリポジトリルールセットで保護する必要があります。
if printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+push'; then
  if printf '%s' "$CMD" | grep -qE 'push([^;&|]*[[:space:]])(\+?refs/heads/|\+?HEAD:(refs/heads/)?)?(main|master|develop|production)([[:space:]]|$)'; then
    block "保護ブランチへのpush"
  fi
  current_branch="$(git branch --show-current 2>/dev/null || true)"
  if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+push([[:space:]]+\S+)?[[:space:]]*$' && \
     printf '%s' "$current_branch" | grep -qE '^(main|master|develop|production)$'; then
    block "保護ブランチからのpush"
  fi
fi

# シェル経由の憲章・ゲートスクリプト編集を防ぎ、
# settings.jsonのEdit拒否ルールの迂回を阻止します。
if printf '%s' "$CMD" | grep -qE '(docs/factory/CHARTER\.md|\.factory/gates\.conf|\.claude/|\.agents/|\.codex/)'; then
  if printf '%s' "$CMD" | grep -qE '(^|[;&|[:space:]])(sed|tee|cat[[:space:]]*>|>|>>|rm|mv|cp|truncate)'; then
    block "シェル経由での保護対象ファクトリーファイルへの書き込み"
  fi
fi

exit 0
