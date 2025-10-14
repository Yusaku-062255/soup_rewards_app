// ポイント永続化サービス（SharedPreferences）
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'points_service.dart';

class PointsStore {
  static const String _pointsStateKey = 'points_state_v1';
  static const String _seedLoadedKey = 'points_seed_loaded';

  /// ポイント状態を読み込み
  static Future<PointsState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pointsStateKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final state = PointsState.fromJson(json);
        developer.log('[SOUP] Points state loaded: ${state.balance}pt balance, ${state.totalEarned}pt total');
        return state;
      }
      
      // 初回起動時：シードデータの読み込み
      final seedState = await _loadSeedData();
      if (seedState != null) {
        await save(seedState);
        return seedState;
      }
      
      developer.log('[SOUP] Points state initialized with defaults');
      return PointsState.initial;
    } catch (e) {
      developer.log('[SOUP] Error loading points state: $e');
      return PointsState.initial;
    }
  }

  /// ポイント状態を保存
  static Future<void> save(PointsState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_pointsStateKey, jsonString);
      
      developer.log('[SOUP] Points state saved: ${state.balance}pt balance, ${state.totalEarned}pt total');
    } catch (e) {
      developer.log('[SOUP] Error saving points state: $e');
      rethrow;
    }
  }

  /// シードデータの読み込み（初回のみ）
  static Future<PointsState?> _loadSeedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seedLoaded = prefs.getBool(_seedLoadedKey) ?? false;
      
      if (seedLoaded) {
        return null; // 既にシード読み込み済み
      }

      // assets/seed/points_seed.json を読み込み
      try {
        final seedJson = await rootBundle.loadString('assets/seed/points_seed.json');
        final seedData = jsonDecode(seedJson) as Map<String, dynamic>;
        
        final seedState = PointsState.fromJson(seedData);
        await prefs.setBool(_seedLoadedKey, true);
        
        developer.log('[SOUP] Seed data loaded: ${seedState.balance}pt balance, ${seedState.totalEarned}pt total');
        return seedState;
      } catch (e) {
        // シードファイルが存在しない場合は無視
        developer.log('[SOUP] No seed file found, using defaults: $e');
        await prefs.setBool(_seedLoadedKey, true);
        return null;
      }
    } catch (e) {
      developer.log('[SOUP] Error loading seed data: $e');
      return null;
    }
  }

  /// データをクリア（デバッグ用）
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsStateKey);
      await prefs.remove(_seedLoadedKey);
      developer.log('[SOUP] Points data cleared');
    } catch (e) {
      developer.log('[SOUP] Error clearing points data: $e');
    }
  }

  /// バックアップ作成
  static Future<String> exportBackup() async {
    try {
      final state = await load();
      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': state.toJson(),
      };
      return jsonEncode(backup);
    } catch (e) {
      developer.log('[SOUP] Error creating backup: $e');
      rethrow;
    }
  }

  /// バックアップから復元
  static Future<bool> importBackup(String backupJson) async {
    try {
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;
      final data = backup['data'] as Map<String, dynamic>;
      final state = PointsState.fromJson(data);
      
      await save(state);
      developer.log('[SOUP] Backup restored successfully');
      return true;
    } catch (e) {
      developer.log('[SOUP] Error restoring backup: $e');
      return false;
    }
  }
}
