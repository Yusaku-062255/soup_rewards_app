#!/bin/bash

# SOUP Rewards App テスト実行スクリプト

echo "=== SOUP Rewards App テスト実行 ==="
echo "日時: $(date)"
echo ""

# プロジェクトディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# テスト結果ディレクトリを作成
mkdir -p test_results

echo "1. 依存関係の確認..."
if [ -f "pubspec.yaml" ]; then
    echo "✓ pubspec.yaml が存在します"
else
    echo "✗ pubspec.yaml が見つかりません"
    exit 1
fi

echo ""
echo "2. テストファイルの確認..."
test_files=$(find test -name "*.dart" | wc -l)
echo "✓ テストファイル数: $test_files"

if [ $test_files -eq 0 ]; then
    echo "✗ テストファイルが見つかりません"
    exit 1
fi

echo ""
echo "3. テストファイル一覧:"
find test -name "*.dart" | sort

echo ""
echo "4. Dartファイルの構文チェック..."
syntax_errors=0

for file in $(find lib -name "*.dart"); do
    if ! dart analyze "$file" > /dev/null 2>&1; then
        echo "✗ 構文エラー: $file"
        syntax_errors=$((syntax_errors + 1))
    fi
done

for file in $(find test -name "*.dart"); do
    if ! dart analyze "$file" > /dev/null 2>&1; then
        echo "✗ 構文エラー: $file"
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [ $syntax_errors -eq 0 ]; then
    echo "✓ 構文チェック完了（エラーなし）"
else
    echo "✗ 構文エラーが $syntax_errors 個見つかりました"
fi

echo ""
echo "5. テストの模擬実行..."

# 各テストファイルの基本的な検証
echo ""
echo "=== テストファイル検証結果 ==="

# ポイントサービステスト
if [ -f "test/core/services/points_service_test.dart" ]; then
    echo "✓ ポイントサービステスト: 存在"
    test_count=$(grep -c "test(" test/core/services/points_service_test.dart)
    echo "  - テストケース数: $test_count"
else
    echo "✗ ポイントサービステスト: 不存在"
fi

# 車両ストアテスト
if [ -f "test/core/services/vehicle_store_test.dart" ]; then
    echo "✓ 車両ストアテスト: 存在"
    test_count=$(grep -c "test(" test/core/services/vehicle_store_test.dart)
    echo "  - テストケース数: $test_count"
else
    echo "✗ 車両ストアテスト: 不存在"
fi

# クーポンストアテスト
if [ -f "test/core/services/coupon_store_test.dart" ]; then
    echo "✓ クーポンストアテスト: 存在"
    test_count=$(grep -c "test(" test/core/services/coupon_store_test.dart)
    echo "  - テストケース数: $test_count"
else
    echo "✗ クーポンストアテスト: 不存在"
fi

# ホームページテスト
if [ -f "test/features/home/home_page_test.dart" ]; then
    echo "✓ ホームページテスト: 存在"
    test_count=$(grep -c "testWidgets(" test/features/home/home_page_test.dart)
    echo "  - ウィジェットテスト数: $test_count"
else
    echo "✗ ホームページテスト: 不存在"
fi

# 統合テスト
if [ -f "test/integration/app_integration_test.dart" ]; then
    echo "✓ 統合テスト: 存在"
    test_count=$(grep -c "testWidgets(" test/integration/app_integration_test.dart)
    echo "  - 統合テスト数: $test_count"
else
    echo "✗ 統合テスト: 不存在"
fi

echo ""
echo "6. コードカバレッジ分析..."

# ソースファイル数をカウント
lib_files=$(find lib -name "*.dart" | wc -l)
test_files=$(find test -name "*.dart" | wc -l)

echo "✓ ライブラリファイル数: $lib_files"
echo "✓ テストファイル数: $test_files"

# カバレッジ率の概算
if [ $lib_files -gt 0 ]; then
    coverage_ratio=$(echo "scale=1; $test_files * 100 / $lib_files" | bc -l 2>/dev/null || echo "計算不可")
    echo "✓ テストカバレッジ概算: ${coverage_ratio}%"
else
    echo "✗ ライブラリファイルが見つかりません"
fi

echo ""
echo "7. テスト品質評価..."

# 重要なテストパターンの確認
patterns=(
    "expect("
    "setUp("
    "tearDown("
    "group("
    "test("
    "testWidgets("
)

echo "テストパターン分析:"
for pattern in "${patterns[@]}"; do
    count=$(grep -r "$pattern" test/ | wc -l)
    echo "  - $pattern: $count 箇所"
done

echo ""
echo "8. テスト実行準備完了"
echo ""
echo "=== テスト実行サマリー ==="
echo "- プロジェクト: SOUP Rewards App"
echo "- テストファイル数: $test_files"
echo "- ライブラリファイル数: $lib_files"
echo "- 構文エラー: $syntax_errors"
echo "- 実行日時: $(date)"
echo ""

if [ $syntax_errors -eq 0 ] && [ $test_files -gt 0 ]; then
    echo "✅ テスト実行準備完了"
    echo ""
    echo "注意: 実際のFlutter環境でのテスト実行には以下のコマンドを使用してください:"
    echo "  flutter test --coverage"
    echo "  flutter test test/core/services/"
    echo "  flutter test test/features/"
    echo "  flutter test test/integration/"
    exit 0
else
    echo "❌ テスト実行準備に問題があります"
    exit 1
fi
