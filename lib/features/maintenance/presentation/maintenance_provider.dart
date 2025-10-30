import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/maintenance_repository.dart';
import '../domain/vehicle.dart';
import '../domain/service_history.dart';
import '../data/maintenance_repository_impl.dart';

/// メンテナンスリポジトリプロバイダー
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepositoryImpl();
});

/// 車両リストプロバイダー
final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.watchVehicles();
});

/// メンテナンス要車両プロバイダー
final vehiclesNeedingMaintenanceProvider =
    FutureProvider<List<Vehicle>>((ref) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.getVehiclesNeedingMaintenance();
});

/// 特定車両プロバイダー
final vehicleProvider =
    FutureProvider.family<Vehicle?, String>((ref, vehicleId) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.getVehicle(vehicleId);
});

/// 車両サービス履歴プロバイダー
final serviceHistoryProvider =
    StreamProvider.family<List<ServiceHistory>, String>((ref, vehicleId) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.watchServiceHistory(vehicleId);
});

/// 車両ワランティプロバイダー
final warrantiesProvider =
    StreamProvider.family<List<WarrantyInfo>, String>((ref, vehicleId) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.watchWarranties(vehicleId);
});

/// 有効なワランティプロバイダー
final activeWarrantiesProvider =
    FutureProvider.family<List<WarrantyInfo>, String>((ref, vehicleId) async {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.getActiveWarranties(vehicleId);
});

/// 車両統計プロバイダー
final vehicleStatsProvider =
    FutureProvider.family<VehicleStats, String>((ref, vehicleId) async {
  final repository = ref.watch(maintenanceRepositoryProvider);

  final totalCount = await repository.getTotalMaintenanceCount(vehicleId);
  final totalSpent = await repository.getTotalSpent(vehicleId);

  return VehicleStats(
    totalMaintenanceCount: totalCount,
    totalSpent: totalSpent,
  );
});

/// 車両統計モデル
class VehicleStats {
  final int totalMaintenanceCount;
  final int totalSpent;

  const VehicleStats({
    required this.totalMaintenanceCount,
    required this.totalSpent,
  });

  int get averageSpent =>
      totalMaintenanceCount > 0 ? totalSpent ~/ totalMaintenanceCount : 0;
}
