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
  final DateTime startedAt; // ✅ 変更: createdAt → startedAt
  final DateTime expiresAt; // ルーム有効期限（開始時刻 + 10分）
  
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
    required this.startedAt, // ✅ 変更
    DateTime? expiresAt,
  }) : expiresAt = expiresAt ?? startedAt.add(Duration(minutes: 10)); // ✅ 変更
  
  // Backward compatibility: get userIds array from id1/id2
  List<String> get userIds {
    final ids = <String>[];
    if (id1 != null && id1!.isNotEmpty) ids.add(id1!);
    if (id2 != null && id2!.isNotEmpty) ids.add(id2!);
    return ids;
  }
  
  // Status helpers
  bool get isWaiting => status == 0;
  bool get isActive => status == 1;
  bool get isFinished => status == 2;
  String get statusText {
    switch (status) {
      case 0: return '待機中';
      case 1: return '会話中';
      case 2: return '終了';
      default: return '不明';
    }
  }
  
  // Backward compatibility: 'name' field
  String get name => topic;
  
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
    'name': topic,
    'userIds': userIds,
  };
  
  factory ChatRoom.fromMap(Map<String, dynamic> json) {
    // Backward compatibility: support old 'userIds' array format
    String id1Value;
    String? id2Value;
    
    if (json.containsKey('id1')) {
      // New format
      id1Value = json['id1'] as String;
      id2Value = json['id2'] as String?;
    } else if (json.containsKey('userIds')) {
      // Old format: convert userIds array to id1/id2
      final userIds = List<String>.from(json['userIds'] as List);
      id1Value = userIds.isNotEmpty ? userIds[0] : '';
      id2Value = userIds.length > 1 ? userIds[1] : null;
    } else {
      id1Value = '';
      id2Value = null;
    }
    
    final startedAt = json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : (json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now());
    
    return ChatRoom(
      id: json['id'] as String,
      topic: json['topic'] as String? ?? json['name'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      id1: id1Value,
      id2: id2Value,
      comment1: json['comment1'] as String?,
      comment2: json['comment2'] as String?,
      extensionCount: json['extensionCount'] as int? ?? 0,
      extension: json['extension'] as int? ?? 2,
      startedAt: startedAt,
      expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : startedAt.add(Duration(minutes: 10)),
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
    );
  }
}