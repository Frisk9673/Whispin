import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../services/block_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/responsive.dart';
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
    final isMobile = context.isMobile;
    final padding = context.responsiveHorizontalPadding;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Column(
        children: [
          // ブロックリスト
          Expanded(
            child: _isLoading
                ? LoadingWidget(
                    color: AppColors.error,
                  )
                : _blockedUsers.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.check_circle_outline,
                        title: 'ブロック中のユーザーはいません',
                        iconColor: AppColors.success,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBlockedUsers,
                        color: AppColors.error,
                        backgroundColor: isDark 
                          ? AppColors.darkSurface
                          : Colors.white,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding.left,
                            vertical: isMobile ? 12 : AppConstants.defaultPadding,
                          ),
                          itemCount: _blockedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _blockedUsers[index];
                            return _buildBlockedUserCard(
                              user,
                              index,
                              isMobile,
                              isDark,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(
    Map<String, String> user,
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
          color: isDark 
            ? AppColors.error.withOpacity(0.3)
            : AppColors.error,
          width: isDark ? 1 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: isMobile ? 40 : 48,
          height: isMobile ? 40 : 48,
          decoration: BoxDecoration(
            color: isDark
              ? AppColors.error.withOpacity(0.2)
              : AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.error.withOpacity(isDark ? 0.4 : 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.block,
            color: AppColors.error,
            size: isMobile ? 20 : 24,
          ),
        ),
        title: Text(
          user['name']!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          user['id']!,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton(
          onPressed: () => _unblockUser(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
              ? AppColors.info.withOpacity(0.8)
              : AppColors.info,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
            elevation: isDark ? 2 : 4,
          ),
          child: Text(
            '解除',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: context.responsiveFontSize(14),
            ),
          ),
        ),
      ),
    );
  }
}
