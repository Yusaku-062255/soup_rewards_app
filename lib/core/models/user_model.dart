import 'package:cloud_firestore/cloud_firestore.dart';

/// 車種区分
enum VehicleType {
  ev, // EV車
  gasoline, // ガソリン車など
}

/// ユーザーモデル
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final int points;
  final String? memberId; // 6桁の会員ID（本会員登録時に付与）
  final VehicleType? vehicleType; // 車種区分（EV車 / ガソリン車など）
  final String? vehicleMaker; // メーカー名（任意）
  final String? vehicleModel; // 車種名（任意）
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.points = 0,
    this.memberId,
    this.vehicleType,
    this.vehicleMaker,
    this.vehicleModel,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから作成
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('User data not found for ID: ${doc.id}');
    }

    // 車種区分の変換（文字列からenumへ）
    VehicleType? vehicleType;
    final vehicleTypeStr = data['vehicleType'] as String?;
    if (vehicleTypeStr != null) {
      vehicleType = VehicleType.values.firstWhere(
        (e) => e.toString().split('.').last == vehicleTypeStr,
        orElse: () => VehicleType.gasoline,
      );
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      points: (data['points'] as int?) ?? 0,
      memberId: data['memberId'] as String?,
      vehicleType: vehicleType,
      vehicleMaker: data['vehicleMaker'] as String?,
      vehicleModel: data['vehicleModel'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'points': points,
      'memberId': memberId,
      if (vehicleType != null)
        'vehicleType': vehicleType.toString().split('.').last,
      if (vehicleMaker != null) 'vehicleMaker': vehicleMaker,
      if (vehicleModel != null) 'vehicleModel': vehicleModel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// コピーを作成
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    int? points,
    String? memberId,
    VehicleType? vehicleType,
    String? vehicleMaker,
    String? vehicleModel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      points: points ?? this.points,
      memberId: memberId ?? this.memberId,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleMaker: vehicleMaker ?? this.vehicleMaker,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
