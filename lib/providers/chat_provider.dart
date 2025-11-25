import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  String? chatId;
  bool loading = true;

  Future<void> loadChat() async {
    loading = true;
    notifyListeners();

    chatId = await _service.createOrGetChat();

    loading = false;
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (chatId == null || text.trim().isEmpty) return;
    await _service.sendMessage(chatId: chatId!, text: text);
  }
}
