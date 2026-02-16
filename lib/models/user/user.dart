// lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// User は、アプリ利用者のプロフィール/認証/状態を表す中心モデル。
/// 主に `users` コレクションに保存し、認証・チャット・フレンド機能の基点として利用する。
///
/// フォーマット規約:
/// - ID (`id`) はメールアドレス文字列を主キーとして扱う。
/// - 日付 (`createdAt` ほか) は Firestore Timestamp / ISO8601 の双方を許容。
/// - 列挙相当値は主に bool (`premium`) と数値 (`rate`, `roomCount`) で管理。
///
/// 関連モデル:
/// - Friendship / FriendRequest / Block / UserEvaluation で User.id が参照される。
/// - ChatRoom (`id1`,`id2`) / Invitation / ExtensionRequest の主体ユーザーとして参照される。
class User {
  final String id; // Email (Primary Key)
  final String password; // hashed password (JSON 用)
  final String firstName;
  final String lastName;
  final String nickname;
  final String? phoneNumber;
  final double rate;
  final bool premium;
  final int roomCount;
  final DateTime createdAt;
  final DateTime? lastUpdatedPremium;
  final DateTime? deletedAt;
  final String? fcmToken;
  final DateTime? fcmTokenUpdatedAt;
  final String? profileImageUrl;

  User({
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
    this.fcmToken,
    this.fcmTokenUpdatedAt,
    this.profileImageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName =>
      nickname.isNotEmpty ? nickname : '$firstName $lastName';
  String get fullName => '$lastName $firstName';
  bool get isDeleted => deletedAt != null;

  // ===== Firestore + JSON 両対応の fromMap =====
  // 必須キー: id(または EmailAddress) 推奨
  // 任意キー: password/firstName/lastName/nickname/phoneNumber/rate/premium/roomCount/
  //          createdAt/lastUpdatedPremium/deletedAt/fcmToken/fcmTokenUpdatedAt/profileImageUrl
  // デフォルト値: 文字列'', rate:0.0, premium:false, roomCount:0, createdAt:now
  factory User.fromMap(Map<String, dynamic> map) {
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return User(
      id: map['id'] ?? map['EmailAddress'] ?? '',

      password: map['password'] ?? '',

      firstName: map['firstName'] ?? map['FirstName'] ?? '',
      lastName: map['lastName'] ?? map['LastName'] ?? '',
      nickname: map['nickname'] ?? map['Nickname'] ?? map['username'] ?? '',

      phoneNumber: map['phoneNumber'] ?? map['TEL_ID'],

      rate: (map['rate'] ?? map['Rate'] ?? 0).toDouble(),

      premium: map['premium'] ?? map['Premium'] ?? false,
      roomCount: map['roomCount'] ?? map['RoomCount'] ?? 0,

      createdAt:
          _toDate(map['createdAt'] ?? map['CreatedAt']) ?? DateTime.now(),

      lastUpdatedPremium:
          _toDate(map['lastUpdatedPremium'] ?? map['LastUpdated_Premium']),

      deletedAt: _toDate(map['deletedAt'] ?? map['DeletedAt']),
      
      fcmToken: map['fcmToken'] as String?,
      fcmTokenUpdatedAt: _toDate(map['fcmTokenUpdatedAt']),
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  // ===== Firestore / JSON 両対応 Map 変換 =====
  // 出力キー: id/password/firstName/lastName/nickname/phoneNumber/rate/premium/roomCount/
  //          createdAt/lastUpdatedPremium/deletedAt/fcmToken/fcmTokenUpdatedAt/profileImageUrl
  Map<String, dynamic> toMap() {
    Timestamp? _ts(DateTime? d) => d != null ? Timestamp.fromDate(d) : null;

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
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': _ts(fcmTokenUpdatedAt),
      'profileImageUrl': profileImageUrl,
    };
  }
}
