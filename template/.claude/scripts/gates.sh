#!/usr/bin/env bash
# gates.sh - ファクトリーの決定論的な判定。
#
# パイプラインのこの部分だけは、自信満々な説明でも判定を覆せません。
# 全ファクトリースキルが呼び出します。これなしにマージしてはいけません。
#
# 使い方:
#   ./.claude/scripts/gates.sh fast    # 型 + lint（数秒程度、頻繁に実行）
#   ./.claude/scripts/gates.sh full    # + テスト + ビルド（既定、PR作成前に実行）
#   ./.claude/scripts/gates.sh deep    # + 監査 + 複雑性（重要経路の変更時に実行）
#
# 終了コード: 0 = 全必須ゲート合格、1 = 1つ以上のゲートが不合格
#              2 = 無効なレベル、または必須ゲートを実行できなかった
#
# エージェントが結果を言い換えないよう、最後に機械可読行を出力します:
#   FACTORY_GATES: level=full status=RED passed=3 failed=1 failing=test skipped=build misconfigured=none
#
# プロジェクトに合わせて.factory/gates.confとDETECTブロックを調整してください。

set -uo pipefail

LEVEL="${1:-full}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2

case "$LEVEL" in
  fast|full|deep) ;;
  *)
    echo "エラー: ゲートレベルはfast、full、deepのいずれかです（指定値: $LEVEL）" >&2
    printf 'FACTORY_GATES: level=%s status=MISCONFIGURED passed=0 failed=0 failing=none skipped=none misconfigured=invalid-level\n' "$LEVEL"
    exit 2
    ;;
esac

REQUIRED_FAST="types lint"
REQUIRED_FULL="types lint test"
REQUIRED_DEEP="types lint test audit architecture"
if [ -f .factory/gates.conf ]; then
  # このファイルは運用規約で保護されており、変数への代入だけを含みます。
  # shellcheck disable=SC1091
  source .factory/gates.conf
fi

case "$LEVEL" in
  fast) REQUIRED="$REQUIRED_FAST" ;;
  full) REQUIRED="$REQUIRED_FULL" ;;
  deep) REQUIRED="$REQUIRED_DEEP" ;;
esac

for gate in $REQUIRED; do
  case "$gate" in
    types|lint|test|build|audit|mutation|architecture) ;;
    *)
      echo "エラー: .factory/gates.conf に未知の必須ゲートがあります: $gate" >&2
      printf 'FACTORY_GATES: level=%s status=MISCONFIGURED passed=0 failed=0 failing=none skipped=none misconfigured=unknown-required-gate:%s\n' "$LEVEL" "$gate"
      exit 2
      ;;
  esac
done

PASSED=0
FAILED=0
FAILING=""
SKIPPED=""
MISCONFIGURED=""

c_red()   { printf '\033[31m%s\033[0m\n' "$1"; }
c_green() { printf '\033[32m%s\033[0m\n' "$1"; }
c_dim()   { printf '\033[2m%s\033[0m\n' "$1"; }

# run <name> <command...> - ゲートを実行して判定を記録します。途中終了しません。
run() {
  local name="$1"; shift
  printf '\n=== gate: %s ===\n' "$name"
  if "$@"; then
    c_green "PASS  $name"
    PASSED=$((PASSED + 1))
  else
    c_red   "FAIL  $name"
    FAILED=$((FAILED + 1))
    FAILING="${FAILING}${FAILING:+,}${name}"
  fi
}

skip() {
  c_dim "SKIP  $1 ($2)"
  SKIPPED="${SKIPPED}${SKIPPED:+,}$1"
  case " $REQUIRED " in
    *" $1 "*) MISCONFIGURED="${MISCONFIGURED}${MISCONFIGURED:+,}$1" ;;
  esac
}

has()      { command -v "$1" >/dev/null 2>&1; }
pkg_has()  { [ -f package.json ] && node -e "process.exit(require('./package.json').scripts?.['$1']?0:1)" 2>/dev/null; }

# ---------------------------------------------------------------------------
# DETECT - プロジェクトの種類を識別します。リポジトリに合わせて編集してください。
# ---------------------------------------------------------------------------
STACK="unknown"
if   [ -f package.json ];      then STACK="node"
elif [ -f pyproject.toml ] || [ -f setup.py ]; then STACK="python"
elif [ -f Cargo.toml ];        then STACK="rust"
elif [ -f go.mod ];            then STACK="go"
fi

# npmと決めつけず、パッケージマネージャーを選びます。
PM="npm"
if   [ -f pnpm-lock.yaml ];   then PM="pnpm"
elif [ -f yarn.lock ];        then PM="yarn"
elif [ -f bun.lockb ];        then PM="bun"
fi
PMRUN="$PM run"
[ "$PM" = "npm" ] && PMRUN="npm run --silent"

printf 'factory gates | level=%s stack=%s pm=%s\n' "$LEVEL" "$STACK" "$PM"

# ---------------------------------------------------------------------------
# TIER 1 - fast。型検査とlint。編集のたびに実行できる軽量な検査。
# ---------------------------------------------------------------------------
case "$STACK" in
  node)
    if pkg_has typecheck;    then run types $PMRUN typecheck
    elif [ -f tsconfig.json ] && has npx; then run types npx --no-install tsc --noEmit
    else skip types "typecheckスクリプトもtsconfig.jsonもありません"; fi

    if pkg_has lint;         then run lint $PMRUN lint
    elif has npx && [ -f eslint.config.js -o -f eslint.config.mjs -o -f .eslintrc.json -o -f .eslintrc.cjs ]; then
                                  run lint npx --no-install eslint .
    else skip lint "lintスクリプトもeslint設定もありません"; fi
    ;;
  python)
    if has ruff;  then run lint  ruff check .;  else skip lint  "ruffが未導入です"; fi
    if has mypy;  then run types mypy .;        else skip types "mypyが未導入です"; fi
    ;;
  rust)
    run types cargo check --all-targets
    if has cargo-clippy || cargo clippy --version >/dev/null 2>&1; then
      run lint cargo clippy --all-targets -- -D warnings
    else skip lint "clippyが未導入です"; fi
    ;;
  go)
    run types go vet ./...
    if has golangci-lint; then run lint golangci-lint run; else skip lint "golangci-lintが未導入です"; fi
    ;;
  *)
    skip types "不明な技術スタック"; skip lint "不明な技術スタック"
    ;;
esac

# ---------------------------------------------------------------------------
# TIER 2 - full。テストとビルド。PR作成前の既定ゲート。
# ---------------------------------------------------------------------------
if [ "$LEVEL" = "full" ] || [ "$LEVEL" = "deep" ]; then
  case "$STACK" in
    node)
      if pkg_has test; then run test $PMRUN test; else skip test "testスクリプトがありません"; fi
      if pkg_has build; then run build $PMRUN build; else skip build "buildスクリプトがありません"; fi
      ;;
    python)
      if has pytest; then run test pytest -q; else skip test "pytestが未導入です"; fi
      ;;
    rust)
      run test cargo test --all
      run build cargo build --release
      ;;
    go)
      run test go test ./...
      run build go build ./...
      ;;
    *) skip test "不明な技術スタック"; skip build "不明な技術スタック" ;;
  esac
fi

# ---------------------------------------------------------------------------
# TIER 3 - deep。セキュリティ、複雑性、ミューテーション、アーキテクチャルール。
# 重要経路に関わる変更で実行します（docs/factory/CHARTER.md参照）。
# ---------------------------------------------------------------------------
if [ "$LEVEL" = "deep" ]; then
  case "$STACK" in
    node)
      run audit $PM audit --audit-level=high
      if pkg_has mutation; then run mutation $PMRUN mutation
      else skip mutation "'mutation'スクリプトがありません（CHARTER.mdを参照。カバレッジでは代替できません）"; fi
      ;;
    python)
      if has pip-audit; then run audit pip-audit; else skip audit "pip-auditが未導入です"; fi
      if has mutmut;    then run mutation mutmut run; else skip mutation "mutmutが未導入です"; fi
      ;;
    rust)
      if has cargo-audit; then run audit cargo audit; else skip audit "cargo-auditが未導入です"; fi
      ;;
    go)
      if has govulncheck; then run audit govulncheck ./...; else skip audit "govulncheckが未導入です"; fi
      ;;
    *)
      skip audit "不明な技術スタック"
      skip mutation "不明な技術スタック"
      ;;
  esac

  # アーキテクチャルール: 最初は単純なgrepの検査で十分です。
  # エージェントが言いくるめることもできません。以下に独自ルールを追加してください。
  printf '\n=== gate: architecture ===\n'
  ARCH_FAIL=0
  # 例: src/db以外から生のDBクライアントをインポートさせません。
  # if grep -rn "from '.*db/client'" src --include='*.ts' | grep -v '^src/db/'; then
  #   c_red "アーキテクチャ: src/db外からdb/clientがインポートされています"; ARCH_FAIL=1
  # fi
  if [ "$ARCH_FAIL" -eq 0 ]; then
    c_green "PASS  architecture"; PASSED=$((PASSED + 1))
  else
    c_red   "FAIL  architecture"; FAILED=$((FAILED + 1)); FAILING="${FAILING}${FAILING:+,}architecture"
  fi
fi

# ---------------------------------------------------------------------------
# 判定
# ---------------------------------------------------------------------------
STATUS="GREEN"
EXIT_STATUS=0
if [ -n "$MISCONFIGURED" ]; then
  STATUS="MISCONFIGURED"
  EXIT_STATUS=2
elif [ "$FAILED" -gt 0 ]; then
  STATUS="RED"
  EXIT_STATUS=1
fi

printf '\n---------------------------------------------\n'
[ -n "$SKIPPED" ] && c_dim "スキップ: $SKIPPED"
case "$STATUS" in
  GREEN) c_green "GATES GREEN（$PASSED 件合格）" ;;
  RED) c_red "GATES RED（$FAILED 件不合格: $FAILING）" ;;
  MISCONFIGURED) c_red "GATES MISCONFIGURED（必須ゲートをスキップ: $MISCONFIGURED）" ;;
esac

# 機械可読行。スキルにはそのまま引用するよう指示しており、
# これに矛盾する結果の報告は禁止されています。
printf 'FACTORY_GATES: level=%s status=%s passed=%d failed=%d failing=%s skipped=%s misconfigured=%s\n' \
  "$LEVEL" "$STATUS" "$PASSED" "$FAILED" "${FAILING:-none}" "${SKIPPED:-none}" "${MISCONFIGURED:-none}"

exit "$EXIT_STATUS"
