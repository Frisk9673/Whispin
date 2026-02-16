/// ExtensionRequest は、ChatRoom の会話時間延長リクエストを表すモデル。
/// 主に `extension_requests` コレクションで延長承認フローに利用する。
///
/// フォーマット規約:
/// - ID (`id`, `roomId`, `requesterId`) は文字列 ID（`roomId` は ChatRoom.id、`requesterId` は User.id）。
/// - 日付 (`createdAt`) は ISO8601 文字列で保存。
/// - 列挙相当値 (`status`) は 'pending' | 'approved' | 'rejected'。
///
/// 関連モデル:
/// - ChatRoom (`lib/models/user/chat_room.dart`) の延長要求を表現する。
/// - User (`lib/models/user/user.dart`) の操作履歴を表現する。
class ExtensionRequest {
  final String id; // Unique request ID
  final String roomId; // Room ID
  final String requesterId; // User who requested extension
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  ExtensionRequest({
    required this.id,
    required this.roomId,
    required this.requesterId,
    this.status = 'pending',
    required this.createdAt,
  });

  // toMap: 必須キー=id/roomId/requesterId/status/createdAt, 任意キー=なし, デフォルト値=status:'pending'
  Map<String, dynamic> toMap() => {
        'id': id,
        'roomId': roomId,
        'requesterId': requesterId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  // fromMap: 必須キー=id/roomId/requesterId/createdAt, 任意キー=status, デフォルト値=status:'pending'
  factory ExtensionRequest.fromMap(Map<String, dynamic> json) =>
      ExtensionRequest(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        requesterId: json['requesterId'] as String,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  ExtensionRequest copyWith({
    String? id,
    String? roomId,
    String? requesterId,
    String? status,
    DateTime? createdAt,
  }) {
    return ExtensionRequest(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      requesterId: requesterId ?? this.requesterId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
