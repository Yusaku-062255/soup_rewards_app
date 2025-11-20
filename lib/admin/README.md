# SOUP Admin - 管理画面

スタッフ用のWeb管理画面です。

## 📋 概要

SOUP Rewardsアプリの管理機能を提供するFlutter Webアプリケーションです。
同じFirebase/Firestoreプロジェクトを使用し、スタッフが会員管理やポイント付与を行うことができます。

## 🚀 実行方法

### 開発環境での実行

```bash
# Chromeで実行
flutter run -d chrome --target=lib/main_admin.dart

# または特定のポートで実行
flutter run -d chrome --target=lib/main_admin.dart --web-port=8080
```

### ビルド

```bash
# Webビルド
flutter build web --target=lib/main_admin.dart

# ビルド出力は build/web/ に生成されます
```

### Firebase Hostingへのデプロイ（将来）

```bash
# Firebase Hostingにデプロイ
firebase deploy --only hosting:admin
```

## 📁 ディレクトリ構成

```
lib/admin/
├── domain/
│   └── models/
│       ├── service_menu.dart          # サービスメニュー定義
│       └── member_search_result.dart  # 会員検索結果モデル
├── data/
│   └── repositories/
│       ├── admin_user_repository.dart    # 管理画面用ユーザーリポジトリ
│       └── admin_points_repository.dart  # 管理画面用ポイントリポジトリ
└── presentation/
    └── pages/
        ├── admin_main_page.dart          # メインページ（ナビゲーション）
        ├── points_admin_page.dart        # ポイント付与画面
        ├── reservations_admin_page.dart   # 予約一覧画面
        └── members_admin_page.dart        # 会員検索＆詳細画面
```

## 🎯 機能

### 1. ポイント付与画面

- 会員ID（6桁）で会員を検索
- 会員情報の表示（会員ID、現在ポイント、ランク、名前）
- サービスメニュー選択（洗車ライト、洗車プレミアム、コーティングライト、コーティングスタンダード、コーティングプレミアム、セラミックフル）
- ポイント付与処理（Firestoreへの書き込み + 取引履歴の追加）

### 2. 予約一覧画面（ひな型）

- フィルター機能（今日、今週、全て）
- 日付ピッカー
- 予約一覧表示（時間、名前、メニュー、ステータス）

**TODO:**
- Firestoreの`reservations`コレクションからの読み取り実装
- 予約ステータスの更新機能

### 3. 会員検索＆詳細画面（ひな型）

- 検索条件（会員ID、名前、電話番号）
- 検索結果一覧表示
- 会員詳細表示（基本情報、ポイント・ランク情報、取引履歴）

**TODO:**
- 最終来店日の取得実装
- 累計利用回数の正確な計算
- 車情報の表示

## 🔥 Firestoreスキーマ

### 既存のコレクション

#### `users/{userId}`

**管理画面用に追加されたフィールド:**
- `lastVisitDate: Timestamp` - 最終来店日（ポイント付与時に更新）
- `visitCount: number` - 累計来店回数（ポイント付与時に +1）
- `memberId: string` - 6桁の会員ID（検索用インデックス）

**更新タイミング:**
- `lastVisitDate` / `visitCount` は `AdminPointsRepository.grantPoints()` 実行時にトランザクション内で更新されます
- モバイルアプリ側の `FirestorePointsRepository` には影響しません

#### `users/{userId}`
```typescript
{
  shopId: string;
  points: number;
  lastDailyDrawAt: Timestamp?;
  todayDrawPoints: number?;
  // 既存のUserModelのフィールド
  name: string;
  email: string;
  phoneNumber?: string;
  membershipLevel: string;
  createdAt: Timestamp;
  updatedAt?: Timestamp;
}
```

#### `transactions/{transactionId}`
```typescript
{
  userId: string;
  type: 'earn' | 'redeem';
  points: number;
  description: string;
  storeId?: string;
  timestamp: Timestamp;
}
```

### 新規コレクション

#### `reservations/{reservationId}`

予約情報を管理するコレクション（実装済み）

**フィールド:**
- `userId?: string` - 会員ID（オプション）
- `name: string` - 予約者名
- `phoneNumber?: string` - 電話番号
- `menu: string` - メニュー名
- `status: string` - ステータス（'予約' | '施工中' | '完了' | 'キャンセル'）
- `scheduledDate: Timestamp` - 予約日時
- `createdAt: Timestamp` - 作成日時
- `updatedAt?: Timestamp` - 更新日時

**インデックス:**
- `scheduledDate` フィールドに単一フィールドインデックスが必要
- `status` + `scheduledDate` の複合インデックス（ステータスフィルター用）
- `userId` + `scheduledDate` の複合インデックス（会員予約の場合）

詳細は `FIRESTORE_SCHEMA.md` を参照してください。
```typescript
{
  userId: string;
  name: string;
  phoneNumber?: string;
  menu: string;
  status: '予約' | '施工中' | '完了';
  scheduledDate: Timestamp;
  createdAt: Timestamp;
  updatedAt?: Timestamp;
}
```

### ポイント付与のトランザクション処理

`AdminPointsRepository.grantPoints()` は Firestore のトランザクションを使用して、以下の処理を原子的に実行します:

1. `users/{userId}` の `points` フィールドを加算
2. `lastVisitDate` を更新（今回の付与時間）
3. `visitCount` を +1
4. `transactions` コレクションに取引履歴を追加

これにより、複数端末から同時に操作されても、ポイントが競合せず原子的に更新されます。

## 🔐 セキュリティルール（将来実装）

管理画面はスタッフ専用のため、適切な認証と権限管理が必要です。

### 推奨実装

1. **Firebase Authentication**
   - スタッフ用のメール/パスワード認証
   - カスタムクレームで「admin」ロールを付与

2. **Firestoreセキュリティルール**
   ```javascript
   match /users/{userId} {
     // 管理者のみ読み書き可能
     allow read, write: if request.auth != null && 
       request.auth.token.admin == true;
   }
   
   match /transactions/{transactionId} {
     // 管理者のみ作成可能
     allow create: if request.auth != null && 
       request.auth.token.admin == true;
   }
   ```

## 📝 TODO

### 高優先度
- [x] ポイント付与のトランザクション処理実装
- [x] 来店情報（lastVisitDate / visitCount）の更新ロジック実装
- [x] MembersAdminPageのFirestore連携（検索 & 詳細）
- [x] ReservationsAdminPageのFirestore連携（一覧表示）
- [ ] 会員ID検索のインデックス作成とデプロイ

### 中優先度
- [ ] スタッフ認証の実装
- [ ] Firestoreセキュリティルールの更新
- [ ] 予約ステータスの更新機能
- [ ] エラーハンドリングの強化
- [ ] ローディング状態の改善

### 低優先度
- [ ] 車情報の表示
- [ ] 統計情報の表示
- [ ] エクスポート機能
- [ ] 名前検索の最適化（Algoliaなどの全文検索サービス）

## 🛠️ 技術スタック

- Flutter Web
- Firebase (Firestore, Authentication)
- Riverpod (状態管理)
- 既存のモデル・リポジトリの再利用

## 📚 関連ドキュメント

- [Firestoreスキーマ設計](./FIRESTORE_SCHEMA.md) (TODO: 作成)
- [認証・権限管理](./AUTH.md) (TODO: 作成)

