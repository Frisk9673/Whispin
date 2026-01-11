import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/user_repository.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final BlockRepository _blockRepository = BlockRepository();
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _logName = 'BlockListScreen';

  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    logger.section('_loadBlockedUsers() 開始', name: _logName);

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

      logger.start('Repository経由でブロック一覧取得中...', name: _logName);

      // Repository経由でブロック一覧を取得
      final blocks = await _blockRepository.findBlockedUsers(currentUserEmail);

      logger.success('ブロック取得: ${blocks.length}件', name: _logName);

      // ブロックユーザーの情報を取得
      final List<Map<String, dynamic>> blockedList = [];

      for (var block in blocks) {
        logger.debug('ブロックユーザーID: ${block.blockedId} を取得中...', name: _logName);

        try {
          // Repository経由でユーザー情報を取得
          final blockedUser = await _userRepository.findById(block.blockedId);

          if (blockedUser != null) {
            blockedList.add({
              'id': block.blockedId,
              'name': blockedUser.displayName,
              'blockId': block.id,
            });
            logger.debug('  → ${blockedUser.displayName}', name: _logName);
          } else {
            logger.warning('ユーザー情報なし: ${block.blockedId}', name: _logName);
            blockedList.add({
              'id': block.blockedId,
              'name': block.blockedId,
              'blockId': block.id,
            });
          }
        } catch (e) {
          logger.error('ブロックユーザー情報取得エラー: $e', name: _logName, error: e);
          blockedList.add({
            'id': block.blockedId,
            'name': block.blockedId,
            'blockId': block.id,
          });
        }
      }

      setState(() {
        _blockedUsers = blockedList;
        _isLoading = false;
      });

      logger.success('ブロック一覧表示準備完了: ${_blockedUsers.length}人', name: _logName);
      logger.section('_loadBlockedUsers() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('ブロック一覧取得エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      _showError('ブロック一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _unblockUser(int index) async {
    final user = _blockedUsers[index];

    logger.section('_unblockUser() 開始', name: _logName);
    logger.info('対象ユーザー: ${user['name']}', name: _logName);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text('ブロック解除', style: AppTextStyles.titleLarge),
        content: Text(
          '${user['name']} のブロックを解除しますか？',
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
              backgroundColor: AppColors.info,
            ),
            child: const Text(
              '解除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) {
      logger.info('解除キャンセル', name: _logName);
      return;
    }

    try {
      logger.start('Repository経由でブロック解除中...', name: _logName);

      // Repository経由で解除（ソフトデリート）
      await _blockRepository.unblockById(user['blockId']);

      logger.success('ブロック解除完了', name: _logName);

      setState(() {
        _blockedUsers.removeAt(index);
      });

      if (!mounted) return;

      // ✅ context拡張メソッド使用
      context.showSuccessSnackBar('ブロックを解除しました');

      logger.section('_unblockUser() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('ブロック解除エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      _showError('ブロック解除に失敗しました: $e');
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
      // ✅ 統一ヘッダーを使用
      appBar: CommonHeader(
        title: 'ブロック一覧',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // サブヘッダー（アイコン付きタイトル）
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Icon(
                  Icons.block,
                  size: 32,
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'ブロック一覧',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // ブロックリスト
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.error,
                    ),
                  )
                : _blockedUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ブロック中のユーザーはいません',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                        ),
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: AppConstants.cardElevation,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius,
                              ),
                              side: BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.error,
                                child: const Icon(
                                  Icons.block,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                user['name']!,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user['id']!,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _unblockUser(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '解除',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
