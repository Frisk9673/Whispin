import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // チャット作成 or 取得
  Future<String?> createOrGetChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final tel = user.phoneNumber ?? user.email ?? "unknown";

    final check = await _db
        .collection("QuestionChat")
        .where("UserID", isEqualTo: tel)
        .limit(1)
        .get();

    if (check.docs.isNotEmpty) {
      return check.docs.first.id;
    }

    final doc = await _db.collection("QuestionChat").add({
      "UserID": tel,
      "AdminID": null,
      "LastMessage": "",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // モデルを利用してメッセージ送信
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
      isAdmin: false,
      text: text,
      createdAt: Timestamp.now(),
      read: false,
    );

    await msgRef.set(message.toJson());

    await _db.collection("QuestionChat").doc(chatId).update({
      "LastMessage": text,
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  // モデルを返すストリームに変更
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
}
