# Factory実行記録

実行ごとに変更不可のMarkdownファイルを1つ書きます。
これにより並列ルーチン間のマージ競合を避け、
後でFactoryを測定するための十分な構造化された証拠を残せます。

調整せずに一意になるファイル名を使ってください。

```
YYYY-MM-DDTHHMMSSZ-<stage>-<issue-or-run-id>.md
```

各ファイルは次のフロントマターで始めます。

```yaml
---
run_id: 2026-08-18T153012Z-implement-142
stage: triage | spec | implement | verify | monitor
started_at: 2026-08-18T15:30:12Z
finished_at: 2026-08-18T15:41:09Z
status: succeeded | stopped | rejected | infrastructure-failed
issue: 142 | none
pull_request: 318 | none
gate_level: fast | full | deep | none
gate_status: GREEN | RED | MISCONFIGURED | not-run
verifier: accepted | accepted-with-reservations | rejected | not-run
human_required: true | false
---
```

続いて、確認した内容、変更した内容、問題がなかった内容、停止した理由を記録します。
秘密情報、会話ログ全文、Issue本文のコピーは含めないでください。
代わりに、それらを管理するシステムへのリンクを記載します。

別のサービスを用意しなくても、この記録から簡単な測定ができます。
キューの滞留時間、ゲートの失敗率、検証者の却下率、レビューまでの時間、
実行やPRにひも付けられた検出漏れの欠陥などが対象です。
