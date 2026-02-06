import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/block_repository.dart';
import '../../services/friendship_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final UserRepository _userRepository = UserRepository();
  final BlockRepository _blockRepository = BlockRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _logName = 'FriendListScreen';

  bool _isLoading = true;
  List<Map<String, dynamic>> _friends = [];

  late FriendshipService _friendshipService;

  @override
  void initState() {
    super.initState();
    _friendshipService = context.read<FriendshipService>();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    logger.section('_loadFriends() 開始', name: _logName);

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        logger.warning('未ログイン', name: _logName);
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email!;

      logger.start('Service経由でフレンド一覧取得中...', name: _logName);
      final friendships =
          await _friendshipService.getUserFriends(currentUserEmail);

      logger.success('フレンドシップ取得: ${friendships.length}件', name: _logName);

      final List<Map<String, dynamic>> friendsList = [];

      for (var friendship in friendships) {
        final friendId = friendship.userId == currentUserEmail
            ? friendship.friendId
            : friendship.userId;

        logger.debug('フレンドID: $friendId を取得中...', name: _logName);

        try {
          final friendUser = await _userRepository.findById(friendId);

          if (friendUser != null) {
            friendsList.add({
              'id': friendId,
              'name': friendUser.displayName,
              'friendshipId': friendship.id,
            });
            logger.debug('  → ${friendUser.displayName}', name: _logName);
          } else {
            logger.warning('ユーザー情報なし: $friendId', name: _logName);
            friendsList.add({
              'id': friendId,
              'name': friendId,
              'friendshipId': friendship.id,
            });
          }
        } catch (e) {
          logger.error('フレンド情報取得エラー: $e', name: _logName, error: e);
          friendsList.add({
            'id': friendId,
            'name': friendId,
            'friendshipId': friendship.id,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _friends = friendsList;
        _isLoading = false;
      });

      logger.success('フレンド一覧表示準備完了: ${_friends.length}人', name: _logName);
      logger.section('_loadFriends() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('フレンド一覧取得エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showErrorSnackBar('フレンド一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _showRemoveOptions(int index) async {
    final friend = _friends[index];
    final isMobile = context.isMobile;
    final isDark = context.isDark;

    logger.section('フレンド削除/ブロック選択', name: _logName);
    logger.info('対象フレンド: ${friend['name']}', name: _logName);

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person_remove,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'フレンド削除',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(18),
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${friend['name']} との関係を解除します。',
              style: TextStyle(
                fontSize: context.responsiveFontSize(15),
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'どのように削除しますか？',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: context.responsiveFontSize(14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'キャンセル',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: isDark ? Colors.grey[400] : null,
              ),
            ),
          ),
          if (!isMobile) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'remove'),
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('フレンド削除のみ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(
                  color: isDark
                      ? AppColors.warning.withOpacity(0.8)
                      : AppColors.warning,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'block'),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('ブロックして削除'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'remove'),
                  icon: const Icon(Icons.person_remove, size: 18),
                  label: const Text('フレンド削除のみ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.warning.withOpacity(0.8)
                          : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'block'),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('ブロックして削除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (action == null) {
      logger.info('キャンセルされました', name: _logName);
      return;
    }

    if (action == 'remove') {
      await _removeFriend(index);
    } else if (action == 'block') {
      await _blockAndRemoveFriend(index);
    }
  }

  Future<void> _removeFriend(int index) async {
    final friend = _friends[index];
    final currentUserEmail = _auth.currentUser!.email!;

    logger.section('フレンド削除開始', name: _logName);
    logger.info('対象: ${friend['name']}', name: _logName);

    context.showLoadingDialog(message: '削除中...');

    try {
      logger.start('Service経由でフレンドシップ削除中...', name: _logName);

      await _friendshipService.removeFriend(
        userId1: currentUserEmail,
        userId2: friend['id'],
      );

      logger.success('フレンドシップ削除完了', name: _logName);

      if (!mounted) return;
      context.hideLoadingDialog();

      setState(() {
        _friends.removeAt(index);
      });

      context.showSuccessSnackBar('フレンドを削除しました');

      logger.section('フレンド削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('削除エラー: $e', name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      context.hideLoadingDialog();
      context.showErrorSnackBar('削除に失敗しました: $e');
    }
  }

  Future<void> _blockAndRemoveFriend(int index) async {
    final friend = _friends[index];
    final currentUserEmail = _auth.currentUser!.email!;

    logger.section('ブロック&削除開始', name: _logName);
    logger.info('対象: ${friend['name']}', name: _logName);

    context.showLoadingDialog(message: 'ブロック中...');

    try {
      logger.start('Service経由でブロック&削除処理実行中...', name: _logName);

      await _friendshipService.blockAndRemoveFriend(
        blockerId: currentUserEmail,
        blockedId: friend['id'],
        blockRepository: _blockRepository,
      );

      logger.success('ブロック&削除処理完了', name: _logName);

      if (!mounted) return;
      context.hideLoadingDialog();

      setState(() {
        _friends.removeAt(index);
      });

      context.showWarningSnackBar('ブロックしてフレンドを削除しました');

      logger.section('ブロック&削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('ブロック&削除エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      if (!mounted) return;
      context.hideLoadingDialog();
      context.showErrorSnackBar('処理に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final padding = context.responsiveHorizontalPadding;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Column(
        children: [
          // フレンドリスト
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _friends.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_off,
                        title: 'フレンドがいません',
                        subtitle: '新しいフレンドを追加しましょう',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFriends,
                        color: AppColors.primary,
                        backgroundColor:
                            isDark ? AppColors.darkSurface : Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding.left,
                            vertical:
                                isMobile ? 12 : AppConstants.defaultPadding,
                          ),
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return _buildFriendCard(
                                friend, index, isMobile, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    Map<String, dynamic> friend,
    int index,
    bool isMobile,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: BorderSide(
          color: isDark ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: isDark ? 1 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: UserAvatar(
          name: friend['name']!,
          size: isMobile ? 40 : 48,
        ),
        title: Text(
          friend['name']!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          friend['id']!,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.textSecondary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              size: isMobile ? 20 : 24,
            ),
            onPressed: () => _showRemoveOptions(index),
          ),
        ),
      ),
    );
  }
}
