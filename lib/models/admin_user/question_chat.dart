import 'package:cloud_firestore/cloud_firestore.dart';

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
