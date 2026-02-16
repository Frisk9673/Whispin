import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../models/admin_user/question_message.dart';
import '../../constants/colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

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
  static const String _logName = 'AdminQuestionChatScreen';

  @override
  void initState() {
    super.initState();

    // 管理者としてチャット購読開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      // 次は AdminProvider.startMessageStream() から AdminQuestionChatService.messageStream() へ渡す。
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
    // 次は AdminProvider.sendMessage() から AdminQuestionChatService.sendMessage() へ渡す。
    await provider.sendMessage(widget.chatId, text);

    _controller.clear();
    _scrollToBottom();
  }

  /// ステータス変更ダイアログを表示
  Future<void> _showStatusChangeDialog() async {
    logger.section('ステータス変更ダイアログ表示', name: _logName);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('ステータス変更'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(
              context: ctx,
              status: 'pending',
              label: '未対応',
              icon: Icons.inbox,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context: ctx,
              status: 'in_progress',
              label: '対応中',
              icon: Icons.schedule,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context: ctx,
              status: 'resolved',
              label: '対応済',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await _changeStatus(result);
    }
  }

  Widget _buildStatusOption({
    required BuildContext context,
    required String status,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(status),
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ステータスを変更
  Future<void> _changeStatus(String newStatus) async {
    logger.section('ステータス変更処理開始', name: _logName);
    logger.info('新しいステータス: $newStatus', name: _logName);

    try {
      context.showLoadingDialog(message: 'ステータス変更中...');

      final provider = Provider.of<AdminProvider>(context, listen: false);

      // 次は AdminProvider の各ステータス更新メソッドから AdminQuestionChatService へ渡す。
      switch (newStatus) {
        case 'pending':
          await provider.markAsPending(widget.chatId);
          break;
        case 'in_progress':
          await provider.markAsInProgress(widget.chatId);
          break;
        case 'resolved':
          await provider.markAsResolved(widget.chatId);
          break;
      }

      if (!mounted) return;

      context.hideLoadingDialog();
      context.showSuccessSnackBar('ステータスを変更しました');

      logger.success('ステータス変更完了', name: _logName);
    } catch (e, stack) {
      logger.error('ステータス変更エラー: $e',
          name: _logName, error: e, stackTrace: stack);

      if (!mounted) return;

      context.hideLoadingDialog();
      context.showErrorSnackBar('ステータスの変更に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ対応'),
        actions: [
          // ステータス変更ボタンを追加␊
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _showStatusChangeDialog,
            tooltip: 'ステータス変更',
          ),
        ],
      ),
      body: Column(
        children: [
          // メッセージ一覧
          Expanded(
            child: provider.messages.isEmpty
                ? Center(
                    child: Text(
                      'メッセージがありません',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = message.isAdmin;
    final alignment = isAdmin ? Alignment.centerRight : Alignment.centerLeft;
    final userBubbleColor = colorScheme.surfaceVariant;
    final userTextColor = colorScheme.onSurface;
    final adminBubbleColor = colorScheme.primary;
    final adminTextColor = colorScheme.onPrimary;

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
                  color: isAdmin ? adminBubbleColor : userBubbleColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isAdmin ? adminTextColor : userTextColor,
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
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isAdmin ? colorScheme.primary : colorScheme.surfaceVariant,
      child: Icon(
        isAdmin ? Icons.support_agent : Icons.person,
        color: isAdmin ? colorScheme.onPrimary : colorScheme.onSurface,
        size: 18,
      ),
    );
  }

  /// 入力エリア
  Widget _buildInputArea() {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.primary,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
