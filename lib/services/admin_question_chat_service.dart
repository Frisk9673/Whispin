import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_message.dart';

class AdminQuestionChatService {
  final _db = FirebaseFirestore.instance;

  /// 特定チャットのメッセージストリームを取得
  Stream<List<Message>> messageStream(String chatId) {
    return _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .orderBy("CreatedAt")
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// 管理者としてメッセージを送信
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final msgRef = _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .doc();

    final message = Message(
      id: msgRef.id,
      isAdmin: true, // 管理者送信
      text: text,
      createdAt: Timestamp.now(),
      read: false,
    );

    await msgRef.set(message.toMap());

    // 最終メッセージと更新日時を更新
    await _db.collection("QuestionChat").doc(chatId).update({
      "LastMessage": text,
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// チャット担当者を割り当て
  Future<void> assignAdmin(String chatId, String adminId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "AdminID": adminId,
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 未読メッセージを管理者が既読にする場合（オプション）
  Future<void> markMessagesAsRead(String chatId) async {
    final msgs = await _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .where("Read", isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (var doc in msgs.docs) {
      batch.update(doc.reference, {"Read": true});
    }

    await batch.commit();
  }
}
