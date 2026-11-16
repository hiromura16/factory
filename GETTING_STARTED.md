# デスクトップアプリから始める

APIキー、独自のオーケストレーター、クラウドルーチンがなくても、安全なローカルのドライランまで進められます。このガイドでは、1つのリポジトリにFactoryをインストールし、そのリポジトリをClaude Code DesktopまたはChatGPTデスクトップアプリのCodexで開いて、エージェントの助けを借りながらプロジェクト固有の設定を仕上げます。

最初の一通りの作業には約15分を見込んでください。手順を覚える間は、新規開発用または使い捨てのリポジトリを使います。顧客の本番リポジトリを最初の試験対象にすることは勧めません。

## インストールされるもの

このリポジトリはテンプレートとインストーラーです。アプリケーションを`factory`リポジトリの中で開発するわけではありません。インストーラーは、Factoryを動かす対象プロジェクトへ、コミット済みの少数のファイルをコピーします。

- `CLAUDE.md`と`AGENTS.md`は、Claude CodeとCodexにプロジェクトの背景情報を伝えます。
- `.claude/`と`.agents/`には、各ハーネスが検出できるワークフローを格納します。
- `docs/factory/CHARTER.md`には、許可する作業を記録します。
- `.claude/scripts/gates.sh`は、既存の検査を決定論的な判定にまとめます。
- GitHubラベルは、明示的に初期設定した後、実際の作業キューになります。

インストーラーは既存ファイルの上書きを拒否します。それでも、まずドライランで実行してください。安全な既定値は役立ちますが、差分を読むことの代わりにはなりません。

## 1. クローンしてインストールする

設定したいプロジェクトと並ぶ場所に、このリポジトリをクローンします。

この日本語版は [Addy Osmani による原版 Factory](https://github.com/addyosmani/factory) のフォークです。以下では日本語版をクローンします。

```bash
git clone https://github.com/hiromura16/factory.git
git clone https://github.com/you/your-project.git
cd your-project
../factory/install.sh --dry-run .
../factory/install.sh .
```

プロジェクトがすでにディスク上にある場合は、代わりに絶対パスを渡します。

```bash
/path/to/factory/install.sh --dry-run /path/to/your-project
/path/to/factory/install.sh /path/to/your-project
```

この時点では、コミット、push、スケジュール登録、GitHubへの接続は何も行われていません。新しいファイルは、レビュー対象となる通常の作業ツリーの変更です。

## 2. デスクトップでの進め方を選ぶ

どちらの進め方でも、同じチャーター、ゲート、キュー、証拠ファイルを使います。Claude Codeを主な経路とし、クラウドセッションとルーチンも利用します。Codexは同じリポジトリ契約に沿って対話的に作業するための経路です。このプロジェクトでは、両製品のスケジューラーが同一であるかのようには扱いません。

### Claude Code Desktop

1. Claude Code Desktopの**Code**タブを開きます。
2. 環境として**Local**を選び、対象プロジェクトのフォルダーを指定します。`factory`テンプレートのフォルダーではありません。
3. **Plan**モードで開始します。Planが使えない場合は**Ask permissions**を使います。
4. 次のプロンプトを貼り付けます。

```text
CLAUDE.md、docs/factory/CONTRACT.md、docs/factory/CHARTER.md、およびこの
リポジトリのビルドとCIのファイルを読んでください。このプロジェクト用にFactoryを設定するのを手伝ってください。

最初は報告だけを行ってください。プロジェクトを要約し、ティア、重要な保護対象パス、
自動化できる作業、停止条件、fastとfullのゲートに使う実際のコマンドを提案してください。
製品方針やリスクの判断が必要な事項は、私に確認してください。

ファイルの編集、GitHubラベルの作成、コミット、push、ルーチンの作成、マージはしないでください。
```

求めるのは、エージェントが実際に見つけたファイルに基づく簡潔な設定案です。テストコマンドやプロジェクトのリスクを推測していたら、先へ進む前に訂正してください。

判断事項を承認したら、Planモードを終了して次を貼り付けます。

```text
私が承認した判断に基づき、docs/factory/CHARTER.md、.factory/gates.conf、
およびCLAUDE.mdの冒頭付近にあるプロジェクト固有のコマンドと規約を更新してください。

Factoryの契約と保護対象パスの既定値は維持してください。fastとfullのゲートを実行し、
続いて./.factory/scripts/doctor.shを実行してください。差分と正確なFACTORY_GATES行を
提示したところで停止してください。コミット、push、ラベル作成、ルーチン作成、マージはしないでください。
```

表示される差分をファイルごとにレビューしてください。Claude Code Desktopの公式ガイドでは、[プロジェクトフォルダー、環境、権限、差分レビューの操作](https://code.claude.com/docs/en/desktop)を説明しています。

### ChatGPTデスクトップアプリのCodex

1. 対象プロジェクトのフォルダーをCodexプロジェクトとして開きます。
2. プロジェクトに`AGENTS.md`があることを確認し、最初のタスクの前に読みます。
3. `/hooks`を開き、`.codex/hooks.json`のリポジトリフックを確認します。コマンドと保護対象パスが想定どおりであることを確かめてから、信頼を許可します。
4. 計画または読み取り専用のタスクから始め、次を貼り付けます。

```text
AGENTS.md、CLAUDE.md、docs/factory/CONTRACT.md、
docs/factory/CHARTER.md、およびこのリポジトリのビルドとCIのファイルを読んでください。
このプロジェクト用にFactoryを設定するのを手伝ってください。

最初は報告してください。プロジェクトを要約し、ティア、重要な保護対象パス、自動化できる作業、
停止条件、fastとfullのゲートに使う実際のコマンドを提案してください。安全に推定できない
製品方針やリスクの判断は、私に確認してください。

ファイルの編集、GitHubラベルの作成、コミット、push、マージはしないでください。
```

提案を承認したら、Claudeの節と同じ設定用プロンプトを使います。Codexは[`AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md)を読み、[リポジトリスキル](https://learn.chatgpt.com/docs/build-skills)を検出し、コミット済みの[リポジトリフック](https://learn.chatgpt.com/docs/hooks)を読み込めます。インストールされるアダプターは正規のClaudeワークフローを参照するため、方針が分岐しません。

## 3. 自分でも結果を確認する

エージェントが実行済みのはずですが、正常な出力を把握するため、統合ターミナルで一度実行してください。

```bash
./.claude/scripts/gates.sh fast
./.claude/scripts/gates.sh full
./.factory/scripts/doctor.sh
```

最後のゲート行は`status=GREEN`になるはずです。`MISCONFIGURED`は意味のある失敗です。必須検査が実行できなかったことを示し、テストコマンドがない状態を黙って成功扱いすることを防ぎます。

次にGitHubラベルをプレビューします。最初のコマンドは何も書き込みません。

```bash
./.factory/scripts/bootstrap-github.sh
```

プレビューに正しいリポジトリが表示されたことを確認してから、適用します。

```bash
./.factory/scripts/bootstrap-github.sh --apply
```

無人実行の前に、ブランチ保護またはGitHubルールセットを設定してください。コミット済みのフックは一般的なマージ経路を遮断しますが、強制力を持つ境界はGitHubです。

## 4. インストール内容をコミットする

コミット前に変更全体をレビューします。

```bash
git status --short
git diff --check
git diff
git add CLAUDE.md AGENTS.md .factory .claude .agents .codex docs/factory
git commit -m "factory: install reference workflow"
git push
```

クラウドセッションは常にリモートからのクローンで開始するため、このコミットをpushするまでFactoryを認識できません。

## 5. 最初のコントロールルーム確認を行う

Claude Code Desktopでは、次を入力します。

```text
/factory
```

Codexでは、次のように依頼します。

```text
factory-statusスキルを使ってコントロールルームを表示してください。報告のみで、何も変更しないでください。
```

キューが空でも正常な結果です。次に、トリアージのドライラン報告を依頼します。

```text
factory-triageワークフローを報告専用モードで実行してください。ファイルを書き込んだり、ラベルを適用したりしないでください。
提案する各振り分けについて、チャーターに基づいて説明してください。
```

提案された振り分けを読みます。誤った振り分けは通常、チャーターの問題です。エージェントを責めたり再訓練したりする前に、チャーターを厳密にしてください。有用なフィードバックループは、確認できる制約から始まります。

## クラウド自動化は段階的に追加する

対話的に使うだけなら、デスクトップの設定で十分です。ローカルでの報告とゲートの結果が予測可能になったら、[QUICKSTART.md](QUICKSTART.md)へ進み、Claudeのクラウドセッション、GitHub起点の検証、ルーチンを追加してください。

最初にトリアージのルーチンを作り、数日間動かします。初日から5つすべてのルーチンを追加すると、失敗の原因を特定しにくくなり、チャーターが役割を果たしているか分かる前にレビューキューが埋まるおそれがあります。
