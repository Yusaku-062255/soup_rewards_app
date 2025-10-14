// クーポンストアサービステスト
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/models/coupon_model.dart';
import '../../../lib/core/services/coupon_store.dart';

void main() {
  group('CouponStore Tests', () {
    setUp(() async {
      // テスト前にSharedPreferencesをクリア
      SharedPreferences.setMockInitialValues({});
    });

    test('クーポンの追加と取得', () async {
      // 給油券クーポンを作成
      final coupon = CouponModel.createFuelCoupon();
      
      // クーポンを追加
      final addResult = await CouponStore.addCoupon(coupon);
      expect(addResult, true);

      // 使用可能クーポンを取得
      final availableCoupons = await CouponStore.getAvailableCoupons();
      expect(availableCoupons.length, 1);
      expect(availableCoupons.first.title, '給油券');
      expect(availableCoupons.first.cost, 5000);
      expect(availableCoupons.first.isRedeemed, false);

      // 使用済みクーポンを取得（空のはず）
      final redeemedCoupons = await CouponStore.getRedeemedCoupons();
      expect(redeemedCoupons.length, 0);
    });

    test('クーポンの使用切り替え', () async {
      // クーポンを追加
      final coupon = CouponModel.createFuelCoupon();
      await CouponStore.addCoupon(coupon);

      // 使用済みに変更
      final toggleResult = await CouponStore.toggleRedeem(coupon.id);
      expect(toggleResult, true);

      // 使用可能クーポンが0になることを確認
      final availableCoupons = await CouponStore.getAvailableCoupons();
      expect(availableCoupons.length, 0);

      // 使用済みクーポンが1になることを確認
      final redeemedCoupons = await CouponStore.getRedeemedCoupons();
      expect(redeemedCoupons.length, 1);
      expect(redeemedCoupons.first.isRedeemed, true);
      expect(redeemedCoupons.first.redeemedAt, isNotNull);

      // 再度切り替えて元に戻す
      final toggleBackResult = await CouponStore.toggleRedeem(coupon.id);
      expect(toggleBackResult, true);

      // 使用可能クーポンが1に戻ることを確認
      final availableAfterToggle = await CouponStore.getAvailableCoupons();
      expect(availableAfterToggle.length, 1);
      expect(availableAfterToggle.first.isRedeemed, false);
      expect(availableAfterToggle.first.redeemedAt, isNull);
    });

    test('存在しないクーポンの切り替え', () async {
      // 存在しないIDで切り替えを試行
      final result = await CouponStore.toggleRedeem('non-existent-id');
      expect(result, false);
    });

    test('デフォルトクーポンの初期化', () async {
      // デフォルトクーポンを初期化
      await CouponStore.initializeDefaultCoupons();

      // デフォルトクーポンが追加されることを確認
      final coupons = await CouponStore.getAvailableCoupons();
      expect(coupons.length, greaterThan(0));
      
      // 給油券が含まれることを確認
      final fuelCoupons = coupons.where((c) => c.title.contains('給油券')).toList();
      expect(fuelCoupons.length, greaterThan(0));
    });

    test('複数クーポンの管理', () async {
      // 複数のクーポンを追加
      final coupon1 = CouponModel.createFuelCoupon();
      final coupon2 = CouponModel.createFuelCoupon();
      final coupon3 = CouponModel.createFuelCoupon();

      await CouponStore.addCoupon(coupon1);
      await CouponStore.addCoupon(coupon2);
      await CouponStore.addCoupon(coupon3);

      // 全て使用可能であることを確認
      final available = await CouponStore.getAvailableCoupons();
      expect(available.length, 3);

      // 1つを使用済みに変更
      await CouponStore.toggleRedeem(coupon2.id);

      // 使用可能が2、使用済みが1になることを確認
      final availableAfter = await CouponStore.getAvailableCoupons();
      final redeemedAfter = await CouponStore.getRedeemedCoupons();
      expect(availableAfter.length, 2);
      expect(redeemedAfter.length, 1);
      expect(redeemedAfter.first.id, coupon2.id);
    });

    test('クーポンの統計情報', () async {
      // 複数のクーポンを追加し、一部を使用済みに
      final coupon1 = CouponModel.createFuelCoupon();
      final coupon2 = CouponModel.createFuelCoupon();
      
      await CouponStore.addCoupon(coupon1);
      await CouponStore.addCoupon(coupon2);
      await CouponStore.toggleRedeem(coupon1.id);

      // 統計情報を取得
      final stats = await CouponStore.getStats();
      expect(stats['totalCoupons'], 2);
      expect(stats['availableCoupons'], 1);
      expect(stats['redeemedCoupons'], 1);
      expect(stats['totalValue'], 10000); // 5000 * 2
      expect(stats['redeemedValue'], 5000); // 使用済み1つ分
    });

    test('クーポンモデルのプロパティ', () {
      // 給油券クーポンのテスト
      final fuelCoupon = CouponModel.createFuelCoupon();
      
      expect(fuelCoupon.title, '給油券');
      expect(fuelCoupon.description, '¥5,000相当・店頭でお渡し');
      expect(fuelCoupon.cost, 5000);
      expect(fuelCoupon.isRedeemed, false);
      expect(fuelCoupon.redeemedAt, isNull);
      expect(fuelCoupon.displayIssuedDate, isNotEmpty);
      expect(fuelCoupon.displayRedeemedDate, '未使用');

      // 使用済みクーポンのテスト
      final redeemedCoupon = fuelCoupon.copyWith(
        isRedeemed: true,
        redeemedAt: DateTime.now(),
      );
      
      expect(redeemedCoupon.isRedeemed, true);
      expect(redeemedCoupon.redeemedAt, isNotNull);
      expect(redeemedCoupon.displayRedeemedDate, isNot('未使用'));
    });

    test('JSON変換のテスト', () {
      // クーポンを作成
      final originalCoupon = CouponModel.createFuelCoupon();
      
      // JSONに変換
      final json = originalCoupon.toJson();
      expect(json['id'], originalCoupon.id);
      expect(json['title'], '給油券');
      expect(json['cost'], 5000);
      expect(json['isRedeemed'], false);

      // JSONから復元
      final restoredCoupon = CouponModel.fromJson(json);
      expect(restoredCoupon.id, originalCoupon.id);
      expect(restoredCoupon.title, originalCoupon.title);
      expect(restoredCoupon.cost, originalCoupon.cost);
      expect(restoredCoupon.isRedeemed, originalCoupon.isRedeemed);
      expect(restoredCoupon.issuedAt, originalCoupon.issuedAt);
    });

    test('エラーハンドリング', () async {
      // 無効なJSONデータでの復元テスト
      expect(() => CouponModel.fromJson({}), throwsException);
      
      // 必須フィールドが欠けているJSONでの復元テスト
      expect(() => CouponModel.fromJson({
        'id': 'test',
        // titleが欠けている
        'cost': 1000,
      }), throwsException);
    });
  });
}
