import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/maintenance_repository.dart';
import '../domain/vehicle.dart';
import '../domain/service_history.dart';

/// メンテナンスリポジトリ実装
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MaintenanceRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference get _vehiclesCollection {
    return _firestore.collection('users').doc(_userId).collection('vehicles');
  }

  CollectionReference _serviceHistoryCollection(String vehicleId) {
    return _vehiclesCollection.doc(vehicleId).collection('serviceHistory');
  }

  CollectionReference _warrantiesCollection(String vehicleId) {
    return _vehiclesCollection.doc(vehicleId).collection('warranties');
  }

  // 車両管理
  @override
  Future<List<Vehicle>> getVehicles() async {
    final snapshot = await _vehiclesCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Vehicle.fromFirestore(doc))
        .toList();
  }

  @override
  Future<Vehicle?> getVehicle(String vehicleId) async {
    final doc = await _vehiclesCollection.doc(vehicleId).get();
    if (!doc.exists) return null;
    return Vehicle.fromFirestore(doc);
  }

  @override
  Future<String> addVehicle(Vehicle vehicle) async {
    final vehicleData = vehicle.toJson();
    vehicleData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _vehiclesCollection.add(vehicleData);
    return docRef.id;
  }

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    final vehicleData = vehicle.toJson();
    vehicleData['updatedAt'] = FieldValue.serverTimestamp();

    await _vehiclesCollection.doc(vehicle.id).update(vehicleData);
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    await _vehiclesCollection.doc(vehicleId).delete();
  }

  @override
  Stream<List<Vehicle>> watchVehicles() {
    return _vehiclesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vehicle.fromFirestore(doc))
            .toList());
  }

  // サービス履歴
  @override
  Future<List<ServiceHistory>> getServiceHistory(String vehicleId) async {
    final snapshot = await _serviceHistoryCollection(vehicleId)
        .orderBy('servicedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ServiceHistory.fromFirestore(doc))
        .toList();
  }

  @override
  Future<ServiceHistory?> getServiceHistoryById(String historyId) async {
    // Note: このメソッドはvehicleIdが必要ですが、インターフェースには含まれていません
    // 実際の実装では、全車両から検索するか、vehicleIdを引数に追加する必要があります
    throw UnimplementedError('getServiceHistoryById requires vehicleId');
  }

  @override
  Future<String> addServiceHistory(ServiceHistory history) async {
    final historyData = history.toJson();
    historyData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _serviceHistoryCollection(history.vehicleId)
        .add(historyData);
    return docRef.id;
  }

  @override
  Future<void> updateServiceHistory(ServiceHistory history) async {
    final historyData = history.toJson();

    await _serviceHistoryCollection(history.vehicleId)
        .doc(history.id)
        .update(historyData);
  }

  @override
  Future<void> deleteServiceHistory(String historyId) async {
    // Note: このメソッドもvehicleIdが必要です
    throw UnimplementedError('deleteServiceHistory requires vehicleId');
  }

  @override
  Stream<List<ServiceHistory>> watchServiceHistory(String vehicleId) {
    return _serviceHistoryCollection(vehicleId)
        .orderBy('servicedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceHistory.fromFirestore(doc))
            .toList());
  }

  // ワランティ
  @override
  Future<List<WarrantyInfo>> getActiveWarranties(String vehicleId) async {
    final now = Timestamp.now();
    final snapshot = await _warrantiesCollection(vehicleId)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .get();

    return snapshot.docs
        .map((doc) => WarrantyInfo.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<WarrantyInfo>> getAllWarranties(String vehicleId) async {
    final snapshot = await _warrantiesCollection(vehicleId)
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WarrantyInfo.fromFirestore(doc))
        .toList();
  }

  @override
  Stream<List<WarrantyInfo>> watchWarranties(String vehicleId) {
    return _warrantiesCollection(vehicleId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WarrantyInfo.fromFirestore(doc))
            .toList());
  }

  // メンテナンス提案
  @override
  Future<List<Vehicle>> getVehiclesNeedingMaintenance() async {
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));

    final snapshot = await _vehiclesCollection
        .where('nextMaintenanceAt',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
        .orderBy('nextMaintenanceAt')
        .get();

    return snapshot.docs
        .map((doc) => Vehicle.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updateNextMaintenanceDate(
    String vehicleId,
    DateTime nextDate,
  ) async {
    await _vehiclesCollection.doc(vehicleId).update({
      'nextMaintenanceAt': Timestamp.fromDate(nextDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 統計
  @override
  Future<int> getTotalMaintenanceCount(String vehicleId) async {
    final snapshot = await _serviceHistoryCollection(vehicleId).get();
    return snapshot.docs.length;
  }

  @override
  Future<int> getTotalSpent(String vehicleId) async {
    final snapshot = await _serviceHistoryCollection(vehicleId).get();

    return snapshot.docs.fold<int>(0, (total, doc) {
      final history = ServiceHistory.fromFirestore(doc);
      return total + history.amount;
    });
  }
}
