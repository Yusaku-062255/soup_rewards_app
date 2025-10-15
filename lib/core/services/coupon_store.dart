// クーポンの永続化サービス
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coupon_model.dart';

class CouponStore {
  static const String _couponsKey = 'user_coupons';

  // クーポンリストを保存
  static Future<bool> saveCoupons(List<CouponModel> coupons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = coupons.map((coupon) => coupon.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      final success = await prefs.setString(_couponsKey, jsonString);
      
      if (success) {
        developer.log('[SOUP] ${coupons.length} coupons saved');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error saving coupons: $e');
      return false;
    }
  }

  // クーポンリストを読み込み
  static Future<List<CouponModel>> loadCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_couponsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('[SOUP] No coupon data found, returning empty list');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final coupons = jsonList
          .map((json) => CouponModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      developer.log('[SOUP] ${coupons.length} coupons loaded');
      return coupons;
    } catch (e) {
      developer.log('[SOUP] Error loading coupons: $e');
      return [];
    }
  }

  // クーポンを追加
  static Future<bool> addCoupon(CouponModel coupon) async {
    try {
      final coupons = await loadCoupons();
      
      // 重複チェック
      if (coupons.any((c) => c.id == coupon.id)) {
        developer.log('[SOUP] Coupon ${coupon.id} already exists');
        return false;
      }
      
      coupons.add(coupon);
      return await saveCoupons(coupons);
    } catch (e) {
      developer.log('[SOUP] Error adding coupon: $e');
      return false;
    }
  }

  // クーポンの交換状態を切り替え
  static Future<bool> toggleRedeem(String couponId) async {
    try {
      final coupons = await loadCoupons();
      final index = coupons.indexWhere((c) => c.id == couponId);
      
      if (index == -1) {
        developer.log('[SOUP] Coupon $couponId not found');
        return false;
      }
      
      final coupon = coupons[index];
      coupons[index] = coupon.isRedeemed 
          ? coupon.copyWith(isRedeemed: false, redeemedAt: null)
          : coupon.redeem();
      
      final success = await saveCoupons(coupons);
      
      if (success) {
        developer.log('[SOUP] Coupon $couponId redeemed: ${coupons[index].isRedeemed}');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error toggling coupon redeem: $e');
      return false;
    }
  }

  // 特定のクーポンを取得
  static Future<CouponModel?> getCoupon(String couponId) async {
    try {
      final coupons = await loadCoupons();
      return coupons.firstWhere(
        (c) => c.id == couponId,
        orElse: () => throw StateError('Coupon not found'),
      );
    } catch (e) {
      developer.log('[SOUP] Coupon $couponId not found: $e');
      return null;
    }
  }

  // 未使用クーポンを取得
  static Future<List<CouponModel>> getAvailableCoupons() async {
    try {
      final coupons = await loadCoupons();
      return coupons.where((c) => !c.isRedeemed && !c.isExpired).toList();
    } catch (e) {
      developer.log('[SOUP] Error getting available coupons: $e');
      return [];
    }
  }

  // 使用済みクーポンを取得
  static Future<List<CouponModel>> getRedeemedCoupons() async {
    try {
      final coupons = await loadCoupons();
      return coupons.where((c) => c.isRedeemed).toList();
    } catch (e) {
      developer.log('[SOUP] Error getting redeemed coupons: $e');
      return [];
    }
  }

  // クーポンを削除
  static Future<bool> removeCoupon(String couponId) async {
    try {
      final coupons = await loadCoupons();
      coupons.removeWhere((c) => c.id == couponId);
      
      final success = await saveCoupons(coupons);
      
      if (success) {
        developer.log('[SOUP] Coupon $couponId removed');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error removing coupon: $e');
      return false;
    }
  }

  // 全クーポンを削除
  static Future<bool> clearAllCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_couponsKey);
      
      if (success) {
        developer.log('[SOUP] All coupons cleared');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error clearing coupons: $e');
      return false;
    }
  }

  // デフォルトクーポンを初期化
  static Future<bool> initializeDefaultCoupons() async {
    try {
      final existingCoupons = await loadCoupons();
      
      // 給油券クーポンが存在しない場合のみ追加
      if (!existingCoupons.any((c) => c.id == 'fuel_coupon_5000')) {
        final fuelCoupon = CouponModel.createFuelCoupon();
        await addCoupon(fuelCoupon);
        developer.log('[SOUP] Default fuel coupon initialized');
      }
      
      return true;
    } catch (e) {
      developer.log('[SOUP] Error initializing default coupons: $e');
      return false;
    }
  }

  // 統計情報取得
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final coupons = await loadCoupons();
      final availableCoupons =
          coupons.where((c) => !c.isRedeemed && !c.isExpired).toList();
      final redeemedCoupons = coupons.where((c) => c.isRedeemed).toList();
      final expiredCoupons = coupons.where((c) => c.isExpired).toList();
      final totalValue = coupons.fold<int>(0, (sum, c) => sum + c.cost);
      final redeemedValue =
          redeemedCoupons.fold<int>(0, (sum, c) => sum + c.cost);

      final availableCount = availableCoupons.length;
      final redeemedCount = redeemedCoupons.length;
      final expiredCount = expiredCoupons.length;
      final totalCount = coupons.length;

      return {
        // 既存互換用のキー
        'total': totalCount,
        'available': availableCount,
        'redeemed': redeemedCount,
        'expired': expiredCount,
        // 新しい統計情報
        'totalCoupons': totalCount,
        'availableCoupons': availableCount,
        'redeemedCoupons': redeemedCount,
        'expiredCoupons': expiredCount,
        'totalValue': totalValue,
        'redeemedValue': redeemedValue,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'total': 0,
        'available': 0,
        'redeemed': 0,
        'expired': 0,
        'totalCoupons': 0,
        'availableCoupons': 0,
        'redeemedCoupons': 0,
        'expiredCoupons': 0,
        'totalValue': 0,
        'redeemedValue': 0,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }
}
