# 🔍 Sentry セットアップ手順書

**SOUP Rewards App** のエラー監視・パフォーマンス計測のためのSentry統合手順です。

## 📋 前提条件

- Sentryアカウント（無料プラン可）
- Flutter SDK 3.4.0以上

---

## 🚀 セットアップ手順

### Step 1: Sentryプロジェクト作成

1. [Sentry.io](https://sentry.io/) にアクセス
2. 「Create Project」をクリック
3. プラットフォーム: **Flutter** を選択
4. プロジェクト名: `soup-rewards-app`
5. **DSN（Data Source Name）** をコピー
   - 形式: `https://xxxxxxxxxxxxxxxxxxxxxxxxxxxx@o123456.ingest.sentry.io/7654321`

---

### Step 2: pubspec.yaml に依存関係追加

すでに追加済み：

```yaml
dependencies:
  sentry_flutter: ^7.18.0
```

```bash
flutter pub get
```

---

### Step 3: main.dart を Sentry統合版に置き換え

#### オプション1: 既存のmain.dartを更新

```bash
# バックアップ
cp lib/main.dart lib/main_original.dart

# Sentry統合版をコピー
cp lib/main_with_sentry.dart lib/main.dart
```

#### オプション2: main.dartを手動編集

`lib/main.dart` に以下を追加：

```dart
import 'core/services/sentry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry初期化
  await SentryService.initialize();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Flutterエラーハンドラー
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SentryService.captureException(
      details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(const ProviderScope(child: SoupRewardsApp()));
}
```

---

### Step 4: 環境変数でDSNを注入

#### 開発環境

```bash
flutter run --dart-define=SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

#### VS Code (.vscode/launch.json)

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dev (with Sentry)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FLAVOR=development",
        "--dart-define=SENTRY_DSN=https://your-dev-dsn@sentry.io/123456"
      ]
    },
    {
      "name": "Production (with Sentry)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FLAVOR=production",
        "--dart-define=SENTRY_DSN=https://your-prod-dsn@sentry.io/654321"
      ]
    }
  ]
}
```

#### GitHub Actions

`.github/workflows/ci.yml` に追加：

```yaml
env:
  SENTRY_DSN: ${{ secrets.SENTRY_DSN }}

steps:
  - name: Build with Sentry
    run: |
      flutter build apk \
        --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }} \
        --dart-define=FLAVOR=production
```

**GitHub Secrets に登録**:
1. リポジトリ → Settings → Secrets and variables → Actions
2. **New repository secret**
3. Name: `SENTRY_DSN`, Value: `https://...`

---

### Step 5: エラー監視の使い方

#### 自動キャプチャ

```dart
// Flutterフレームワークエラーは自動送信
throw Exception('This will be captured automatically');
```

#### 手動キャプチャ

```dart
import 'package:soup_rewards_app/core/services/sentry_service.dart';

try {
  // 危険な処理
  await riskyOperation();
} catch (e, stackTrace) {
  // Sentryに送信
  await SentryService.captureException(
    e,
    stackTrace: stackTrace,
    hint: 'Failed to load user data',
  );
}
```

#### メッセージ送信

```dart
// 情報レベル
SentryService.captureMessage('User logged in', level: SentryLevel.info);

// 警告レベル
SentryService.captureMessage('API rate limit approaching', level: SentryLevel.warning);

// エラーレベル
SentryService.captureMessage('Payment failed', level: SentryLevel.error);
```

#### ユーザー情報設定

```dart
// ログイン時
SentryService.setUser(
  userId: user.uid,
  email: user.email,
  username: user.displayName,
);

// ログアウト時
SentryService.clearUser();
```

#### ブレッドクラム（ユーザー行動トラッキング）

```dart
// 画面遷移
SentryService.addBreadcrumb(
  message: 'Navigated to Points Page',
  category: 'navigation',
  level: SentryLevel.info,
);

// ボタンタップ
SentryService.addBreadcrumb(
  message: 'Tapped on QR Scan button',
  category: 'ui.click',
  data: {'button': 'qr_scan'},
);

// API呼び出し
SentryService.addBreadcrumb(
  message: 'API request to /api/points',
  category: 'http',
  data: {'method': 'GET', 'url': '/api/points'},
);
```

#### パフォーマンス計測

```dart
final transaction = SentryService.startTransaction(
  'load_user_data',
  'http.client',
);

try {
  // 計測対象の処理
  await loadUserData();
  transaction.status = const SpanStatus.ok();
} catch (e) {
  transaction.status = const SpanStatus.internalError();
  rethrow;
} finally {
  await transaction.finish();
}
```

---

### Step 6: 実装例

#### Providerでのエラーハンドリング

```dart
// lib/core/providers/app_providers.dart
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState.initial);

  Future<void> signIn(String email, String password) async {
    state = AuthState.loading;
    try {
      // Firebase Auth実装
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AuthState.authenticated;

      // Sentryにユーザー情報設定
      final user = FirebaseAuth.instance.currentUser!;
      SentryService.setUser(
        userId: user.uid,
        email: user.email,
      );

      // 成功のブレッドクラム
      SentryService.addBreadcrumb(
        message: 'User signed in successfully',
        category: 'auth',
      );
    } catch (e, stackTrace) {
      state = AuthState.error;

      // Sentryにエラー送信
      await SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Sign-in failed for $email',
      );
    }
  }
}
```

---

## 📊 Sentryダッシュボード確認

### エラー一覧

1. Sentry.io → プロジェクト → **Issues**
2. エラーの詳細確認:
   - スタックトレース
   - ユーザー情報
   - デバイス情報
   - ブレッドクラム（エラー前の行動履歴）

### パフォーマンス

1. Sentry.io → **Performance**
2. トランザクション一覧:
   - レスポンスタイム
   - スループット
   - エラー率

### リリース追跡

1. Sentry.io → **Releases**
2. バージョン別エラー発生率の確認

---

## 🔐 セキュリティ設定

### センシティブデータの除外

`lib/core/services/sentry_service.dart` の `beforeSend` で設定済み：

```dart
options.beforeSend = (event, hint) {
  // パスワード・トークンを除外
  if (event.request?.data != null) {
    final data = event.request!.data as Map<String, dynamic>?;
    data?.remove('password');
    data?.remove('token');
    data?.remove('api_key');
  }
  return event;
};
```

---

## 🧪 テスト

### エラーキャプチャのテスト

```dart
// テスト用エラーを投げる
ElevatedButton(
  onPressed: () {
    throw Exception('Test error for Sentry');
  },
  child: Text('Test Sentry'),
),
```

Sentryダッシュボードで確認（数秒～数分で反映）

---

## 📚 参考リンク

- [Sentry Flutter SDK](https://docs.sentry.io/platforms/flutter/)
- [Sentry Dashboard](https://sentry.io/)
- [Best Practices](https://docs.sentry.io/platforms/flutter/best-practices/)

---

**次のステップ**: Firestore セキュリティルール設定
