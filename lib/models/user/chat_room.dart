import 'dart:convert';

/// ChatRoom は、ユーザー同士の会話セッション（部屋）を表すモデル。
/// 主に `chat_rooms` コレクションで、マッチング後の会話状態管理に利用する。
///
/// フォーマット規約:
/// - ID (`id`, `id1`, `id2`) は文字列 ID（`id1/id2` は User.id を参照）。
/// - 日付 (`startedAt`, `expiresAt`) は ISO8601 文字列で保存。
/// - 列挙相当値 (`status`) は 0=待機, 1=会話, 2=終了 の整数コード。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) の参加関係を保持する。
/// - ExtensionRequest (`lib/models/user/extension_request.dart`) の対象 roomId になる。
/// - Invitation (`lib/models/user/invitation.dart`) の対象 roomId になる。
class ChatRoom {
  final String id; // roomId (Primary Key)
  final String topic; // 話題 (formerly 'name')
  final int status; // 状態: 0=待機, 1=会話, 2=終了
  final String? id1; // 作成者 (creator user ID)
  final String? id2; // 参加者 (participant user ID, nullable)
  final String? comment1; // コメント1 (creator's comment, nullable)
  final String? comment2; // コメント2 (participant's comment, nullable)
  final int extensionCount; // 延長回数
  final int extension; // 延長上限 (non-premium: 2)
  final DateTime startedAt; // 開始時刻
  final DateTime expiresAt; // ルーム有効期限（開始時刻 + 10分）
  final bool private; // プライベートルームフラグ(Default: false)

  ChatRoom({
    required this.id,
    required this.topic,
    this.status = 0,
    required this.id1,
    this.id2,
    this.comment1,
    this.comment2,
    this.extensionCount = 0,
    this.extension = 2,
    required this.startedAt,
    DateTime? expiresAt,
    this.private = false,
  }) : expiresAt = expiresAt ?? startedAt.add(Duration(minutes: 10));

  // Status helpers
  bool get isWaiting => status == 0;
  bool get isActive => status == 1;
  bool get isFinished => status == 2;
  String get statusText {
    switch (status) {
      case 0:
        return '待機中';
      case 1:
        return '会話中';
      case 2:
        return '終了';
      default:
        return '不明';
    }
  }

  bool get isPrivate => private;
  bool get isPublic => !private;

  // toMap: 必須キー=id/topic/status/id1/extensionCount/extension/startedAt/expiresAt/private
  // 任意キー=id2/comment1/comment2, デフォルト値=status:0, extensionCount:0, extension:2, private:false
  Map<String, dynamic> toMap() => {
        'id': id,
        'topic': topic,
        'status': status,
        'id1': id1,
        'id2': id2,
        'comment1': comment1,
        'comment2': comment2,
        'extensionCount': extensionCount,
        'extension': extension,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'private': private,
        'name': topic,
      };

  // fromMap: 必須キー=id/id1 (topic は未指定時 ''), 任意キー=id2/comment1/comment2/expiresAt/private
  // デフォルト値=status:0, extensionCount:0, extension:2, startedAt:createdAt or now, expiresAt:startedAt+10min
  factory ChatRoom.fromMap(Map<String, dynamic> json) {
    final startedAt = json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : (json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now());

    return ChatRoom(
      id: json['id'] as String,
      topic: json['topic'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      id1: json['id1'] as String,
      id2: json['id2'] as String?,
      comment1: json['comment1'] as String?,
      comment2: json['comment2'] as String?,
      extensionCount: json['extensionCount'] as int? ?? 0,
      extension: json['extension'] as int? ?? 2,
      startedAt: startedAt,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : startedAt.add(Duration(minutes: 10)),
      private: json['private'] as bool? ?? false,
    );
  }

  ChatRoom copyWith({
    String? id,
    String? topic,
    int? status,
    String? id1,
    String? id2,
    String? comment1,
    String? comment2,
    int? extensionCount,
    int? extension,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? private,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      id1: id1 ?? this.id1,
      id2: id2 ?? this.id2,
      comment1: comment1 ?? this.comment1,
      comment2: comment2 ?? this.comment2,
      extensionCount: extensionCount ?? this.extensionCount,
      extension: extension ?? this.extension,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      private: private ?? this.private,
    );
  }

  @override
  String toString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toMap());
  }
}
