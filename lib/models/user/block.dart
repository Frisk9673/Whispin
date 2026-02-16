/// Block は、ユーザー間のブロック関係（遮断状態）を表すモデル。
/// 主に `blocks` コレクションで、User 間の可視性/接触制御に利用する。
///
/// フォーマット規約:
/// - ID (`id`, `blockerId`, `blockedId`) は User.id（メール文字列）準拠。
/// - 日付 (`createdAt`) は UTC 推奨の ISO8601 文字列で保存。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) を参照し、誰が誰をブロックしたかを表現する。
class Block {
  final String id; // Unique block ID
  final String blockerId; // User who blocked
  final String blockedId; // User who was blocked
  final bool active; // Active flag for soft delete
  final DateTime createdAt;

  Block({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.active = true,
    required this.createdAt,
  });

  Block copyWith({
    String? id,
    String? blockerId,
    String? blockedId,
    bool? active,
    DateTime? createdAt,
  }) {
    return Block(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // toMap: 必須キー=id/blockerId/blockedId/createdAt, 任意キー=なし, デフォルト値=active(true)
  Map<String, dynamic> toMap() => {
        'id': id,
        'blockerId': blockerId,
        'blockedId': blockedId,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
      };

  // fromMap: 必須キー=id/blockerId/blockedId/createdAt, 任意キー=active, デフォルト値=active:true
  factory Block.fromMap(Map<String, dynamic> json) => Block(
        id: json['id'] as String,
        blockerId: json['blockerId'] as String,
        blockedId: json['blockedId'] as String,
        active: json['active'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
