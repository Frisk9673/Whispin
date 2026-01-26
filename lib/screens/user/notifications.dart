// lib/screens/user/notifications.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
import '../../repositories/user_repository.dart';
import '../../services/friendship_service.dart';
import '../../services/invitation_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/friend_request.dart';
import '../../models/invitation.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/datetime_extensions.dart';
import '../../utils/app_logger.dart';

/// 通知一覧画面（フレンドリクエスト + ルーム招待）
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logName = 'FriendRequestsScreen';

  bool _isLoading = true;
  List<FriendRequest> _friendRequests = [];
  List<Invitation> _invitations = [];

  late FriendshipService _friendshipService;
  late InvitationService _invitationService;

  @override
  void initState() {
    super.initState();
    _friendshipService = context.read<FriendshipService>();
    _invitationService = context.read<InvitationService>();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    logger.section('通知読み込み開始', name: _logName);

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        logger.warning('未ログイン', name: _logName);
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email!;
      logger.info('currentUserEmail: $currentUserEmail', name: _logName);

      // フレンドリクエスト取得
      logger.start('フレンドリクエスト取得中...', name: _logName);
      _friendRequests =
          await _friendshipService.getReceivedRequests(currentUserEmail);
      logger.success('フレンドリクエスト: ${_friendRequests.length}件', name: _logName);

      // ルーム招待取得
      logger.start('ルーム招待取得中...', name: _logName);
      _invitations =
          _invitationService.getReceivedInvitations(currentUserEmail);
      logger.success('ルーム招待: ${_invitations.length}件', name: _logName);

      setState(() => _isLoading = false);

      logger.section('通知読み込み完了', name: _logName);
    } catch (e, stack) {
      logger.error('読み込みエラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);

      if (mounted) {
        context.showErrorSnackBar('読み込みに失敗しました: $e');
      }
    }
  }

  // ===== フレンドリクエスト処理 =====

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    logger.section('フレンドリクエスト承認開始', name: _logName);
    logger.info('requestId: ${request.id}', name: _logName);
    logger.info('senderId: ${request.senderId}', name: _logName);
    logger.info('receiverId: ${request.receiverId}', name: _logName);

    context.showLoadingDialog(message: '承認中...');

    try {
      logger.start('Service経由で承認処理実行中...', name: _logName);
      await _friendshipService.acceptFriendRequest(request);
      logger.success('承認処理完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showSuccessSnackBar('フレンド申請を承認しました');

      await _loadNotifications();

      logger.section('フレンドリクエスト承認処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('承認エラー: $e', name: _logName, error: e, stackTrace: stack);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showErrorSnackBar('承認に失敗しました: $e');
    }
  }

  Future<void> _rejectFriendRequest(FriendRequest request) async {
    logger.section('フレンドリクエスト拒否開始', name: _logName);
    logger.info('requestId: ${request.id}', name: _logName);

    final result = await context.showConfirmDialog(
      title: 'フレンドリクエスト拒否',
      message: 'このフレンドリクエストを拒否しますか?',
      confirmText: '拒否',
      cancelText: 'キャンセル',
    );

    if (!result) {
      logger.info('拒否キャンセル', name: _logName);
      return;
    }

    context.showLoadingDialog(message: '拒否中...');

    try {
      logger.start('Service経由で拒否処理実行中...', name: _logName);
      await _friendshipService.rejectFriendRequest(request.id);
      logger.success('拒否処理完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showInfoSnackBar('フレンドリクエストを拒否しました');

      await _loadNotifications();

      logger.section('フレンドリクエスト拒否処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('拒否エラー: $e', name: _logName, error: e, stackTrace: stack);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showErrorSnackBar('拒否に失敗しました: $e');
    }
  }

  // ===== ルーム招待処理 =====

  Future<void> _acceptInvitation(Invitation invitation) async {
    logger.section('招待承認開始', name: _logName);
    logger.info('invitationId: ${invitation.id}', name: _logName);

    context.showLoadingDialog(message: '参加中...');

    try {
      // 招待を承認
      final updatedRoom =
          await _invitationService.acceptInvitation(invitation.id);
      logger.success('招待承認完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showSuccessSnackBar('ルームに参加しました');

      // 👇 これを追加
      await _loadNotifications();

      // 👇 そのあと遷移
      if (!mounted) return;

      // チャット画面へ遷移
      await NavigationHelper.toChat(
        context,
        roomId: updatedRoom.id,
        authService: context.read<AuthService>(),
        chatService: context.read<ChatService>(),
        storageService: context.read<StorageService>(),
      );

      logger.section('招待承認処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('承認エラー: $e', name: _logName, error: e, stackTrace: stack);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showErrorSnackBar('参加に失敗しました: $e');
    }
  }

  Future<void> _rejectInvitation(Invitation invitation) async {
    logger.section('招待拒否開始', name: _logName);
    logger.info('invitationId: ${invitation.id}', name: _logName);

    final result = await context.showConfirmDialog(
      title: 'ルーム招待を拒否',
      message: 'この招待を拒否しますか?',
      confirmText: '拒否',
      cancelText: 'キャンセル',
    );

    if (!result) {
      logger.info('拒否キャンセル', name: _logName);
      return;
    }

    context.showLoadingDialog(message: '拒否中...');

    try {
      await _invitationService.rejectInvitation(invitation.id);
      logger.success('拒否処理完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showInfoSnackBar('招待を拒否しました');

      await _loadNotifications();

      logger.section('招待拒否処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('拒否エラー: $e', name: _logName, error: e, stackTrace: stack);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showErrorSnackBar('拒否に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: '通知',
        showNotifications: false,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _friendRequests.isEmpty && _invitations.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundLight,
            ),
            child: Icon(
              Icons.inbox,
              size: 80,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '通知はありません',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しい通知が届くとここに表示されます',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // ルーム招待セクション
          if (_invitations.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.mail,
              title: 'ルーム招待',
              count: _invitations.length,
            ),
            const SizedBox(height: 12),
            ..._invitations
                .map((invitation) => _buildInvitationCard(invitation)),
            const SizedBox(height: 24),
          ],

          // フレンドリクエストセクション
          if (_friendRequests.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.person_add,
              title: 'フレンドリクエスト',
              count: _friendRequests.length,
            ),
            const SizedBox(height: 12),
            ..._friendRequests
                .map((request) => _buildFriendRequestCard(request)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    return FutureBuilder<Map<String, String>>(
      future: _getInvitationDetails(invitation),
      builder: (context, snapshot) {
        final details = snapshot.data ??
            {
              'inviterName': invitation.inviterId,
              'roomName': invitation.roomId,
            };

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            side: BorderSide(
              color: AppColors.info.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 招待者情報
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.info,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.mail,
                        color: AppColors.info,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details['inviterName']!,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'があなたを招待しました',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ルーム情報
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ルーム名',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              details['roomName']!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 時刻
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        invitation.createdAt.toRelativeTime,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptInvitation(invitation),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('参加する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectInvitation(invitation),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('拒否'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendRequestCard(FriendRequest request) {
    return FutureBuilder<String>(
      future: _getSenderName(request.senderId),
      builder: (context, snapshot) {
        final senderName = snapshot.data ?? request.senderId;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            side: BorderSide(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.textWhite,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.senderId,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.createdAt.toRelativeTime,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptFriendRequest(request),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('承認'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectFriendRequest(request),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('拒否'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getSenderName(String userId) async {
    try {
      logger.debug('ユーザー名取得: $userId', name: _logName);
      final user = await _userRepository.findById(userId);

      if (user != null) {
        logger.debug('  → ${user.displayName}', name: _logName);
        return user.displayName;
      }

      logger.warning('ユーザー情報なし: $userId', name: _logName);
      return userId;
    } catch (e) {
      logger.warning('ユーザー名取得失敗: $e', name: _logName);
      return userId;
    }
  }

  Future<Map<String, String>> _getInvitationDetails(
      Invitation invitation) async {
    try {
      final storageService = context.read<StorageService>();

      // 招待者情報を取得
      final inviter = await _userRepository.findById(invitation.inviterId);
      final inviterName = inviter?.displayName ?? invitation.inviterId;

      // ルーム情報を取得
      final room = storageService.rooms.firstWhere(
        (r) => r.id == invitation.roomId,
        orElse: () => throw Exception('ルームが見つかりません'),
      );

      return {
        'inviterName': inviterName,
        'roomName': room.topic,
      };
    } catch (e) {
      logger.error('招待詳細取得エラー: $e', name: _logName, error: e);
      return {
        'inviterName': invitation.inviterId,
        'roomName': invitation.roomId,
      };
    }
  }
}
