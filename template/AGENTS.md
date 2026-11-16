# Codex向けプロジェクト・Factoryガイド

変更する前に、プロジェクトのコマンドと規約を `CLAUDE.md` で確認し、
続いて `docs/factory/CONTRACT.md` と `docs/factory/CHARTER.md` を読んでください。
初期設定とローカルでのドライランは `docs/factory/README.md` に従ってください。

この契約はClaude Codeと共有しています。このアダプターと契約が食い違う場合は、
契約を優先します。Factoryのワークフローには `.agents/skills/` にある
リポジトリ内のスキルを使ってください。

`.codex/hooks.json` のリポジトリフックは多層防御の一部です。
ローカルでの信頼設定が必要で、GitHubのブランチ保護を代替するものではありません。
