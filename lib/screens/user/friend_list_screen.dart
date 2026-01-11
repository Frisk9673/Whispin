import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../repositories/friendship_repository.dart';
import '../../repositories/user_repository.dart';
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
      if (currentUser == null) {
        logger.warning('未ログイン', name: _logName);
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email;
      if (currentUserEmail == null) {
        logger.warning('メールアドレスなし', name: _logName);
        setState(() => _isLoading = false);
        return;
      }

      logger.start('Repository経由でフレンド一覧取得中...', name: _logName);

      // Repository経由でフレンド一覧を取得
      final friendships = await _friendshipRepository.findUserFriends(currentUserEmail);

      logger.success('フレンドシップ取得: ${friendships.length}件', name: _logName);

      // フレンドのユーザー情報を取得
      final List<Map<String, dynamic>> friendsList = [];

      for (var friendship in friendships) {
        // 相手のIDを特定
        final friendId = friendship.userId == currentUserEmail
            ? friendship.friendId
            : friendship.userId;

        logger.debug('フレンドID: $friendId を取得中...', name: _logName);

        try {
          // Repository経由でユーザー情報を取得
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
      logger.error('フレンド一覧取得エラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      _showError('フレンド一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _removeFriend(int index) async {
    final friend = _friends[index];

    logger.section('_removeFriend() 開始', name: _logName);
    logger.info('対象フレンド: ${friend['name']}', name: _logName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text('フレンド削除', style: AppTextStyles.titleLarge),
        content: Text(
          '${friend['name']} をフレンドから削除しますか?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) {
      logger.info('削除キャンセル', name: _logName);
      return;
    }

    try {
      logger.start('Repository経由でフレンドシップ削除中...', name: _logName);

      // Repository経由で削除（ソフトデリート）
      await _friendshipRepository.deactivateFriendship(friend['friendshipId']);

      logger.success('フレンドシップ削除完了', name: _logName);

      setState(() {
        _friends.removeAt(index);
      });

      if (!mounted) return;

      // ✅ context拡張メソッド使用
      context.showSuccessSnackBar('フレンドを削除しました');

      logger.section('_removeFriend() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('削除エラー: $e', name: _logName, error: e, stackTrace: stack);
      _showError('削除に失敗しました: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    // ✅ context拡張メソッド使用
    context.showErrorSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(
              onProfilePressed: () {},
              onSettingsPressed: () {},
            ),
            Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: const [
                  Icon(
                    Icons.people,
                    size: 32,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'フレンド一覧',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _friends.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'フレンドがいません',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: AppConstants.cardElevation,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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
                                    Icons.person_remove,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _removeFriend(index),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: AppColors.border,
                      width: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 40,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}