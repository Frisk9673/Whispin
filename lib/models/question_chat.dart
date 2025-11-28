import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionChat {
  final String id;
  final String userId;
  final String? adminId;
  final String lastMessage;
  final Timestamp? updatedAt;

  QuestionChat({
    required this.id,
    required this.userId,
    this.adminId,
    required this.lastMessage,
    this.updatedAt,
  });

  factory QuestionChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionChat(
      id: doc.id,
      userId: data["UserID"],
      adminId: data["AdminID"],
      lastMessage: data["LastMessage"] ?? "",
      updatedAt: data["UpdatedAt"],
    );
  }
}
