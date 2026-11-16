# Factoryキューのスナップショット

運用上のキューはGitHubのIssueラベルにあります。このファイルは `factory-triage` が記述し、
`/factory` が報告する、レビュー可能なスナップショットです。
実装ルーチンはGitHubを直接問い合わせます。

このファイルの未マージの更新が、後続ルーチンによる作業の発見を妨げてはいけません。
永続的な実行証拠は、`docs/factory/runs/` に実行ごとに1ファイルで残します。

**処理区分**

| 処理区分 | 次の段階 |
|---|---|
| `ready-to-implement` | factory-implementが引き受ける |
| `ready-to-spec` | 人間がfactory-specを実行する |
| `needs-info` | 保留。質問はIssueに記載 |
| `wait-to-implement` | 保留。阻害要因は下に明記 |
| `awaiting-review` | PR作成済み。人間が担当 |
| `done` | 人間がマージ済み |

対応する実際のラベルには `factory:` 接頭辞を付けます。
例は `factory:ready-to-implement` と `factory:awaiting-review` です。
実際のIssueには、実装に必要なフィールドを持つ `factory-handoff:v1` コメントも付けます。

---

## 記入例（削除してください）

## FQ-142: 期限切れトークンで401ではなく500が返る
- disposition: ready-to-implement
- source: https://github.com/owner/repo/issues/142
- last_triaged: 2026-08-16
- repro: confirmed
- files_expected: src/auth/verify.ts, src/auth/verify.test.ts
- load_bearing: true
- gate_level: deep
- done_when: `verify.test.ts` に期限切れトークンで401応答を検証するケースがあり、`main` では失敗し、変更後は成功する
- confidence: high
- notes: `src/auth/**` は重要パスなので、単純な変更でも自動実装はできない。factory-specに回すか、人間の目視確認を必須として実装する。

---
