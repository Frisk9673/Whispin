import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String telId;
  final String email;
  final String firstName;
  final String lastName;
  final String nickname;
  final double rate;
  final bool premium;
  final int roomCount;
  final DateTime? createdAt;
  final DateTime? lastUpdatedPremium;
  final DateTime? deletedAt;

  UserModel({
    required this.telId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.rate,
    required this.premium,
    required this.roomCount,
    required this.createdAt,
    this.lastUpdatedPremium,
    this.deletedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      telId: map['TEL_ID'] ?? '',
      email: map['EmailAddress'] ?? '',
      firstName: map['FirstName'] ?? '',
      lastName: map['LastName'] ?? '',
      nickname: map['Nickname'] ?? '',
      rate: (map['Rate'] ?? 0).toDouble(),
      premium: map['Premium'] ?? false,
      roomCount: map['RoomCount'] ?? 0,

      /// Firestore は Timestamp or null の可能性があるので安全変換
      createdAt: map['CreatedAt'] is Timestamp
          ? (map['CreatedAt'] as Timestamp).toDate()
          : null,

      lastUpdatedPremium: map['LastUpdated_Premium'] is Timestamp
          ? (map['LastUpdated_Premium'] as Timestamp).toDate()
          : null,

      deletedAt: map['DeletedAt'] is Timestamp
          ? (map['DeletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore に保存するときの Map 変換（必要なら）
  Map<String, dynamic> toMap() {
    return {
      "TEL_ID": telId,
      "EmailAddress": email,
      "FirstName": firstName,
      "LastName": lastName,
      "Nickname": nickname,
      "Rate": rate,
      "Premium": premium,
      "RoomCount": roomCount,
      "CreatedAt": createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      "LastUpdated_Premium": lastUpdatedPremium != null
          ? Timestamp.fromDate(lastUpdatedPremium!)
          : null,
      "DeletedAt":
          deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }
}
