import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../services/block_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _logName = 'BlockListScreen';

  bool _isLoading = true;
  List<Map<String, String>> _blockedUsers = [];

  late BlockService _blockService;

  @override
  void initState() {
    super.initState();
    _blockService = context.read<BlockService>();
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

      logger.start('Service経由でブロック一覧取得中...', name: _logName);

      final blockedList = await _blockService.getBlockedUsersWithInfo(
        currentUserEmail,
      );

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
      context.showErrorSnackBar('ブロック一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _unblockUser(int index) async {
    final user = _blockedUsers[index];

    logger.section('_unblockUser() 開始', name: _logName);
    logger.info('対象ユーザー: ${user['name']}', name: _logName);

    final result = await context.showConfirmDialog(
      title: 'ブロック解除',
      message: '${user['name']} のブロックを解除しますか？',
      confirmText: '解除',
      cancelText: 'キャンセル',
    );

    if (!result) {
      logger.info('解除キャンセル', name: _logName);
      return;
    }

    try {
      logger.start('Service経由でブロック解除中...', name: _logName);

      await _blockService.unblockById(user['blockId']!);

      logger.success('ブロック解除完了', name: _logName);

      setState(() {
        _blockedUsers.removeAt(index);
      });

      if (!mounted) return;

      context.showSuccessSnackBar('ブロックを解除しました');

      logger.section('_unblockUser() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('ブロック解除エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      context.showErrorSnackBar('ブロック解除に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'ブロック一覧',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // セクションヘッダー（統一ウィジェット使用）
          SectionHeader(
            icon: Icons.block,
            title: 'ブロック一覧',
            color: AppColors.error,
          ),

          // ブロックリスト
          Expanded(
            child: _isLoading
                ? LoadingWidget( // 統一ウィジェット使用
                    color: AppColors.error,
                  )
                : _blockedUsers.isEmpty
                    ? EmptyStateWidget( // 統一ウィジェット使用
                        icon: Icons.check_circle_outline,
                        title: 'ブロック中のユーザーはいません',
                        iconColor: AppColors.success,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBlockedUsers,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding,
                          ),
                          itemCount: _blockedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _blockedUsers[index];
                            return ListItemCard( // 統一ウィジェット使用
                              leading: CircleAvatar(
                                backgroundColor: AppColors.error,
                                child: const Icon(
                                  Icons.block,
                                  color: Colors.white,
                                ),
                              ),
                              title: user['name']!,
                              subtitle: user['id']!,
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
                              borderColor: AppColors.error,
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