import 'vehicle.dart';
import 'service_history.dart';

/// メンテナンス・車両管理リポジトリ
abstract class MaintenanceRepository {
  // 車両管理
  Future<List<Vehicle>> getVehicles();
  Future<Vehicle?> getVehicle(String vehicleId);
  Future<String> addVehicle(Vehicle vehicle);
  Future<void> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String vehicleId);
  Stream<List<Vehicle>> watchVehicles();

  // サービス履歴
  Future<List<ServiceHistory>> getServiceHistory(String vehicleId);
  Future<ServiceHistory?> getServiceHistoryById(String historyId);
  Future<String> addServiceHistory(ServiceHistory history);
  Future<void> updateServiceHistory(ServiceHistory history);
  Future<void> deleteServiceHistory(String historyId);
  Stream<List<ServiceHistory>> watchServiceHistory(String vehicleId);

  // ワランティ
  Future<List<WarrantyInfo>> getActiveWarranties(String vehicleId);
  Future<List<WarrantyInfo>> getAllWarranties(String vehicleId);
  Stream<List<WarrantyInfo>> watchWarranties(String vehicleId);

  // メンテナンス提案
  Future<List<Vehicle>> getVehiclesNeedingMaintenance();
  Future<void> updateNextMaintenanceDate(String vehicleId, DateTime nextDate);

  // 統計
  Future<int> getTotalMaintenanceCount(String vehicleId);
  Future<int> getTotalSpent(String vehicleId);
}
