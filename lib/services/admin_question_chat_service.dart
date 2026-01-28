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
    final msgRef =
        _db.collection("QuestionChat").doc(chatId).collection("Messages").doc();

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
      "Status": "in_progress", // ✅ 管理者がメッセージ送信時に自動的に「対応中」へ
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
  
  /// ✅ 新規追加: チャットステータスを「対応済」に変更
  Future<void> markAsResolved(String chatId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "resolved",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ✅ 新規追加: チャットステータスを「対応中」に変更
  Future<void> markAsInProgress(String chatId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "in_progress",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ✅ 新規追加: チャットステータスを「未対応」に戻す
  Future<void> markAsPending(String chatId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "pending",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }
}
