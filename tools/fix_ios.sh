#!/usr/bin/env bash
set -e

echo "🧹 Clean & regenerate lock"
rm -f pubspec.lock
flutter clean
flutter pub get

echo "📦 CocoaPods setup"
cd ios
pod repo update
pod install
cd ..

echo "🔍 Quality checks"
flutter analyze
flutter test

echo "✅ Ready! Try: flutter run -d <device>"
echo "📱 Available devices:"
flutter devices
