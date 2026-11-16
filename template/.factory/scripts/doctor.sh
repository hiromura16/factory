#!/usr/bin/env bash
# インストール済みファクトリーに、安全な実行に必要な設定があるか確認します。

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 2

failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

required_files=(
  CLAUDE.md
  AGENTS.md
  docs/factory/CONTRACT.md
  docs/factory/CHARTER.md
  .factory/gates.conf
  .claude/scripts/gates.sh
)

for path in "${required_files[@]}"; do
  [ -f "$path" ] && pass "$path が存在します" || fail "$path がありません"
done

if [ -f CLAUDE.md ] && grep -q '<PROJECT NAME>\|<install>\|<One paragraph:' CLAUDE.md; then
  fail "CLAUDE.md に設定用プレースホルダーが残っています"
else
  pass "CLAUDE.md のプレースホルダーは置換済みです"
fi

if [ -f docs/factory/CHARTER.md ] && grep -q '^CHARTER_STATUS: ready$' docs/factory/CHARTER.md; then
  pass "憲章はreadyに設定されています"
else
  fail "憲章がreadyに設定されていません"
fi

if [ -f docs/factory/CHARTER.md ] && grep -q '^TIER: \(revival\|greenfield\|oss\|client-production\)$' docs/factory/CHARTER.md; then
  pass "憲章のtierは有効です"
else
  fail "憲章のtierが未設定または無効です"
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
  pass "Gitリポジトリを検出しました"
  if git remote get-url origin >/dev/null 2>&1; then pass "originリモートを検出しました"; else warn "originリモートがありません"; fi
else
  fail "Gitリポジトリではありません"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  pass "GitHub CLIは認証済みです"
  missing_labels=0
  for label in factory:ready-to-implement factory:ready-to-spec factory:needs-info factory:wait-to-implement factory:in-progress factory:awaiting-review; do
    gh label view "$label" >/dev/null 2>&1 || missing_labels=$((missing_labels + 1))
  done
  [ "$missing_labels" -eq 0 ] && pass "稼働キューのラベルが存在します" || warn "稼働キューのラベルが $missing_labels 個不足しています。次を実行してください: ./.factory/scripts/bootstrap-github.sh --apply"
else
  warn "ghが未導入または未認証のため、稼働キューの検査をスキップしました"
fi

if [ -f .codex/hooks.json ]; then
  warn "Codex利用者は/hooksでリポジトリのフックを確認し、信頼を承認する必要があります"
fi
warn "GitHubのブランチ保護またはルールセットを手動で確認してください。docs/factory/GITHUB.mdを参照"

printf '\nFACTORY_DOCTOR: failures=%d warnings=%d\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
