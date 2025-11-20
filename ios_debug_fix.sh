#!/bin/bash
# iOS デバッグタイムアウト問題の修正スクリプト

echo "🔧 iOS デバッグ問題を修正中..."

# 1. Xcode を強制終了
echo "📱 Xcode を終了中..."
killall Xcode 2>/dev/null || true
killall com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
sleep 2

# 2. ビルドキャッシュのクリア
echo "🗑️  ビルドキャッシュをクリア中..."
cd "$(dirname "$0")"
flutter clean
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. 依存関係の再インストール
echo "📦 依存関係を再インストール中..."
flutter pub get
cd ios && pod install && cd ..

# 4. 完了
echo "✅ 修正完了！"
echo ""
echo "次のステップ:"
echo "1. Xcodeを開く: open ios/Runner.xcworkspace"
echo "2. デバイスが接続され、信頼されていることを確認"
echo "3. Product > Clean Build Folder (Shift+Cmd+K)"
echo "4. Product > Run (Cmd+R) または flutter run"
echo ""
echo "⚠️  重要な確認事項:"
echo "- デバイスがMacを信頼しているか（デバイス上で承認）"
echo "- システム環境設定 > プライバシーとセキュリティ > オートメーション で Xcode が許可されているか"
echo "- Xcode > Preferences > Accounts で開発チーム (JCK8C4LKG3) が正しく設定されているか"
