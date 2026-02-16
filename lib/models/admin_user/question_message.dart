import 'package:cloud_firestore/cloud_firestore.dart';

/// Message は、問い合わせチャット内の単一メッセージを表すモデル。
/// 主に `question_chats/{chatId}/messages` サブコレクションで利用する。
///
/// フォーマット規約:
/// - ID (`id`) はドキュメント ID 文字列。
/// - 日付 (`createdAt`) は Firestore Timestamp。
/// - 列挙相当値は持たず、`isAdmin` で送信者種別を表現する。
///
/// 関連モデル:
/// - QuestionChat (`lib/models/admin_user/question_chat.dart`) に所属する。
/// - User / Administrator の送信内容を `isAdmin` で識別する。
class Message {
  final String id;
  final bool isAdmin;
  final String text;
  final Timestamp createdAt;
  final bool read;

  Message({
    required this.id,
    required this.isAdmin,
    required this.text,
    required this.createdAt,
    required this.read,
  });

  // fromFirestore(fromMap 相当): 必須キー=なし, 任意キー=IsAdmin/Text/CreatedAt/Read
  // デフォルト値=isAdmin:false, text:'', createdAt:Timestamp.now(), read:false
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      isAdmin: data["IsAdmin"] ?? false,
      text: data["Text"] ?? "",
      createdAt: data["CreatedAt"] ?? Timestamp.now(),
      read: data["Read"] ?? false,
    );
  }

  // toMap: 必須キー=ID/IsAdmin/Text/CreatedAt/Read, 任意キー=なし, デフォルト値=なし
  Map<String, dynamic> toMap() {
    return {
      "ID": id,
      "IsAdmin": isAdmin,
      "Text": text,
      "CreatedAt": createdAt,
      "Read": read,
    };
  }
}
