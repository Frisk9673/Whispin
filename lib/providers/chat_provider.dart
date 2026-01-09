import 'package:flutter/material.dart';
import '../services/question_chat.dart';
import '../models/administrator.dart';

class ChatProvider extends ChangeNotifier {
  final QuestionChatService _service = QuestionChatService();

  /// 管理者情報（ユーザ側では null）
  final Administrator? administrator;

  ChatProvider({this.administrator});

  String? chatId;
  bool loading = true;

  // =========================
  // ユーザ用：新規 or 既存チャット
  // =========================
  Future<void> loadChat() async {
    loading = true;
    notifyListeners();

    chatId = await _service.createOrGetChat();

    loading = false;
    notifyListeners();
  }

  // =========================
  // 管理者用：既存チャットを開く
  // =========================
  Future<void> loadChatAsAdmin(String chatId) async {
    loading = true;
    notifyListeners();

    this.chatId = chatId;

    loading = false;
    notifyListeners();
  }

  // =========================
  // メッセージ送信（共通）
  // =========================
  Future<void> send(String text) async {
    if (chatId == null || text.trim().isEmpty) return;

    final senderRole =
        administrator != null && administrator!.role == 'admin'
            ? 'admin'
            : 'user';

    await _service.sendMessage(
      chatId: chatId!,
      text: text,
      senderRole: senderRole,
    );
  }
}
