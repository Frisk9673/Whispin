import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../repositories/friendship_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/block_repository.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FriendshipRepository _friendshipRepository = FriendshipRepository();
  final UserRepository _userRepository = UserRepository();
  final BlockRepository _blockRepository = BlockRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _logName = 'FriendListScreen';

  bool _isLoading = true;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    logger.section('_loadFriends() 開始', name: _logName);

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        logger.warning('未ログイン', name: _logName);
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email!;

      logger.start('Repository経由でフレンド一覧取得中...', name: _logName);

      final friendships = await _friendshipRepository.findUserFriends(currentUserEmail);

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

      setState(() {
        _friends = friendsList;
        _isLoading = false;
      });

      logger.success('フレンド一覧表示準備完了: ${_friends.length}人', name: _logName);
      logger.section('_loadFriends() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('フレンド一覧取得エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      _showError('フレンド一覧の取得に失敗しました: $e');
    }
  }

  /// ✅ フレンド削除 or ブロック選択ダイアログ
  Future<void> _showRemoveOptions(int index) async {
    final friend = _friends[index];

    logger.section('フレンド削除/ブロック選択', name: _logName);
    logger.info('対象フレンド: ${friend['name']}', name: _logName);

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.person_remove, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('フレンド削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${friend['name']} との関係を解除します。',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'どのように削除しますか？',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('キャンセル'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'remove'),
            icon: const Icon(Icons.person_remove),
            label: const Text('フレンド削除のみ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'block'),
            icon: const Icon(Icons.block),
            label: const Text('ブロックして削除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
          ),
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

  /// フレンド削除のみ
  Future<void> _removeFriend(int index) async {
    final friend = _friends[index];
    final currentUserEmail = _auth.currentUser!.email!;

    logger.section('フレンド削除開始', name: _logName);
    logger.info('対象: ${friend['name']}', name: _logName);

    context.showLoadingDialog(message: '削除中...');

    try {
      logger.start('Repository経由でフレンドシップ削除中...', name: _logName);

      await _friendshipRepository.removeFriendship(
        currentUserEmail,
        friend['id'],
      );

      logger.success('フレンドシップ削除完了', name: _logName);

      context.hideLoadingDialog();

      setState(() {
        _friends.removeAt(index);
      });

      if (!mounted) return;

      context.showSuccessSnackBar('フレンドを削除しました');

      logger.section('フレンド削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('削除エラー: $e', name: _logName, error: e, stackTrace: stack);
      context.hideLoadingDialog();
      if (!mounted) return;
      _showError('削除に失敗しました: $e');
    }
  }

  /// ✅ ブロックしてフレンド削除
  Future<void> _blockAndRemoveFriend(int index) async {
    final friend = _friends[index];
    final currentUserEmail = _auth.currentUser!.email!;

    logger.section('ブロック&削除開始', name: _logName);
    logger.info('対象: ${friend['name']}', name: _logName);

    context.showLoadingDialog(message: 'ブロック中...');

    try {
      // 1. ブロック追加
      logger.start('Repository経由でブロック追加中...', name: _logName);
      await _blockRepository.blockUser(currentUserEmail, friend['id']);
      logger.success('ブロック追加完了', name: _logName);

      // 2. フレンドシップ削除
      logger.start('フレンドシップ削除中...', name: _logName);
      await _friendshipRepository.removeFriendship(
        currentUserEmail,
        friend['id'],
      );
      logger.success('フレンドシップ削除完了', name: _logName);

      context.hideLoadingDialog();

      setState(() {
        _friends.removeAt(index);
      });

      if (!mounted) return;

      context.showWarningSnackBar('ブロックしてフレンドを削除しました');

      logger.section('ブロック&削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('ブロック&削除エラー: $e', name: _logName, error: e, stackTrace: stack);
      context.hideLoadingDialog();
      if (!mounted) return;
      _showError('処理に失敗しました: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    context.showErrorSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'フレンド一覧',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // サブヘッダー
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'フレンド一覧',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // フレンドリスト
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'フレンドがいません',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFriends,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding,
                          ),
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: AppConstants.cardElevation,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.defaultBorderRadius,
                                ),
                                side: BorderSide(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    friend['name']![0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  friend['name']!,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  friend['id']!,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => _showRemoveOptions(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}