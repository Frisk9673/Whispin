import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // チャット作成 or 取得
  Future<String?> createOrGetChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final tel = user.phoneNumber ?? user.email ?? "unknown";

    // 既存チェック
    final check = await _db
        .collection("QuestionChat")
        .where("UserID", isEqualTo: tel)
        .limit(1)
        .get();

    if (check.docs.isNotEmpty) {
      return check.docs.first.id;
    }

    // 新規作成
    final doc = await _db.collection("QuestionChat").add({
      "UserID": tel,
      "AdminID": null,
      "LastMessage": "",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // メッセージ送信
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final msgRef = _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .doc();

    await msgRef.set({
      "ID": msgRef.id,
      "IsAdmin": false,
      "Text": text,
      "CreatedAt": FieldValue.serverTimestamp(),
      "Read": false,
    });

    // 最新メッセージ更新
    await _db.collection("QuestionChat").doc(chatId).update({
      "LastMessage": text,
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  // メッセージ一覧ストリーム
  Stream<QuerySnapshot> messageStream(String chatId) {
    return _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .orderBy("CreatedAt")
        .snapshots();
  }
}
