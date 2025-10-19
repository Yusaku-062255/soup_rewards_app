// 車両ストアサービステスト
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/models/vehicle_model.dart';
import '../../../lib/core/services/vehicle_store.dart';

void main() {
  group('VehicleStore Tests', () {
    setUp(() async {
      // テスト前にSharedPreferencesをクリア
      SharedPreferences.setMockInitialValues({});
    });

    test('車両情報の保存と読み込み', () async {
      // テスト用車両データ
      const vehicle = VehicleModel(
        name: 'プリウス',
        manufacturer: 'トヨタ',
        year: 2020,
        plateNumber: '品川 123 あ 1234',
        isEv: false,
        photoPath: '/path/to/photo.jpg',
      );

      // 保存
      final saveResult = await VehicleStore.saveVehicle(vehicle);
      expect(saveResult, true);

      // 読み込み
      final loadedVehicle = await VehicleStore.loadVehicle();
      expect(loadedVehicle, isNotNull);
      expect(loadedVehicle!.name, 'プリウス');
      expect(loadedVehicle.manufacturer, 'トヨタ');
      expect(loadedVehicle.year, 2020);
      expect(loadedVehicle.plateNumber, '品川 123 あ 1234');
      expect(loadedVehicle.isEv, false);
      expect(loadedVehicle.photoPath, '/path/to/photo.jpg');
    });

    test('EV車両の保存と読み込み', () async {
      // EV車両データ
      const evVehicle = VehicleModel(
        name: 'リーフ',
        manufacturer: '日産',
        year: 2022,
        isEv: true,
      );

      // 保存
      await VehicleStore.saveVehicle(evVehicle);

      // EVフラグの確認
      final isEv = await VehicleStore.isEvVehicle();
      expect(isEv, true);

      // 車両情報の確認
      final info = await VehicleStore.getVehicleInfo();
      expect(info, isNotNull);
      expect(info!['displayName'], '日産 リーフ');
      expect(info['displayType'], 'EV');
      expect(info['isEv'], true);
    });

    test('車両情報が存在しない場合', () async {
      // 何も保存していない状態
      final hasVehicle = await VehicleStore.hasVehicle();
      expect(hasVehicle, false);

      final vehicle = await VehicleStore.loadVehicle();
      expect(vehicle, isNull);

      final isEv = await VehicleStore.isEvVehicle();
      expect(isEv, false);

      final info = await VehicleStore.getVehicleInfo();
      expect(info, isNull);
    });

    test('車両情報の削除', () async {
      // 車両を保存
      const vehicle = VehicleModel(
        name: 'アクア',
        manufacturer: 'トヨタ',
        isEv: false,
      );
      await VehicleStore.saveVehicle(vehicle);

      // 存在確認
      expect(await VehicleStore.hasVehicle(), true);

      // 削除
      final clearResult = await VehicleStore.clearVehicle();
      expect(clearResult, true);

      // 削除後の確認
      expect(await VehicleStore.hasVehicle(), false);
      expect(await VehicleStore.loadVehicle(), isNull);
    });

    test('バリデーション付き保存', () async {
      // 有効な車両データ
      const validVehicle = VehicleModel(
        name: 'カローラ',
        manufacturer: 'トヨタ',
        year: 2021,
        isEv: false,
      );

      final validResult = await VehicleStore.saveVehicleWithValidation(validVehicle);
      expect(validResult['success'], true);
      expect(validResult['message'], '車両情報を保存しました');

      // 無効な車両データ（車名なし）
      const invalidVehicle = VehicleModel(
        name: '',
        manufacturer: 'トヨタ',
        year: 2021,
        isEv: false,
      );

      final invalidResult = await VehicleStore.saveVehicleWithValidation(invalidVehicle);
      expect(invalidResult['success'], false);
      expect(invalidResult['error'], contains('車名は必須'));

      // 無効な年式
      const invalidYearVehicle = VehicleModel(
        name: 'テスト車',
        year: 1800, // 1900年より前
        isEv: false,
      );

      final invalidYearResult = await VehicleStore.saveVehicleWithValidation(invalidYearVehicle);
      expect(invalidYearResult['success'], false);
      expect(invalidYearResult['error'], contains('1900年以降'));
    });

    test('統計情報の取得', () async {
      // 車両を保存
      const vehicle = VehicleModel(
        name: 'テスラ Model 3',
        manufacturer: 'Tesla',
        year: 2023,
        isEv: true,
        photoPath: '/path/to/tesla.jpg',
      );
      await VehicleStore.saveVehicle(vehicle);

      // 統計情報取得
      final stats = await VehicleStore.getStats();
      expect(stats['hasVehicle'], true);
      expect(stats['isEv'], true);
      expect(stats['vehicleInfo'], isNotNull);
      expect(stats['vehicleInfo']['displayName'], 'Tesla テスラ Model 3');
      expect(stats['vehicleInfo']['hasPhoto'], true);
      expect(stats['lastChecked'], isNotNull);
    });

    test('車両モデルのプロパティ', () {
      // 基本的な車両
      const basicVehicle = VehicleModel(
        name: 'フィット',
        manufacturer: 'ホンダ',
        year: 2019,
        isEv: false,
      );

      expect(basicVehicle.displayName, 'ホンダ フィット');
      expect(basicVehicle.displayYear, '2019年式');
      expect(basicVehicle.displayType, 'ガソリン車');
      expect(basicVehicle.isValid, true);

      // メーカーなしの車両
      const noManufacturerVehicle = VehicleModel(
        name: 'カスタムカー',
        isEv: true,
      );

      expect(noManufacturerVehicle.displayName, 'カスタムカー');
      expect(noManufacturerVehicle.displayType, 'EV');

      // 年式なしの車両
      const noYearVehicle = VehicleModel(
        name: 'クラシックカー',
        isEv: false,
      );

      expect(noYearVehicle.displayYear, '年式不明');

      // 無効な車両（車名なし）
      const invalidVehicle = VehicleModel(
        name: '',
        isEv: false,
      );

      expect(invalidVehicle.isValid, false);
    });
  });
}
