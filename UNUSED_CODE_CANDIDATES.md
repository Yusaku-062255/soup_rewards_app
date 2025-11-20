# 不要コード削除候補リスト

## 📋 概要

SOUP Rewards アプリのコードベースから、現時点で参照されていないページ・Widget・ユーティリティの候補を洗い出しました。

**注意**: このリストは「削除提案」です。実際に削除する前に、各ファイルの内容を確認し、必要に応じてバックアップを取ってください。

---

## 🗑️ 削除候補ファイル

### 1. `lib/features/home/presentation/pages/improved_home_page.dart` (739行)

**状態**: 削除候補（高確率で不要）

**理由**:
- `main_page.dart`では`home_page.dart`をimportして使用
- `improved_home_page.dart`への参照が見つからない（`grep -r "improved_home_page\|ImprovedHomePage" lib/`で0件）
- `pointsProvider`, `couponsProvider`, `newsProvider`を使用しているが、これらは`app_providers.dart`で定義されているが、実際には`home_page.dart`では使用されていない
- 実装途中の旧UIの可能性が高い

**確認方法**:
```bash
grep -r "improved_home_page\|ImprovedHomePage" lib/ test/
```

**推奨アクション**:
- 使用されていないことを確認後、削除を検討
- または、`home_page.dart`の代わりに使用する場合は、`main_page.dart`のimportを変更

**影響範囲**:
- このファイルを削除しても、アプリの動作に影響はない（使用されていないため）

---

## ✅ 使用中のファイル（削除不要）

### 1. `lib/features/qr_scan/presentation/pages/qr_scan_page.dart` (18行)

**状態**: 使用中（エイリアスとして機能）

**理由**:
- `QrScanPage`は`QrScanPageNew`へのエイリアス
- 他のファイルから`QRScanPage`として参照される可能性があるため、残しておく
- ただし、現在は`QrScanPageNew`が直接使用されているため、将来的に削除を検討してもよい

---

## 🔍 要確認ファイル

### 1. `lib/core/utils/error_handler.dart`

**状態**: 要確認

**理由**:
- `improved_home_page.dart`で使用されているが、`improved_home_page.dart`自体が使用されていない
- 他のファイルで使用されているか確認が必要

**確認方法**:
```bash
grep -r "error_handler\|AppErrorHandler\|LoadingOverlay" lib/ --exclude-dir=improved_home_page
```

### 2. `lib/core/utils/performance_utils.dart`

**状態**: 要確認

**理由**:
- `improved_home_page.dart`で使用されているが、`improved_home_page.dart`自体が使用されていない
- 他のファイルで使用されているか確認が必要

**確認方法**:
```bash
grep -r "performance_utils\|PerformanceUtils" lib/ --exclude-dir=improved_home_page
```

### 3. `lib/core/utils/security_utils.dart`

**状態**: 要確認

**理由**:
- 使用箇所を確認する必要がある

**確認方法**:
```bash
grep -r "security_utils\|SecurityUtils" lib/
```

---

## 📊 削除候補のサマリー

| ファイル | 行数 | 削除推奨度 | 理由 |
|---------|------|-----------|------|
| `lib/features/home/presentation/pages/improved_home_page.dart` | 739 | 高 | どこからも参照されていない |

---

## 🎯 推奨アクション

1. **`improved_home_page.dart`の削除**
   - 使用されていないことを確認後、削除を検討
   - 削除前に、`home_page.dart`と比較して、有用な実装がないか確認

2. **`error_handler.dart`と`performance_utils.dart`の確認**
   - `improved_home_page.dart`を削除する場合、これらのファイルも使用されていない可能性がある
   - 他のファイルで使用されているか確認

3. **`qr_scan_page.dart`の整理**
   - 現在は`QrScanPageNew`が直接使用されているため、エイリアスファイルは将来的に削除を検討

---

## ⚠️ 削除前の確認事項

1. **バックアップ**: 削除前に、該当ファイルをバックアップ
2. **依存関係**: 削除対象ファイルが他のファイルに依存していないか確認
3. **テスト**: 削除後に`flutter analyze`と`flutter test`を実行して問題がないか確認

---

## 📝 削除コマンド（確認後）

```bash
# improved_home_page.dartを削除（確認後）
rm lib/features/home/presentation/pages/improved_home_page.dart

# 削除後にflutter analyzeを実行
flutter analyze
```

---

**作成日**: 2024年（実装完了時点）
**確認者**: [確認者の名前を記入]

