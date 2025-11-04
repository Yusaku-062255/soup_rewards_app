# Pull Request

## 概要
<!-- このPRで何を達成するか簡潔に説明 -->

## 変更内容
<!-- 主要な変更点をリストアップ -->

### Flutter
- [ ] 新規画面:
- [ ] 既存画面の変更:
- [ ] 新規Provider/Repository:
- [ ] ルーティング変更:

### Backend (Cloud Functions)
- [ ] 新規Function:
- [ ] 既存Function変更:
- [ ] Firestoreルール変更:

### インフラ・CI/CD
- [ ] GitHub Actions変更:
- [ ] 依存関係更新:
- [ ] 環境変数追加:

## テスト
- [ ] Unit tests追加/更新
- [ ] Widget tests追加/更新
- [ ] Integration tests追加/更新
- [ ] 手動テスト完了（iOS実機）
- [ ] Cloud Functions emulatorでテスト完了

## Acceptance Criteria
<!-- このPRが満たすべき受入基準 -->
- [ ]
- [ ]
- [ ]

## セキュリティチェック
- [ ] 秘密情報（API鍵、設定ファイル）をコミットしていない
- [ ] Firestoreルールで適切なアクセス制御を実装
- [ ] ユーザー入力のバリデーション実装
- [ ] トランザクション使用で競合状態を防止

## パフォーマンス
- [ ] 不要なFirestore読み取りを最小化
- [ ] リスト表示でページネーション実装
- [ ] 画像の最適化（キャッシュ、圧縮）

## スクリーンショット
<!-- UIに変更がある場合はスクリーンショットを添付 -->

## 関連Issue
<!-- 関連するIssue番号を記載 -->
Closes #

## デプロイ手順
<!-- このPRをマージした後に必要な手順 -->
- [ ] Cloud Functionsデプロイ: `cd functions && npm run deploy`
- [ ] Firestoreルールデプロイ: `firebase deploy --only firestore:rules`
- [ ] Firestoreインデックス作成: `firebase deploy --only firestore:indexes`
- [ ] その他:

## レビュー観点
<!-- レビュアーに特に注目してほしい点 -->
-
-

## 備考
<!-- その他の補足情報 -->
