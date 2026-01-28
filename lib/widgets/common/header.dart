import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/friendship_repository.dart';
import '../../services/invitation_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/routes.dart';
import '../../constants/responsive.dart';
import '../../utils/app_logger.dart';

/// レスポンシブ対応の統一ヘッダーコンポーネント
class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotifications;
  final bool showProfile;
  final bool showPremiumBadge;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final List<Widget>? additionalActions;

  static const String _logName = 'CommonHeader';

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

  /// フレンドリクエスト数 + 招待数を取得
  Future<int> _getNotificationCount(BuildContext context) async {
    try {
      final userProvider = context.read<UserProvider>();
      final currentUserId = userProvider.currentUser?.id;

      if (currentUserId == null) return 0;

      // フレンドリクエスト数を取得
      final friendRequestRepository = FriendRequestRepository();
      final friendRequests =
          await friendRequestRepository.findReceivedRequests(currentUserId);

      logger.debug('フレンドリクエスト数: ${friendRequests.length}', name: _logName);

      // 招待数を取得
      final invitationService = context.read<InvitationService>();
      final invitations =
          invitationService.getReceivedInvitations(currentUserId);

      logger.debug('招待数: ${invitations.length}', name: _logName);

      final totalCount = friendRequests.length + invitations.length;
      logger.debug('合計通知数: $totalCount', name: _logName);

      return totalCount;
    } catch (e, stack) {
      logger.error('通知数取得エラー: $e', 
          name: _logName, error: e, stackTrace: stack);
      return 0;
    }
  }

  void _handleNotificationPressed(BuildContext context) {
    if (onNotificationPressed != null) {
      onNotificationPressed!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.friendRequests);
    }
  }

  void _handleProfilePressed(BuildContext context) {
    if (onProfilePressed != null) {
      onProfilePressed!();
    } else {
      Navigator.of(context).pushNamed(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMobile = context.isMobile;

    return AppBar(
      title: _buildTitle(context),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
      elevation: 4,
      // モバイルではタイトルを中央に配置
      centerTitle: isMobile,
      actions: _buildActions(context, userProvider, isMobile),
    );
  }

  /// タイトル部分を構築（レスポンシブ対応）
  Widget _buildTitle(BuildContext context) {
    // モバイルでは短縮タイトル
    if (context.isMobile && title.length > 15) {
      return Text(
        title.length > 12 ? '${title.substring(0, 12)}...' : title,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textWhite,
          fontSize: context.responsiveFontSize(18),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      title,
      style: AppTextStyles.titleLarge.copyWith(
        color: AppColors.textWhite,
        fontSize: context.responsiveFontSize(20),
      ),
    );
  }

  /// アクション部分を構築（レスポンシブ対応）
  List<Widget> _buildActions(
    BuildContext context,
    UserProvider userProvider,
    bool isMobile,
  ) {
    final actions = <Widget>[];

    // 通知アイコン
    if (showNotifications) {
      actions.add(_buildNotificationButton(context, isMobile));
    }

    // プロフィールアイコン
    if (showProfile) {
      actions.add(_buildProfileButton(context, isMobile));
    }

    // プレミアムバッジ
    if (showPremiumBadge && userProvider.isPremium) {
      actions.add(_buildPremiumBadge(context, isMobile));
    }

    // 追加アクション
    if (additionalActions != null) {
      actions.addAll(additionalActions!);
    }

    return actions;
  }

  /// 通知ボタンを構築
  Widget _buildNotificationButton(BuildContext context, bool isMobile) {
    return FutureBuilder<int>(
      future: _getNotificationCount(context),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                size: isMobile ? 22 : 24,
              ),
              onPressed: () => _handleNotificationPressed(context),
              tooltip: '通知',
              padding: isMobile 
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.all(12),
            ),
            if (count > 0) _buildNotificationBadge(count, isMobile),
          ],
        );
      },
    );
  }

  /// 通知バッジを構築
  Widget _buildNotificationBadge(int count, bool isMobile) {
    return Positioned(
      right: isMobile ? 6 : 8,
      top: isMobile ? 6 : 8,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 3 : 4),
        constraints: BoxConstraints(
          minWidth: isMobile ? 16 : 18,
          minHeight: isMobile ? 16 : 18,
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
              fontSize: isMobile ? 9 : 10,
            ),
          ),
        ),
      ),
    );
  }

  /// プロフィールボタンを構築
  Widget _buildProfileButton(BuildContext context, bool isMobile) {
    return IconButton(
      icon: Icon(
        Icons.person,
        size: isMobile ? 22 : 24,
      ),
      onPressed: () => _handleProfilePressed(context),
      tooltip: 'プロフィール',
      padding: isMobile 
          ? const EdgeInsets.all(8)
          : const EdgeInsets.all(12),
    );
  }

  /// プレミアムバッジを構築
  Widget _buildPremiumBadge(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 4 : 8),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: isMobile ? 3 : 4,
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
                size: isMobile ? 14 : 16,
                color: AppColors.textWhite,
              ),
              if (!isMobile) ...[
                const SizedBox(width: 4),
                Text(
                  'Premium',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 10 : 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}