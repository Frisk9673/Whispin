import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../repositories/friendship_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/friend_request.dart';
import '../../models/friendship.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/datetime_extensions.dart';
import '../../utils/app_logger.dart';

/// フレンドリクエスト画面
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendRequestRepository _friendRequestRepository = FriendRequestRepository();
  final FriendshipRepository _friendshipRepository = FriendshipRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logName = 'FriendRequestsScreen';

  bool _isLoading = true;
  List<FriendRequest> _friendRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    logger.section('フレンドリクエスト読み込み開始', name: _logName);

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
      logger.start('Repository経由でフレンドリクエスト取得中...', name: _logName);
      _friendRequests = await _friendRequestRepository.findReceivedRequests(currentUserEmail);
      
      logger.success('フレンドリクエスト取得: ${_friendRequests.length}件', name: _logName);

      setState(() => _isLoading = false);

      logger.section('フレンドリクエスト読み込み完了', name: _logName);
    } catch (e, stack) {
      logger.error('読み込みエラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      
      if (mounted) {
        context.showErrorSnackBar('読み込みに失敗しました: $e');
      }
    }
  }

  Future<void> _acceptFriendRequest(FriendRequest request) async {
    logger.section('フレンドリクエスト承認開始', name: _logName);
    logger.info('requestId: ${request.id}', name: _logName);
    logger.info('senderId: ${request.senderId}', name: _logName);
    logger.info('receiverId: ${request.receiverId}', name: _logName);

    context.showLoadingDialog(message: '承認中...');

    try {
      // 1. リクエストを承認状態に更新
      logger.start('リクエスト承認処理中...', name: _logName);
      await _friendRequestRepository.acceptRequest(request.id);
      logger.success('リクエスト承認完了', name: _logName);

      // 2. フレンドシップを作成
      logger.start('フレンドシップ作成中...', name: _logName);
      final friendship = Friendship(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: request.senderId,
        friendId: request.receiverId,
        active: true,
        createdAt: DateTime.now(),
      );

      logger.debug('Friendship作成:', name: _logName);
      logger.debug('  id: ${friendship.id}', name: _logName);
      logger.debug('  userId: ${friendship.userId}', name: _logName);
      logger.debug('  friendId: ${friendship.friendId}', name: _logName);
      logger.debug('  active: ${friendship.active}', name: _logName);

      await _friendshipRepository.create(friendship, id: friendship.id);
      logger.success('フレンドシップ作成完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showSuccessSnackBar('フレンド申請を承認しました');
      
      // リスト再読み込み
      await _loadFriendRequests();

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
      message: 'このフレンドリクエストを拒否しますか？',
      confirmText: '拒否',
      cancelText: 'キャンセル',
    );

    if (!result) {
      logger.info('拒否キャンセル', name: _logName);
      return;
    }

    context.showLoadingDialog(message: '拒否中...');

    try {
      logger.start('リクエスト拒否処理中...', name: _logName);
      await _friendRequestRepository.rejectRequest(request.id);
      logger.success('リクエスト拒否完了', name: _logName);

      context.hideLoadingDialog();

      if (!mounted) return;

      context.showInfoSnackBar('フレンドリクエストを拒否しました');
      
      // リスト再読み込み
      await _loadFriendRequests();

      logger.section('フレンドリクエスト拒否処理完了', name: _logName);
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
        title: 'フレンドリクエスト',
        showNotifications: false,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _friendRequests.isEmpty
              ? _buildEmptyState()
              : _buildRequestList(),
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
            'フレンドリクエストはありません',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいリクエストが届くとここに表示されます',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(_friendRequests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return FutureBuilder<String>(
      future: _getSenderName(request.senderId),
      builder: (context, snapshot) {
        final senderName = snapshot.data ?? request.senderId;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                // ヘッダー（アバター + 名前）
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

                // タイムスタンプ
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

                // アクションボタン
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
}