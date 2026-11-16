# Claudeクラウドのクイックスタート

所要時間は約30分です。最初は顧客のリポジトリではなく、`greenfield`のリポジトリで試してください。

このガイドは、デスクトップのチュートリアルを終えたところから始まります。テンプレートのインストール、チャーターの設定、ローカルゲートの成功確認がまだなら、[GETTING_STARTED.md](GETTING_STARTED.md)から始めてください。Claudeのクラウドセッションとルーチンを追加する準備ができたら、ここへ戻ります。

## 0. 前提条件

- Claude Code CLIをインストールし、`claude auth login`でサインインしていること（claude.aiのサブスクリプションでのログインであり、APIキーではありません。ルーチンと`--teleport`には、どちらもこのログインが必要です）
- Web版Claude Codeが有効であること
- 次のいずれかでGitHubを接続していること
  - リポジトリに[Claude GitHub App](https://github.com/apps/claude)をインストールする
  - ターミナルで`/web-setup`を実行し、`gh`トークンを同期する

**ルーチンのGitHubトリガー**と**auto-fix**にはAppが必要です。`/web-setup`だけではクローンのアクセス権は得られますが、Webhookは有効になりません。ルーチン3（PR検証）を使う場合は、Appをインストールしてください。

確認します。

```bash
claude --version && claude auth whoami
```

## 1. テンプレートをインストールする

```bash
cd /path/to/your/repo
/path/to/reference-software-factory/install.sh
```

共有のFactory契約、Claude Codeのファイル、Codexアダプター、`docs/factory/`をコピーし、既存のものは上書きしません。コミット前に差分をレビューしてください。任意の即時Issueトリガーワークフローは、`--with-issue-trigger`を指定した場合だけインストールされます。

## 2. チャーターを書く

**ここが判断を行う段階です。** ゲートの接続設定やリポジトリ側の強制ルールもレビューが必要ですが、Factoryにどの作業を試みさせるかを決めるのはチャーターです。

```bash
$EDITOR docs/factory/CHARTER.md
```

少なくとも次を設定します。

- **`CHARTER_STATUS`**：編集中は`incomplete`のままにし、すべての節をレビューしてから`ready`にします。
- **`TIER`**：`revival`、`greenfield`、`oss`、`client-production`のいずれか。この1つの選択で、各ルーチンに与える自律性の範囲が決まります。
- **`LOAD_BEARING`**：どのルーチンも無人では変更してはいけないパスのglob。最初は広めに保護してください。証拠を得てから緩めることはできますが、逆の対応は高くつきます。
- **`AUTOMATABLE`**：具体的に書きます。曖昧な項目からは曖昧なトリアージしか生まれません。
- **`STOP_IF`**のレビューキュー上限：3から始めます。

`AUTOMATABLE`を許容しすぎる方向に誤設定することが、最もよくある失敗の原因です。依存関係の更新と文書の修正から始め、証拠が得られたら対象カテゴリを追加してください。

## 3. ゲートを接続する

```bash
$EDITOR .factory/gates.conf
$EDITOR .claude/scripts/gates.sh   # 自動検出にプロジェクト固有のロジックが必要な場合のみ
```

スクリプトはnode、python、rust、goを自動検出します。実際に使うコマンドが選ばれることを確認してください。

```bash
./.claude/scripts/gates.sh fast
./.claude/scripts/gates.sh full
```

必須ゲートは`.factory/gates.conf`にレベル別で列挙されています。必須ゲートを実行できない場合、結果は`MISCONFIGURED`、終了コードは2になります。任意のゲートには`SKIP`が表示されることがあります。各ゲートを必須リストに含めるかどうかは、意図的に判断してください。

## 4. 実際のキューと強制ルールを初期設定する

担当の確保と引き継ぎに使うGitHubラベルを、プレビューしてから作成します。

```bash
./.factory/scripts/bootstrap-github.sh
./.factory/scripts/bootstrap-github.sh --apply
```

デフォルトブランチにGitHubルールセットまたはブランチ保護を設定し、エージェントには迂回権限を与えないでください。コミット済みのフックは一般的なシェルコマンドを捕捉しますが、完全な強制境界ではありません。最低限の設定は`docs/factory/GITHUB.md`に記載されています。

設定チェックを実行します。

```bash
./.factory/scripts/doctor.sh
```

続いてコミットします。

```bash
chmod +x .claude/scripts/gates.sh .claude/hooks/block-merge.sh .factory/scripts/*.sh
git add CLAUDE.md AGENTS.md .factory .claude .agents .codex docs/factory
git commit -m "factory: install"
git push
```

**クラウドで試す前にpushしてください。** クラウドセッションはローカルのチェックアウトではなく、リモートからクローンします。

## 5. まずローカルで試す

```bash
claude
```

```
/factory
```

空のコントロールルーム報告が得られるはずです。次に、書き込みを許可せずトリアージをドライランします。

```
factory-triageスキルを実行し、何をするかの報告だけを行ってください。
何も書き込まず、ラベルも適用しないでください。
```

出力を読みます。振り分けが適切でなければ、チャーターが適切ではありません。無人実行が始まる前に、今ここで修正してください。

## 6. クラウドで試す

```bash
claude --cloud "factory-triageスキルを実行し、何をするか報告してください。何も書き込まないでください。"
```

`/tasks`で監視するか、claude.aiまたはモバイルアプリでセッションを開きます。

この実行では、特に次の2点を確認してください。

- スキルが見つかったこと（リポジトリのクローンから読み込まれることが、Factoryをコードとして管理する設計の要です）
- 組み込みのGitHubツールが、`gh`なしでIssueを読めたこと

自分で引き継ぐ必要がある場合は、セッションをローカルへ取り込みます。

```bash
claude --teleport
```

クリーンな作業ツリーと、同じリポジトリのチェックアウトが必要です。

## 7. ルーチンを作成する

[ROUTINES.md](ROUTINES.md)に従ってください。**ルーチン1（トリアージ）だけを作成します。** 残りを追加する前に、数日間実行してください。

初日に5つすべてを作成してはいけません。どれが問題を起こしているのか分からなくなり、まだ出力を読み解けないFactoryで1日の実行上限を使い切りやすくなります。

## 8. クラウド環境を設定する

[claude.ai/code](https://claude.ai/code)で環境セレクターを開きます。

ほとんどのリポジトリでは、**Default**環境（Trustedネットワーク、セットアップスクリプトなし）で十分です。ゲートに必要なツールがプリインストールされていない場合だけ、セットアップスクリプトを追加してください。

```bash
# 初回に一度実行され、その後キャッシュされる。約5分以内に収める
apt update && apt install -y gh
pnpm install --frozen-lockfile
```

クラウドセッションには、Node 20/21/22、pytest/ruff/mypy付きのPython、Ruby、PHP、Java、Go、Rust、Docker、Postgres 16、Redisがすでに含まれています。

**そのUIに貼り付けた内容は、必ずリポジトリの`CLOUD-ENVIRONMENT.md`に記録してください。** これはFactoryの中でコミットできない唯一の設定部分です。文書化しなければ、次のマシンで失われます。

## 9. 最初の実運用

トリアージを一度実行させます。その後、次を実行します。

```bash
claude
```

```
/factory
```

キューを読み、各項目の振り分けに賛成できるか確認します。評価しているのはエージェントではなくチャーターです。振り分けが誤っているなら、チャーターが曖昧だったことを意味します。

トリアージが納得できる振り分けを出すようになってから、ルーチン2（実装）を追加してください。

---

## 日々の使い方

**朝、デスクトップで。** 作業中のリポジトリで`/factory`を実行します。人の対応が必要な事項を先に示し、レビューキューの件数を知らせます。

**クラウドへ並列展開する。** 独立したタスクを、それぞれ別のセッションで実行します。

```bash
claude --cloud "factory-implementスキルに従ってFQ-142を実装してください"
claude --cloud "factory-implementスキルに従ってFQ-147を実装してください"
```

`/tasks`で追跡します。人の対応が必要になったら、`--teleport`で対象セッションを取り込みます。

**ローカルで計画し、リモートで実行する。** 単純ではない作業で最も価値の高いパターンです。

```bash
claude --permission-mode plan     # 検討だけを行い、編集しない
# 計画をリポジトリに保存し、コミットしてpushする
claude --cloud "docs/factory/specs/FQ-150/04-slices.mdの計画を実行してください"
```

先に人が判断し、実行は無人で進める。この分離が設計のすべてです。

**実行中のセッションを方向づける。** 接続し直さず、どのマシンからでも指示できます。

```bash
claude -p "変更履歴も更新してください" --cloud <session-id>
```

**PRを見守る。** 対象ブランチで`/autofix-pr`を実行すると、CI失敗やレビューコメントに対応するWebセッションが起動します。GitHub Appが必要です。PRコメントがデプロイ自動化を起動し得るリポジトリでは、有効にしないでください。

**毎月。** `/factory-tune`を実行します。見逃しがあった箇所は厳しくし、十分な証拠が積み重なった箇所は緩め、結果を`DECISIONS.md`に記録します。

---

## 拡張を止めるタイミング

現在のルーチン群が1週間問題なく動き、その出力を読んだら、次のルーチンを追加します。レビューキューが頻繁にチャーターの上限へ達するようになったら、追加を止めてください。

その段階では、自動化を増やしても成果は増えません。制約は実行できるエージェントの数ではなく、人の判断を待つ決定事項の数です。キューが満杯なら、レビューを速めるよりもFactoryが作る量を減らすべきです。
