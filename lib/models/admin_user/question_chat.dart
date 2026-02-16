import 'package:cloud_firestore/cloud_firestore.dart';

/// QuestionChat は、ユーザー問い合わせスレッドのメタ情報を表すモデル。
/// 主に `question_chats` コレクションで問い合わせ進行管理に利用する。
///
/// フォーマット規約:
/// - ID (`id`, `userId`, `adminId`) は文字列 ID（`userId` は User.id を参照）。
/// - 日付 (`updatedAt`) は Firestore Timestamp。
/// - 列挙相当値 (`status`) は 'pending' | 'in_progress' | 'resolved'。
///
/// 関連モデル:
/// - User (`lib/models/user/user.dart`) の問い合わせ主体を参照する。
/// - Administrator (`lib/models/admin/administrator.dart`) の担当者を参照する。
/// - Message (`lib/models/admin_user/question_message.dart`) を子メッセージとして持つ。
class QuestionChat {
  final String id;
  final String userId;
  final String? adminId;
  final String lastMessage;
  final Timestamp? updatedAt;
  final String status; // 'pending', 'in_progress', 'resolved'

  QuestionChat({
    required this.id,
    required this.userId,
    this.adminId,
    required this.lastMessage,
    this.updatedAt,
    this.status = 'pending',
  });

  // fromFirestore(fromMap 相当): 必須キー=UserID, 任意キー=AdminID/LastMessage/UpdatedAt/Status
  // デフォルト値=lastMessage:'', status:'pending'
  factory QuestionChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionChat(
      id: doc.id,
      userId: data["UserID"],
      adminId: data["AdminID"],
      lastMessage: data["LastMessage"] ?? "",
      updatedAt: data["UpdatedAt"],
      status: data["Status"] ?? 'pending',
    );
  }
  
  // ステータス判定用のヘルパーメソッド
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  // ステータス表示用のテキスト
  String get statusText {
    switch (status) {
      case 'pending':
        return '未対応';
      case 'in_progress':
        return '対応中';
      case 'resolved':
        return '対応済';
      default:
        return '不明';
    }
  }
}
