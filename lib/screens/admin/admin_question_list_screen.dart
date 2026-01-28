import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whispin/screens/admin/admin_question_screen.dart';
import '../../models/question_chat.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../utils/app_logger.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({super.key});

  @override
  State<AdminQuestionListScreen> createState() =>
      _AdminQuestionListScreenState();
}

class _AdminQuestionListScreenState extends State<AdminQuestionListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _logName = 'AdminQuestionListScreen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ一覧'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: _buildChatList(),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('QuestionChat')
          .orderBy('UpdatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logger.error('エラー: ${snapshot.error}', name: _logName);
          return _buildErrorView();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final chats = snapshot.data?.docs ?? [];

        if (chats.isEmpty) {
          return _buildEmptyView();
        }

        logger.info('お問い合わせ件数: ${chats.length}件', name: _logName);

        return ListView.builder(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final chat = QuestionChat.fromFirestore(chatDoc);
            return _buildChatCard(context, chat);
          },
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'データの取得に失敗しました',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'お問い合わせはありません',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, QuestionChat chat) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          logger.info('チャットタップ: ${chat.id}', name: _logName);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminQuestionChatScreen(chatId: chat.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              _buildAvatar(chat),
              const SizedBox(width: 16),
              Expanded(
                child: _buildChatInfo(chat),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(QuestionChat chat) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          chat.userId.isNotEmpty ? chat.userId[0].toUpperCase() : '?',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInfo(QuestionChat chat) {
    // ✅ ステータスに応じた色とアイコンを決定
    Color statusColor;
    IconData statusIcon;

    switch (chat.status) {
      case 'pending':
        statusColor = AppColors.error;
        statusIcon = Icons.inbox;
        break;
      case 'in_progress':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case 'resolved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                chat.userId,
                style: AppTextStyles.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ✅ ステータスバッジを改善
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 14,
                    color: AppColors.textWhite,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chat.statusText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          chat.lastMessage.isEmpty ? 'メッセージなし' : chat.lastMessage,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (chat.updatedAt != null)
          Text(
            _formatTimestamp(chat.updatedAt!),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    try {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'たった今';
      if (difference.inHours < 1) return '${difference.inMinutes}分前';
      if (difference.inDays < 1) return '${difference.inHours}時間前';
      if (difference.inDays < 7) return '${difference.inDays}日前';
      return '${dateTime.month}/${dateTime.day}';
    } catch (e) {
      return '';
    }
  }
}