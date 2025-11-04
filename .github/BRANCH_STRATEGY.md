# ブランチ戦略

## ブランチ構造

```
main (保護)
  ├── develop (開発統合ブランチ)
  │   ├── feature/epic-1-auth
  │   ├── feature/epic-2-points-gacha
  │   ├── feature/epic-3-coupons
  │   └── feature/epic-4-booking
  └── hotfix/* (緊急修正)
```

## ブランチ種別

### `main`
- **用途**: 本番リリース用
- **保護**: マージ前にPRレビュー必須、CI成功必須
- **マージ元**: `develop` または `hotfix/*`
- **命名**: 固定

### `develop`
- **用途**: 開発統合ブランチ
- **保護**: PRレビュー推奨、CI成功必須
- **マージ元**: `feature/*`
- **命名**: 固定

### `feature/*`
- **用途**: 新機能開発
- **ベース**: `develop`
- **命名規則**: `feature/epic-{n}-{short-description}`
  - 例: `feature/epic-1-auth`, `feature/epic-2-points-gacha`
- **ライフサイクル**: 機能完成後に `develop` へマージし削除

### `hotfix/*`
- **用途**: 本番環境の緊急バグ修正
- **ベース**: `main`
- **命名規則**: `hotfix/{issue-number}-{short-description}`
  - 例: `hotfix/123-fix-login-crash`
- **ライフサイクル**: 修正後に `main` と `develop` 両方にマージ

### `claude/*`
- **用途**: Claude Code による自動実装ブランチ
- **ベース**: `develop` または現在の作業ブランチ
- **命名規則**: `claude/{base-branch}-{session-id}`
- **ライフサイクル**: PR作成後、レビュー完了でベースブランチにマージ

## ワークフロー

### 通常の機能開発

```bash
# 1. developから最新を取得
git checkout develop
git pull origin develop

# 2. featureブランチ作成
git checkout -b feature/epic-1-auth

# 3. 実装・コミット
git add .
git commit -m "feat(auth): Add anonymous auth and Apple Sign-In"

# 4. プッシュ
git push -u origin feature/epic-1-auth

# 5. PR作成（develop <- feature/epic-1-auth）
gh pr create --base develop --title "Epic 1: Authentication & Profile"

# 6. レビュー・CI通過後にマージ
# 7. featureブランチ削除
git branch -d feature/epic-1-auth
```

### エピック実装の流れ

各エピックは以下のサブタスクで構成：

1. **設計フェーズ**
   - Firestoreコレクション設計
   - セキュリティルール設計
   - Cloud Functions設計
   - UI/UXワイヤーフレーム

2. **実装フェーズ**
   - Backend実装（Functions + Rules）
   - Flutter実装（UI + Repository + Provider）
   - テスト実装

3. **検証フェーズ**
   - Unit/Widget/Integration テスト
   - 手動テスト（iOS実機）
   - セキュリティレビュー

4. **マージフェーズ**
   - PR作成
   - レビュー対応
   - CI/CD成功確認
   - developへマージ

## コミットメッセージ規約

### フォーマット
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `style`: コードフォーマット（機能変更なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・設定変更

### Scope
- `auth`: 認証関連
- `points`: ポイント関連
- `coupons`: クーポン関連
- `booking`: 予約関連
- `functions`: Cloud Functions
- `rules`: Firestoreルール
- `ci`: CI/CD

### 例
```
feat(auth): Implement Apple Sign-In

- Add Sign in with Apple button to login screen
- Integrate firebase_auth with Apple provider
- Update user profile after successful sign-in

Closes #42
```

## PR作成チェックリスト

- [ ] ブランチ名が命名規則に従っている
- [ ] コミットメッセージが規約に従っている
- [ ] テストが追加されている
- [ ] CIが成功している
- [ ] 秘密情報が含まれていない
- [ ] PRテンプレートのチェックリストを埋めている
- [ ] スクリーンショット（UI変更時）を添付している

## リリースフロー

### v1.0.0リリース手順

```bash
# 1. developが安定していることを確認
git checkout develop
git pull origin develop

# 2. mainへマージ（PR経由）
gh pr create --base main --title "Release v1.0.0"

# 3. PRレビュー・承認後マージ

# 4. mainでタグ付け
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# 5. GitHub Releaseノート作成
gh release create v1.0.0 --title "v1.0.0" --notes "Initial production release"
```

## 緊急修正フロー

```bash
# 1. mainから緊急修正ブランチ作成
git checkout main
git pull origin main
git checkout -b hotfix/123-fix-crash

# 2. 修正・テスト
git add .
git commit -m "fix: Resolve crash on startup"

# 3. mainへPR
gh pr create --base main --title "Hotfix: Resolve crash on startup"

# 4. マージ後、developにも取り込む
git checkout develop
git merge hotfix/123-fix-crash
git push origin develop
```

## 注意事項

- **mainとdevelopは保護**: 直接pushは禁止、必ずPR経由
- **force pushは原則禁止**: 特にsharedブランチでは絶対にNG
- **featureブランチは短命**: 2週間以上は避ける、大きい場合は分割
- **定期的なrebase**: developの変更を定期的に取り込む
- **秘密情報チェック**: プッシュ前に必ず確認（pre-commit hook推奨）
