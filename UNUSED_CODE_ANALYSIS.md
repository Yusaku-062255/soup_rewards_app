# 不要コード分析レポート

## 概要
SOUP Rewards アプリのコードベースから、現時点で参照されていないページ・Widget・ルートの候補を洗い出しました。

---

## 削除候補ファイル

### 1. `lib/features/home/presentation/pages/improved_home_page.dart`
**状態**: 削除候補（要確認）

**理由**:
- `main_page.dart`では`home_page.dart`をimportして使用
- `improved_home_page.dart`への参照が見つからない

**確認方法**:
```bash
grep -r "improved_home_page\|ImprovedHomePage" lib/
```

**推奨アクション**:
- もし`improved_home_page.dart`が使用されていない場合、削除を検討
- または、`home_page.dart`の代わりに使用する場合は、`main_page.dart`のimportを変更

---

## 使用中のファイル（削除不要）

### 1. `lib/features/qr_scan/presentation/pages/qr_scan_page.dart`
**状態**: 使用中（エイリアスとして機能）

**理由**:
- `QrScanPage`は`QrScanPageNew`へのエイリアス
- 他のファイルから`QRScanPage`として参照される可能性があるため、残しておく

---

## Admin関連ファイル（削除不要）

以下のファイルは Admin Web (`lib/main_admin.dart`) で使用されているため、削除不要です：

- `lib/admin/presentation/pages/admin_main_page.dart`
- `lib/admin/presentation/pages/points_admin_page.dart`
- `lib/admin/presentation/pages/reservations_admin_page.dart`
- `lib/admin/presentation/pages/members_admin_page.dart`
- `lib/admin/data/repositories/admin_points_repository.dart`
- `lib/admin/data/repositories/admin_user_repository.dart`
- `lib/admin/domain/models/service_menu.dart`
- `lib/admin/domain/models/member_search_result.dart`

---

## 試作・サンプルファイル

検索結果:
- `*_old.dart`: 0件
- `*_demo.dart`: 0件
- `*_sample.dart`: 0件

**結論**: 試作・サンプルファイルは見つかりませんでした。

---

## 推奨アクション

1. **`improved_home_page.dart`の確認**
   - 実際に使用されているか確認
   - 使用されていない場合は削除を検討

2. **その他のファイル**
   - 現時点では削除候補は`improved_home_page.dart`のみ
   - 他のファイルはすべて使用中または将来の拡張のために必要

---

## 確認コマンド

```bash
# improved_home_page.dartの使用箇所を確認
grep -r "improved_home_page\|ImprovedHomePage" lib/ test/

# すべての.dartファイルをリスト
find lib -name "*.dart" -type f | sort
```

