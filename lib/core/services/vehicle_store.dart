// 車両情報の永続化サービス
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_model.dart';

class VehicleStore {
  static const String _vehicleKey = 'user_vehicle';

  // 車両情報を保存
  static Future<bool> saveVehicle(VehicleModel vehicle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = vehicle.toJsonString();
      final success = await prefs.setString(_vehicleKey, jsonString);
      
      if (success) {
        developer.log('[SOUP] Vehicle saved: ${vehicle.displayName} (EV: ${vehicle.isEv})');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error saving vehicle: $e');
      return false;
    }
  }

  // 車両情報を読み込み
  static Future<VehicleModel?> loadVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_vehicleKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        developer.log('[SOUP] No vehicle data found');
        return null;
      }
      
      final vehicle = VehicleModel.fromJsonString(jsonString);
      developer.log('[SOUP] Vehicle loaded: ${vehicle.displayName} (EV: ${vehicle.isEv})');
      
      return vehicle;
    } catch (e) {
      developer.log('[SOUP] Error loading vehicle: $e');
      return null;
    }
  }

  // 車両情報を削除
  static Future<bool> clearVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_vehicleKey);
      
      if (success) {
        developer.log('[SOUP] Vehicle data cleared');
      }
      
      return success;
    } catch (e) {
      developer.log('[SOUP] Error clearing vehicle: $e');
      return false;
    }
  }

  // 車両情報が存在するかチェック
  static Future<bool> hasVehicle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_vehicleKey);
    } catch (e) {
      developer.log('[SOUP] Error checking vehicle existence: $e');
      return false;
    }
  }

  // EVフラグのみを取得（高速アクセス用）
  static Future<bool> isEvVehicle() async {
    try {
      final vehicle = await loadVehicle();
      return vehicle?.isEv ?? false;
    } catch (e) {
      developer.log('[SOUP] Error checking EV flag: $e');
      return false;
    }
  }

  // 車両の基本情報のみを取得（表示用）
  static Future<Map<String, dynamic>?> getVehicleInfo() async {
    try {
      final vehicle = await loadVehicle();
      if (vehicle == null) return null;
      
      return {
        'displayName': vehicle.displayName,
        'displayYear': vehicle.displayYear,
        'displayType': vehicle.displayType,
        'isEv': vehicle.isEv,
        'hasPhoto': vehicle.photoPath != null && vehicle.photoPath!.isNotEmpty,
      };
    } catch (e) {
      developer.log('[SOUP] Error getting vehicle info: $e');
      return null;
    }
  }

  // バリデーション付きで保存
  static Future<Map<String, dynamic>> saveVehicleWithValidation(VehicleModel vehicle) async {
    // バリデーションチェック
    if (!vehicle.isValid) {
      return {
        'success': false,
        'error': '車名は必須です。年式は1900年以降を入力してください。',
      };
    }

    // 保存実行
    final success = await saveVehicle(vehicle);
    
    if (success) {
      return {
        'success': true,
        'message': '車両情報を保存しました',
        'vehicle': vehicle.toJson(),
      };
    } else {
      return {
        'success': false,
        'error': '保存に失敗しました。もう一度お試しください。',
      };
    }
  }

  // 統計情報取得（デバッグ用）
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final hasVehicle = await VehicleStore.hasVehicle();
      final isEv = await isEvVehicle();
      final info = await getVehicleInfo();
      
      return {
        'hasVehicle': hasVehicle,
        'isEv': isEv,
        'vehicleInfo': info,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }
}
