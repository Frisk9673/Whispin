import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../services/storage_service.dart';

/// 統一されたヘッダーコンポーネント（AppBar形式）
/// 
/// ホーム画面のヘッダー仕様に統一:
/// - AppColors.primary背景
/// - 通知バッジ（フレンドリクエスト数）
/// - プロフィールアイコン
/// - プレミアムバッジ
class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotifications;
  final bool showProfile;
  final bool showPremiumBadge;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final List<Widget>? additionalActions;

  const CommonHeader({
    super.key,
    this.title = AppConstants.appName,
    this.showNotifications = true,
    this.showProfile = true,
    this.showPremiumBadge = true,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.additionalActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  int _getPendingFriendRequestCount(BuildContext context) {
    try {
      final storageService = context.read<StorageService>();
      final userProvider = context.read<UserProvider>();
      final currentUserId = userProvider.currentUser?.id ?? '';
      
      return storageService.friendRequests
          .where((r) => r.receiverId == currentUserId && r.isPending)
          .length;
    } catch (e) {
      return 0;
    }
  }

  void _handleNotificationPressed(BuildContext context) {
    if (onNotificationPressed != null) {
      onNotificationPressed!();
    } else {
      // デフォルト: フレンドリクエスト画面へ遷移
      NavigationHelper.toFriendList(context);
    }
  }

  void _handleProfilePressed(BuildContext context) {
    if (onProfilePressed != null) {
      onProfilePressed!();
    } else {
      // デフォルト: プロフィール画面へ遷移
      NavigationHelper.toProfile(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final pendingCount = showNotifications ? _getPendingFriendRequestCount(context) : 0;

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textWhite,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
      elevation: 4,
      actions: [
        // 通知アイコン（フレンドリクエスト）
        if (showNotifications)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _handleNotificationPressed(context),
                tooltip: 'フレンドリクエスト',
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

        // プロフィールアイコン
        if (showProfile)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _handleProfilePressed(context),
            tooltip: 'プロフィール',
          ),

        // プレミアムバッジ
        if (showPremiumBadge && userProvider.isPremium)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.premiumGold,
                      AppColors.premiumGold.darken(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumGold.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond,
                      size: 16,
                      color: AppColors.textWhite,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 追加のアクション
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
}