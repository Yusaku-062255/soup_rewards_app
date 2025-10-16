#!/bin/bash

# プロジェクトディレクトリに移動（スクリプトの場所を基準）
cd "$(dirname "$0")"

echo "🧪 SOUP Rewards App - テスト実行"
echo "================================"

# 依存関係の取得
echo "📦 依存関係を取得中..."
flutter pub get

# 静的解析
echo "🔍 静的解析を実行中..."
flutter analyze

# テスト実行
echo "🧪 テストを実行中..."
flutter test

echo "✅ すべてのテストが完了しました"
