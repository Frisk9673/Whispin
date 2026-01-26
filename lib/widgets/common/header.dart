import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/friendship_repository.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/routes.dart';

/// 統一されたヘッダーコンポーネント（AppBar形式）
///
/// フレンドリクエスト数をリアルタイムで表示
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

  /// フレンドリクエスト数を取得
  Future<int> _getFriendRequestCount(BuildContext context) async {
    try {
      final userProvider = context.read<UserProvider>();
      final currentUserId = userProvider.currentUser?.id;

      if (currentUserId == null) return 0;

      final friendRequestRepository = FriendRequestRepository();
      final requests =
          await friendRequestRepository.findReceivedRequests(currentUserId);

      return requests.length;
    } catch (e) {
      return 0;
    }
  }

  void _handleNotificationPressed(BuildContext context) {
    if (onNotificationPressed != null) {
      onNotificationPressed!();
    } else {
      // デフォルト: フレンドリクエスト画面へ遷移
      Navigator.of(context).pushNamed(AppRoutes.friendRequests);
    }
  }

  void _handleProfilePressed(BuildContext context) {
    if (onProfilePressed != null) {
      onProfilePressed!();
    } else {
      // デフォルト: プロフィール画面へ遷移
      Navigator.of(context).pushNamed(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

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
          FutureBuilder<int>(
            future: _getFriendRequestCount(context),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _handleNotificationPressed(context),
                    tooltip: '通知',
                  ),
                  if (count > 0)
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
                            count > 99 ? '99+' : '$count',
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
              );
            },
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
