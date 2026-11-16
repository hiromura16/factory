# Factory運用ガイド

このディレクトリは、リポジトリのソフトウェアFactoryの運用状態を永続的に保持します。
プロジェクトにテンプレートをインストールしたら、ここから始めてください。

最初の安全な到達目標は控えめです。憲章がプロジェクトを正確に説明していること、
必須ゲートがローカルで動くこと、Claude CodeとCodexの両方が、
何も書き込まずに予定する作業を報告できることを目指します。

## 最初に一度設定する

1. [CHARTER.md](CHARTER.md) を確認します。区分を1つ選び、サンプルのパスと作業分類を
   置き換え、レビュー待ちキューの上限を設定します。
   すべての節を読むまで `CHARTER_STATUS` は `incomplete` のままにします。
2. `../../.factory/gates.conf` を設定し、次を実行します。

   ```bash
   ./.claude/scripts/gates.sh fast
   ./.claude/scripts/gates.sh full
   ```

3. [`CLAUDE.md`](../../CLAUDE.md) 冒頭のプロジェクトの仮記入箇所とコマンド例を置き換えます。
4. `./.factory/scripts/bootstrap-github.sh` でGitHubラベルをプレビューします。
   対象リポジトリを確認してから `--apply` を付けてください。
5. [GITHUB.md](GITHUB.md) に従って、ブランチ保護またはGitHubルールセットを設定します。
6. `./.factory/scripts/doctor.sh` を実行し、インストール差分を確認して、コミット・pushします。

クラウドセッションはリモートリポジトリから始まります。
pushしていないFactoryは、クラウドセッションから見ると存在しません。

## Claude Codeから使う

インストールされるプロジェクトコマンドは次のとおりです。

- `/factory` は実際のキュー、ゲートの状態、人間の判断が必要な作業を報告します。
- `/factory-tune` は証拠を確認し、制約の変更を提案します。
- `factory-triage`、`factory-spec`、`factory-implement`、`factory-verify`、
  `factory-monitor` はワークフロースキルです。

まず、報告のみのトリアージを依頼します。

```text
factory-triageスキルを報告のみのモードで実行してください。ファイルの書き込みやラベルの適用はしないでください。
提案するすべての処理区分を、憲章に基づいて説明してください。
```

## Codexから使う

Codexは [`AGENTS.md`](../../AGENTS.md) を読み、`../../.agents/skills/` のアダプターを検出します。
ワークフローを名前で指定して依頼します。

```text
factory-statusスキルを使って管制室の状況を表示してください。報告のみとし、何も変更しないでください。
```

アダプターは `.claude/skills/` にある正規のワークフローを参照します。
Codexアダプターと [CONTRACT.md](CONTRACT.md) が食い違う場合は、契約を優先します。

## 各ファイルの役割

| ファイル | 役割 |
|---|---|
| [CHARTER.md](CHARTER.md) | リスク、範囲、自律性、停止に関する、人間が決める事項 |
| [CONTRACT.md](CONTRACT.md) | Claude CodeとCodexの共通ルール |
| [GITHUB.md](GITHUB.md) | キューラベルとリポジトリ側の強制ルールの設定 |
| [QUEUE.md](QUEUE.md) | レビュー可能なキューのスナップショット。実際の状態はGitHubラベルが保持 |
| [STATE.md](STATE.md) | 人間向けの簡潔な稼働状態のスナップショット |
| [DECISIONS.md](DECISIONS.md) | 採用した制約変更とその証拠 |
| [`runs/`](runs/README.md) | 実行ごとに1件の変更不可の記録 |

## 日々の運用ルール

作業を増やす前に、管制室の状況を確認してください。レビュー待ちの件数が憲章の上限に達したら、
成果物を増やすのを止めます。生成そのものが安価でも、Factoryの有用な処理量は、
人間が検証して理解できる量に制限されます。
