import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../models/question_message.dart';
import '../../constants/colors.dart';

class AdminQuestionChatScreen extends StatefulWidget {
  final String chatId;

  const AdminQuestionChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<AdminQuestionChatScreen> createState() =>
      _AdminQuestionChatScreenState();
}

class _AdminQuestionChatScreenState extends State<AdminQuestionChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 管理者としてチャット購読開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.startMessageStream(widget.chatId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    final provider = Provider.of<AdminProvider>(context, listen: false);
    provider.disposeMessageStream();

    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);
    await provider.sendMessage(widget.chatId, text);

    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ対応'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // メッセージ一覧
          Expanded(
            child: provider.messages.isEmpty
                ? const Center(
                    child: Text(
                      'メッセージがありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                      return _buildMessageBubble(provider.messages[index]);
                    },
                  ),
          ),

          // 入力欄
          _buildInputArea(),
        ],
      ),
    );
  }

  /// メッセージ吹き出し
  Widget _buildMessageBubble(Message message) {
    final isAdmin = message.isAdmin;
    final alignment = isAdmin ? Alignment.centerRight : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisAlignment:
              isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isAdmin) ...[
              _buildAvatar(false),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isAdmin ? AppColors.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isAdmin ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              _buildAvatar(true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isAdmin) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isAdmin ? AppColors.primary : Colors.grey,
      child: Icon(
        isAdmin ? Icons.support_agent : Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// 入力エリア
  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '返信を入力...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: AppColors.primary,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
