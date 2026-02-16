/// Friendship は、ユーザー間の成立済み（または保留中）フレンド関係を表すモデル。
/// 主に `friendships` コレクションで双方向の友達関係管理に利用する。
///
/// フォーマット規約:
/// - ID (`id`, `userId`, `friendId`) は User.id 準拠の文字列。
/// - 日付 (`createdAt`) は ISO8601 文字列で保存。
/// - 列挙相当値 (`active`) は bool（true=有効/成立, false=無効/保留）。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) の相互参照を保持する。
/// - FriendRequest (`lib/models/user/friend_request.dart`) 承認後の実体として扱う。
class Friendship {
  final String id; // Unique friendship ID
  final String userId; // ID of the user
  final String friendId; // ID of the friend
  final bool active; // true = accepted, false = pending
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.active,
    required this.createdAt,
  });

  // toMap: 必須キー=id/userId/friendId/active/createdAt, 任意キー=なし, デフォルト値=なし
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'friendId': friendId,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
      };

  // fromMap: 必須キー=id/userId/friendId/active/createdAt, 任意キー=なし, デフォルト値=なし
  factory Friendship.fromMap(Map<String, dynamic> json) => Friendship(
        id: json['id'] as String,
        userId: json['userId'] as String,
        friendId: json['friendId'] as String,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
