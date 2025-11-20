import 'package:cloud_firestore/cloud_firestore.dart';

/// 店舗モデル
class StoreModel {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final Map<String, String>? hours; // 例: {"monday": "9:00-18:00", ...}
  final GeoPoint? location;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.hours,
    this.location,
  });

  /// Firestoreから作成
  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'],
      hours: data['hours'] != null
          ? Map<String, String>.from(data['hours'])
          : null,
      location: data['location'] as GeoPoint?,
    );
  }

  /// Firestore用に変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (hours != null) 'hours': hours,
      if (location != null) 'location': location,
    };
  }
}
