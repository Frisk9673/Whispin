import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // Email (Primary Key)
  final String password; // hashed password (JSON 用)
  final String firstName;
  final String lastName;
  final String nickname;
  final String? phoneNumber; // TEL_ID に相当
  final double rate; // double に統一
  final bool premium;
  final int roomCount;

  final DateTime createdAt;
  final DateTime? lastUpdatedPremium;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    this.password = '',
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.phoneNumber,
    this.rate = 0.0,
    this.premium = false,
    this.roomCount = 0,
    DateTime? createdAt,
    this.lastUpdatedPremium,
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ===== Getter =====
  String get displayName =>
      nickname.isNotEmpty ? nickname : '$firstName $lastName';

  String get fullName => '$firstName $lastName';

  bool get isDeleted => deletedAt != null;

  // ===== Firestore + JSON 両対応の fromMap =====
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return UserModel(
      id: map['id'] ??
          map['EmailAddress'] ??
          '', // Firestore 旧形式もサポート

      password: map['password'] ?? '',

      firstName: map['firstName'] ?? map['FirstName'] ?? '',
      lastName: map['lastName'] ?? map['LastName'] ?? '',
      nickname:
          map['nickname'] ?? map['Nickname'] ?? map['username'] ?? '',

      phoneNumber: map['phoneNumber'] ?? map['TEL_ID'],

      rate: (map['rate'] ?? map['Rate'] ?? 0).toDouble(),

      premium: map['premium'] ?? map['Premium'] ?? false,
      roomCount: map['roomCount'] ?? map['RoomCount'] ?? 0,

      createdAt: _toDate(map['createdAt'] ?? map['CreatedAt']) ??
          DateTime.now(),

      lastUpdatedPremium:
          _toDate(map['lastUpdatedPremium'] ?? map['LastUpdated_Premium']),

      deletedAt: _toDate(map['deletedAt'] ?? map['DeletedAt']),
    );
  }

  // ===== Firestore / JSON 両対応 Map 変換 =====
  Map<String, dynamic> toMap() {
    Timestamp? _ts(DateTime? d) =>
        d != null ? Timestamp.fromDate(d) : null;

    return {
      'id': id,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'nickname': nickname,
      'phoneNumber': phoneNumber,

      'rate': rate,
      'premium': premium,
      'roomCount': roomCount,

      'createdAt': _ts(createdAt),
      'lastUpdatedPremium': _ts(lastUpdatedPremium),
      'deletedAt': _ts(deletedAt),
    };
  }
}
