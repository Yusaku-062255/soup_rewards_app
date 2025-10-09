## 🚀 SOUP Rewardsアプリ VS Code開発環境セットアップガイド

お待たせいたしました！SOUP RewardsアプリのVS Codeでの開発準備が完了しました。
このガイドに従って、あなたのMacでアプリを動かしてみましょう。

### 🎯 現在の状況

- **GitHubリポジトリ**: [Yusaku-062255/soup_rewards_app](https://github.com/Yusaku-062255/soup_rewards_app)
- **開発状況**: VS CodeでUI確認・編集・テストが可能な状態
- **実装済み機能**:
    - 5画面構成（ホーム/クーポン/QR/ポイント/プロフィール）
    - SOUPブランド準拠のUIデザイン
    - Material3対応テーマシステム
    - Firebase, Riverpod連携準備完了

--- 

### 🛠️ Step 1: プロジェクトをMacにクローン

まず、ターミナルを開いて、開発用フォルダ（例: `~/kanamurayusaku`）に移動し、GitHubからプロジェクトをクローンします。

```bash
# 開発用フォルダに移動
cd ~/kanamurayusaku

# 既存のプロジェクトがあれば削除（念のため）
rm -rf soup_rewards_app

# GitHubから最新版をクローン
gh repo clone Yusaku-062255/soup_rewards_app

# プロジェクトフォルダに移動
cd soup_rewards_app
```

### 📦 Step 2: VS Codeでプロジェクトを開く

クローンしたプロジェクトをVS Codeで開きます。

```bash
# VS Codeでプロジェクトを開く
code .
```

#### 必要なVS Code拡張機能

もしインストールしていない場合は、VS Codeの拡張機能マーケットプレイスから以下をインストールしてください。

1.  **Flutter**: [Dart Code - Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
2.  **Dart**: [Dart Code - Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart)

--- 

### ⚙️ Step 3: 依存関係のインストール

VS Codeの統合ターミナル（`表示` > `ターミナル`）を開き、以下のコマンドを実行して、プロジェクトに必要なパッケージをすべてインストールします。

```bash
# Flutterパッケージを取得
flutter pub get
```

コンソールに「Got dependencies!」と表示されれば成功です。

--- 

### 📱 Step 4: アプリの実行と確認

いよいよアプリを実行します。VS Codeの右下にあるデバイス選択メニューから、起動したいシミュレータ（例: `iPhone 15 Pro`）または接続した実機を選びます。

その後、以下のいずれかの方法でアプリを起動してください。

- **方法1: F5キーを押す**
- **方法2: `実行` > `デバッグの開始` をクリック**
- **方法3: ターミナルでコマンド実行**
    ```bash
    flutter run
    ```

初回ビルドには数分かかる場合があります。ビルドが成功すると、選択したiPhoneシミュレータまたは実機で **SOUP Rewardsアプリが起動します！**

#### ✅ 確認できること

- **SOUPブランドカラー**の美しいUI
- **5つのタブ**（ホーム、クーポン、QRスキャン、ポイント、マイページ）が動作すること
- **ホームページ**にポイントカードやニュースが表示されること

--- 

### 📂 プロジェクト構造（`lib`フォルダ）

VS Codeのファイルエクスプローラーで、以下の構造を確認できます。

```
lib/
├── core/               # アプリ共通のコア機能（テーマ、定数）
│   ├── constants/
│   ├── theme/
│   └── utils/
├── features/           # 各機能ごとのフォルダ
│   ├── home/
│   ├── coupon/
│   ├── qr_scan/
│   ├── points/
│   └── profile/
├── shared/             # 複数機能で共有されるウィジェット等
│   ├── models/
│   ├── services/
│   └── widgets/
└── main.dart           # アプリの起動ファイル
```

### 🎨 デザインやテキストの編集

- **色**: `lib/core/theme/app_colors.dart`
- **テーマ**: `lib/core/theme/app_theme.dart`
- **ホームページUI**: `lib/features/home/presentation/pages/home_page.dart`

これらのファイルを編集してホットリロード（`⌘+S` または `Ctrl+S`）をかければ、即座に変更がアプリに反映されます。

--- 

これで、あなたのMacのVS CodeでSOUP Rewardsアプリを自由に開発・編集できる状態になりました！
