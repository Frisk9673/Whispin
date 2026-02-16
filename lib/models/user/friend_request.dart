/// FriendRequest は、ユーザー間のフレンド申請状態を表すモデル。
/// 主に `friend_requests` コレクションで承認/拒否ワークフローに利用する。
///
/// フォーマット規約:
/// - ID (`id`, `senderId`, `receiverId`) は User.id 準拠の文字列。
/// - 日付 (`createdAt`, `respondedAt`) は ISO8601 文字列で保存。
/// - 列挙相当値 (`status`) は 'pending' | 'accepted' | 'rejected'。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) 間の申請関係を表現する。
/// - Friendship (`lib/models/user/friendship.dart`) の前段状態を表現する。
class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  // toMap: 必須キー=id/senderId/receiverId/status/createdAt, 任意キー=respondedAt, デフォルト値=なし
  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };

  // fromMap: 必須キー=id/senderId/receiverId/status/createdAt, 任意キー=respondedAt, デフォルト値=respondedAt:null
  factory FriendRequest.fromMap(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        receiverId: json['receiverId'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'] as String)
            : null,
      );

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
