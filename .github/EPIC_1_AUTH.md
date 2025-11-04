# Epic 1: 認証 & プロフィール管理

## 🎯 目的

- 匿名認証で即座にアプリ利用開始
- Apple Sign-In / Email でアカウントリンク（匿名→永続化）
- プロフィール編集（表示名、アバター、通知設定）
- アカウント削除機能

## 📊 非機能要件

- **セキュリティ**: Email確認必須、パスワード強度チェック
- **パフォーマンス**: 認証状態の取得 < 500ms
- **可用性**: Firebase Authのオフライン対応
- **UX**: 認証フロー3タップ以内

## 🗄️ Firestoreコレクション設計

### `users/{userId}`

```typescript
interface User {
  // 必須フィールド
  uid: string;                      // Firebase Auth UID
  createdAt: Timestamp;             // アカウント作成日時
  updatedAt: Timestamp;             // 最終更新日時

  // プロフィール（任意）
  displayName?: string;             // 表示名（3-20文字）
  photoURL?: string;                // アバター画像URL
  email?: string;                   // メールアドレス（非匿名のみ）
  phoneNumber?: string;             // 電話番号

  // 認証関連
  isAnonymous: boolean;             // 匿名アカウントか
  authProviders: string[];          // ['anonymous'] or ['apple.com', 'password']
  emailVerified: boolean;           // メール確認済みか

  // 設定
  notificationEnabled: boolean;     // PUSH通知ON/OFF
  notificationToken?: string;       // OneSignal Player ID
  locale: string;                   // 'ja-JP'

  // 統計（読み取り専用、Functions経由で更新）
  totalPoints: number;              // 合計ポイント
  totalBookings: number;            // 予約回数
  totalGachaPlays: number;          // ガチャ実行回数
  lastLoginAt: Timestamp;           // 最終ログイン

  // ソフトデリート
  deletedAt?: Timestamp;            // 削除日時（30日後に物理削除）
}
```

### インデックス
```json
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "email", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### TTL
- `deletedAt` が設定されているドキュメントは30日後に物理削除（Cloud Scheduler）

## 🔐 Firestoreセキュリティルール差分

```javascript
// firestore.rules に追加

match /users/{userId} {
  // 読み取り: 本人のみ
  allow read: if isOwner(userId);

  // 作成: 本人のみ（初回登録時）
  allow create: if isOwner(userId)
    && request.resource.data.uid == userId
    && request.resource.data.createdAt == request.time
    && request.resource.data.keys().hasAll(['uid', 'createdAt', 'isAnonymous', 'authProviders'])
    && request.resource.data.isAnonymous is bool
    && request.resource.data.authProviders is list;

  // 更新: 本人のみ（特定フィールドのみ変更可能）
  allow update: if isOwner(userId)
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['uid', 'createdAt', 'totalPoints', 'totalBookings', 'totalGachaPlays'])
    && request.resource.data.updatedAt == request.time;

  // 削除: 本人のみ（論理削除のみ、物理削除は禁止）
  allow delete: if false;
}
```

## ☁️ Cloud Functions

### `functions/src/auth.ts`

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const region = "asia-northeast1";

/**
 * ユーザー作成時のトリガー
 * - Firestoreにユーザードキュメント自動作成
 */
export const onUserCreate = functions
  .region(region)
  .auth.user()
  .onCreate(async (user) => {
    const { uid, email, displayName, photoURL, providerData } = user;
    const isAnonymous = user.providerData.length === 0;
    const authProviders = isAnonymous
      ? ["anonymous"]
      : providerData.map((p) => p?.providerId).filter(Boolean);

    await admin.firestore().collection("users").doc(uid).set({
      uid,
      email: email || null,
      displayName: displayName || null,
      photoURL: photoURL || null,
      isAnonymous,
      authProviders,
      emailVerified: user.emailVerified || false,
      notificationEnabled: true,
      locale: "ja-JP",
      totalPoints: 0,
      totalBookings: 0,
      totalGachaPlays: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

/**
 * ユーザー削除時のトリガー
 * - 論理削除から30日後の物理削除
 */
export const onUserDelete = functions
  .region(region)
  .auth.user()
  .onDelete(async (user) => {
    const { uid } = user;

    // 関連データの削除（サブコレクション含む）
    const batch = admin.firestore().batch();

    // users/{uid} 削除
    batch.delete(admin.firestore().collection("users").doc(uid));

    // サブコレクション削除
    const collections = ["points", "pointLedger", "coupons", "gachaClaims"];
    for (const collectionName of collections) {
      const snapshot = await admin.firestore()
        .collection("users")
        .doc(uid)
        .collection(collectionName)
        .get();

      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    }

    // bookings の userId フィルタで削除
    const bookingsSnapshot = await admin.firestore()
      .collection("bookings")
      .where("userId", "==", uid)
      .get();

    bookingsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();

    functions.logger.info(`User ${uid} and related data deleted`);
  });

/**
 * アカウントリンク後のプロフィール更新
 */
export const updateProfileAfterLink = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    const user = await admin.auth().getUser(uid);
    const { email, displayName, photoURL, providerData, emailVerified } = user;
    const isAnonymous = providerData.length === 0;
    const authProviders = isAnonymous
      ? ["anonymous"]
      : providerData.map((p) => p?.providerId).filter(Boolean);

    await admin.firestore().collection("users").doc(uid).update({
      email: email || null,
      displayName: displayName || null,
      photoURL: photoURL || null,
      isAnonymous,
      authProviders,
      emailVerified,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true };
  });

/**
 * アカウント論理削除（即座に削除せず30日間保持）
 */
export const softDeleteAccount = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }

    // 論理削除フラグを設定
    await admin.firestore().collection("users").doc(uid).update({
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 30日後に物理削除をスケジュール（Cloud Scheduler + Pub/Sub）
    // ここでは即座に Firebase Auth からは削除しない（復元可能期間）

    return { ok: true, message: "Account will be deleted in 30 days" };
  });
```

### `functions/src/schedulers.ts`

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const region = "asia-northeast1";

/**
 * 毎日実行: 論理削除から30日経過したアカウントを物理削除
 */
export const cleanupDeletedAccounts = functions
  .region(region)
  .pubsub.schedule("0 3 * * *") // JST 03:00（UTC 18:00前日）
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 30 * 24 * 60 * 60 * 1000
    );

    const snapshot = await admin.firestore()
      .collection("users")
      .where("deletedAt", "<=", thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    const uidsToDelete: string[] = [];

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      uidsToDelete.push(doc.id);
    });

    await batch.commit();

    // Firebase Auth からも削除
    for (const uid of uidsToDelete) {
      try {
        await admin.auth().deleteUser(uid);
      } catch (error) {
        functions.logger.error(`Failed to delete user ${uid} from Auth`, error);
      }
    }

    functions.logger.info(`Cleaned up ${uidsToDelete.length} deleted accounts`);
  });
```

## 🎨 Flutter実装

### ディレクトリ構造

```
lib/
├── features/
│   └── auth/
│       ├── domain/
│       │   └── models/
│       │       └── app_user.dart          # Userモデル
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository.dart   # 認証リポジトリ
│       └── presentation/
│           ├── providers/
│           │   ├── auth_state_provider.dart
│           │   └── user_profile_provider.dart
│           ├── pages/
│           │   ├── login_page.dart
│           │   ├── signup_page.dart
│           │   ├── profile_page.dart
│           │   └── account_settings_page.dart
│           └── widgets/
│               ├── apple_sign_in_button.dart
│               ├── email_form.dart
│               └── profile_avatar.dart
```

### `lib/features/auth/domain/models/app_user.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required bool isAnonymous,
    required List<String> authProviders,
    required bool emailVerified,
    required bool notificationEnabled,
    required String locale,
    required int totalPoints,
    required int totalBookings,
    required int totalGachaPlays,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime lastLoginAt,
    String? displayName,
    String? photoURL,
    String? email,
    String? phoneNumber,
    String? notificationToken,
    DateTime? deletedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      isAnonymous: data['isAnonymous'] as bool,
      authProviders: List<String>.from(data['authProviders'] as List),
      emailVerified: data['emailVerified'] as bool,
      notificationEnabled: data['notificationEnabled'] as bool,
      locale: data['locale'] as String,
      totalPoints: data['totalPoints'] as int,
      totalBookings: data['totalBookings'] as int,
      totalGachaPlays: data['totalGachaPlays'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      notificationToken: data['notificationToken'] as String?,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
```

### `lib/features/auth/data/repositories/auth_repository.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../domain/models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(region: 'asia-northeast1'),
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.functions,
  });

  /// 認証状態のストリーム
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// 現在のユーザー
  User? get currentUser => auth.currentUser;

  /// AppUserのストリーム
  Stream<AppUser?> userStream(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// 匿名ログイン
  Future<UserCredential> signInAnonymously() async {
    return await auth.signInAnonymously();
  }

  /// Apple Sign-In（匿名アカウントにリンク）
  Future<UserCredential> signInWithApple({bool link = false}) async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    UserCredential userCredential;
    if (link && currentUser != null && currentUser!.isAnonymous) {
      // 匿名アカウントにリンク
      userCredential = await currentUser!.linkWithCredential(oauthCredential);
    } else {
      // 新規サインイン
      userCredential = await auth.signInWithCredential(oauthCredential);
    }

    // プロフィール更新
    await updateProfileAfterLink();

    return userCredential;
  }

  /// Emailでサインアップ（匿名アカウントにリンク）
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    bool link = false,
  }) async {
    final emailCredential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    UserCredential userCredential;
    if (link && currentUser != null && currentUser!.isAnonymous) {
      // 匿名アカウントにリンク
      userCredential = await currentUser!.linkWithCredential(emailCredential);
    } else {
      // 新規サインアップ
      userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    // メール確認送信
    await userCredential.user?.sendEmailVerification();

    // プロフィール更新
    await updateProfileAfterLink();

    return userCredential;
  }

  /// Emailでログイン
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// サインアウト
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// プロフィール更新（Callable Function）
  Future<void> updateProfileAfterLink() async {
    final callable = functions.httpsCallable('updateProfileAfterLink');
    await callable.call();
  }

  /// プロフィール編集
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (currentUser == null) return;

    // Firebase Auth更新
    await currentUser!.updateDisplayName(displayName);
    await currentUser!.updatePhotoURL(photoURL);

    // Firestore更新
    await firestore.collection('users').doc(currentUser!.uid).update({
      'displayName': displayName,
      'photoURL': photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 通知設定更新
  Future<void> updateNotificationSettings({
    required bool enabled,
    String? token,
  }) async {
    if (currentUser == null) return;

    await firestore.collection('users').doc(currentUser!.uid).update({
      'notificationEnabled': enabled,
      if (token != null) 'notificationToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// アカウント削除（論理削除）
  Future<void> deleteAccount() async {
    final callable = functions.httpsCallable('softDeleteAccount');
    await callable.call();
  }
}
```

### `lib/features/auth/presentation/providers/auth_state_provider.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

/// 認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// 現在のユーザーIDプロバイダー
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// AppUserプロバイダー
final appUserProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value(null);
  }
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.userStream(userId);
});
```

### `lib/features/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design/theme.dart';
import '../../data/repositories/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceHeading),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                CupertinoIcons.car_detailed,
                size: 80,
                color: DesignTokens.primary,
              ),
              const SizedBox(height: DesignTokens.spaceBase),
              Text(
                'SOUP Rewards',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              Text(
                'カーケアポイントプログラム',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceLarge * 2),

              // 匿名ログインボタン
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInAnonymously,
                icon: Icon(CupertinoIcons.play_circle),
                label: Text('今すぐ始める（ゲスト）'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceBase),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceBase),

              // Apple Sign-Inボタン
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithApple,
                icon: Icon(CupertinoIcons.logo_apple),
                label: Text('Appleでサインイン'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceBase),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceBase),

              // Emailサインインボタン
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () {
                  // Navigate to email sign-in page
                },
                icon: Icon(CupertinoIcons.mail),
                label: Text('メールアドレスでサインイン'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceBase),
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceSection),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInAnonymously();
      // Navigate to main page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple(link: false);
      // Navigate to main page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appleサインインに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

## 🧪 テスト

### Unit Test: `test/features/auth/data/repositories/auth_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('AuthRepository', () {
    test('signInAnonymously creates anonymous user', () async {
      // TODO: Mock FirebaseAuth and test
    });

    test('signInWithApple links to anonymous account', () async {
      // TODO: Test account linking
    });

    test('updateProfile updates Firestore and Auth', () async {
      // TODO: Test profile update
    });
  });
}
```

### Widget Test: `test/features/auth/presentation/pages/login_page_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('LoginPage displays all sign-in options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.text('今すぐ始める（ゲスト）'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
    expect(find.text('メールアドレスでサインイン'), findsOneWidget);
  });
}
```

## 📋 Acceptance Criteria

- [ ] 匿名ログインでアプリ起動後3秒以内に利用開始できる
- [ ] Apple Sign-Inで匿名アカウントから永続アカウントにシームレスに移行できる
- [ ] Emailサインアップ時にメール確認リンクが送信される
- [ ] プロフィール編集で表示名・アバターを変更できる
- [ ] 通知設定のON/OFFが即座に反映される
- [ ] アカウント削除後30日間は復元可能（論理削除）
- [ ] 30日経過後に自動的に物理削除される
- [ ] 削除されたアカウントのポイント・予約・クーポンも全て削除される

## 🎨 UIワイヤーフロー

```
[Splash Screen]
      ↓
[Login Page] ←─────────┐
  ├─ 今すぐ始める      │
  │    ↓              │
  │  [Home] (匿名)    │
  │    ↓              │
  │  [Profile]        │
  │    └─ アカウントリンク促進
  │         ↓          │
  ├─ Appleサインイン   │
  │    ↓              │
  │  [Home] (永続)    │
  │                   │
  └─ Emailサインイン   │
       ↓              │
     [Signup Page]    │
       ↓              │
     [Email確認待ち]   │
       ↓              │
     [Home] (永続)    │
       ↓              │
     [Profile Page]   │
       ├─ 表示名編集
       ├─ アバター変更
       ├─ 通知設定
       └─ アカウント削除 ─→ [確認ダイアログ] ─→ [ログアウト]
```

## 📦 デプロイ手順

```bash
# 1. ブランチ作成
git checkout develop
git pull origin develop
git checkout -b feature/epic-1-auth

# 2. Cloud Functions実装
cd functions
npm install

# 新規ファイル追加
# - src/auth.ts
# - src/schedulers.ts

# index.tsにexport追加
# export * from './auth';
# export * from './schedulers';

# ローカルテスト
npm run serve

# デプロイ
npm run deploy

# 3. Firestoreルール更新
firebase deploy --only firestore:rules

# 4. Cloud Scheduler設定（初回のみ）
gcloud scheduler jobs create pubsub cleanup-deleted-accounts \
  --schedule="0 3 * * *" \
  --time-zone="Asia/Tokyo" \
  --topic="cleanup-deleted-accounts" \
  --location="asia-northeast1"

# 5. Flutter実装
cd ..
flutter pub add freezed_annotation json_annotation sign_in_with_apple
flutter pub add --dev freezed json_serializable build_runner

# コード生成
flutter pub run build_runner build --delete-conflicting-outputs

# テスト
flutter test

# 6. コミット
git add .
git commit -m "feat(auth): Implement anonymous auth and Apple Sign-In with account linking"

# 7. プッシュ&PR作成
git push -u origin feature/epic-1-auth
gh pr create --base develop --title "Epic 1: Authentication & Profile"
```

## ⏱️ CI/CD手順（GitHub Actions）

### `.github/workflows/epic-1-ci.yml`

```yaml
name: Epic 1 CI

on:
  pull_request:
    branches: [develop]
    paths:
      - 'lib/features/auth/**'
      - 'functions/src/auth.ts'
      - 'functions/src/schedulers.ts'

jobs:
  test-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install dependencies
        run: cd functions && npm ci

      - name: Run ESLint
        run: cd functions && npm run lint

      - name: Run tests
        run: cd functions && npm test

    timeout-minutes: 10

  test-flutter:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

    timeout-minutes: 15
```

## 📝 所要時間目安

- **設計・レビュー**: 2時間
- **Functions実装**: 3時間
- **Flutter実装**: 6時間
- **テスト実装**: 3時間
- **統合テスト**: 2時間
- **PR作成・レビュー**: 1時間

**合計**: 約17時間（2-3日）
