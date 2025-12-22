import 'package:cloud_firestore/cloud_firestore.dart';

/// 招待モデル
/// 
/// ユーザーがルームに他のユーザーを招待する際に使用されます。
/// 招待はペンディング状態から承認または拒否されます。
class Invitation {
  final String id;              // 招待ID (Primary Key)
  final String roomId;          // ルームID
  final String inviterId;       // 招待者のユーザーID
  final String inviteeId;       // 招待されるユーザーID
  final String status;          // ステータス: 'pending', 'accepted', 'rejected', 'expired'
  final DateTime createdAt;     // 作成日時
  final DateTime? respondedAt;  // 応答日時（承認/拒否された時刻）
  final DateTime expiresAt;     // 有効期限（デフォルト: 作成から24時間）

  Invitation({
    required this.id,
    required this.roomId,
    required this.inviterId,
    required this.inviteeId,
    this.status = 'pending',
    DateTime? createdAt,
    this.respondedAt,
    DateTime? expiresAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? 
            (createdAt ?? DateTime.now()).add(const Duration(hours: 24));

  // ===== ステータスチェック用 Getter =====
  
  /// ペンディング状態か
  bool get isPending => status == 'pending';
  
  /// 承認済みか
  bool get isAccepted => status == 'accepted';
  
  /// 拒否済みか
  bool get isRejected => status == 'rejected';
  
  /// 期限切れか
  bool get isExpired {
    if (status == 'expired') return true;
    return DateTime.now().isAfter(expiresAt) && status == 'pending';
  }

  // ===== Firestore / JSON 変換 =====

  /// Firestore & JSON 対応の toMap
  Map<String, dynamic> toMap() {
    Timestamp? _ts(DateTime? d) => d != null ? Timestamp.fromDate(d) : null;

    return {
      'id': id,
      'roomId': roomId,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'status': status,
      'createdAt': _ts(createdAt),
      'respondedAt': _ts(respondedAt),
      'expiresAt': _ts(expiresAt),
    };
  }

  /// Firestore & JSON 対応の fromMap
  factory Invitation.fromMap(Map<String, dynamic> map) {
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Invitation(
      id: map['id'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      inviterId: map['inviterId'] as String? ?? '',
      inviteeId: map['inviteeId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      respondedAt: _toDate(map['respondedAt']),
      expiresAt: _toDate(map['expiresAt']) ?? 
          DateTime.now().add(const Duration(hours: 24)),
    );
  }

  // ===== copyWith メソッド =====

  /// イミュータブルな更新用
  Invitation copyWith({
    String? id,
    String? roomId,
    String? inviterId,
    String? inviteeId,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // ===== デバッグ用 =====

  @override
  String toString() {
    return 'Invitation(id: $id, roomId: $roomId, inviter: $inviterId, '
        'invitee: $inviteeId, status: $status, expires: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}