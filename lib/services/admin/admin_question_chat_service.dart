import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_user/question_message.dart';

/// 管理者権限前提: 問い合わせチャットの運営対応を行う管理者専用サービス。
class AdminQuestionChatService {
  final _db = FirebaseFirestore.instance;

  /// 取得対象データ: QuestionChat/{chatId}/Messages の全メッセージ。
  /// 更新可否: このメソッドは読み取り専用（更新なし）。
  /// user 問い合わせ画面の取得処理と共通だが、差分理由: 管理者は全体対応のため担当外チャットも閲覧対象にする。
  /// 特定チャットのメッセージストリームを取得
  Stream<List<Message>> messageStream(String chatId) {
    // 次は Firestore QuestionChat/{chatId}/Messages の購読処理へ渡す。
    return _db
        .collection("QuestionChat")
        .doc(chatId)
        .collection("Messages")
        .orderBy("CreatedAt")
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// 取得対象データ: chatId 配下への送信先参照（書き込み前提）。
  /// 更新可否: Messages 追加と QuestionChat メタ情報更新を実施する。
  /// user 送信処理との差分理由: 管理側は対応ステータスを in_progress へ自動遷移させる。
  /// 管理者としてメッセージを送信
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    // 次は Firestore の Messages 追加と QuestionChat メタ更新処理へ渡す。
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

  /// 取得対象データ: QuestionChat ドキュメント（担当者管理対象）。
  /// 更新可否: AdminID と UpdatedAt を更新可能。
  /// チャット担当者を割り当て
  Future<void> assignAdmin(String chatId, String adminId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "AdminID": adminId,
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 取得対象データ: Read=false のメッセージ群。
  /// 更新可否: 該当メッセージの Read を true に更新可能。
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
  
  /// 取得対象データ: QuestionChat ドキュメントの Status。
  /// 更新可否: Status を resolved に更新可能。
  /// ✅ 新規追加: チャットステータスを「対応済」に変更
  Future<void> markAsResolved(String chatId) async {
    // 次は Firestore QuestionChat ドキュメントの Status 更新処理へ渡す。
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "resolved",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 取得対象データ: QuestionChat ドキュメントの Status。
  /// 更新可否: Status を in_progress に更新可能。
  /// ✅ 新規追加: チャットステータスを「対応中」に変更
  Future<void> markAsInProgress(String chatId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "in_progress",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// 取得対象データ: QuestionChat ドキュメントの Status。
  /// 更新可否: Status を pending に更新可能。
  /// ✅ 新規追加: チャットステータスを「未対応」に戻す
  Future<void> markAsPending(String chatId) async {
    await _db.collection("QuestionChat").doc(chatId).update({
      "Status": "pending",
      "UpdatedAt": FieldValue.serverTimestamp(),
    });
  }
}
