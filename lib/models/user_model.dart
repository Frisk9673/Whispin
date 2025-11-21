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
  final DateTime createdAt;
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
      telId: map['TEL_ID'],
      email: map['EmailAddress'],
      firstName: map['FirstName'],
      lastName: map['LastName'],
      nickname: map['Nickname'],
      rate: (map['Rate'] ?? 0).toDouble(),
      premium: map['Premium'] ?? false,
      roomCount: map['RoomCount'] ?? 0,
      createdAt: (map['CreatedAt'] as Timestamp).toDate(),
      lastUpdatedPremium: map['LastUpdated_Premium'] != null
          ? (map['LastUpdated_Premium'] as Timestamp).toDate()
          : null,
      deletedAt: map['DeletedAt'] != null
          ? (map['DeletedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
