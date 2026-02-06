import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/user/profile.dart';
import '../../services/notification_cache_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/routes.dart';
import '../../constants/responsive.dart';
import '../../utils/app_logger.dart';

/// レスポンシブ対応の統一ヘッダーコンポーネント（ダークモード対応版）
///
/// 通知数は NotificationCacheService のキャッシュを経由し、
/// 画面遷移時に再取得・5分ごとに自動リフレッシュする。
class CommonHeader extends StatefulWidget implements PreferredSizeWidget {
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

  @override
  State<CommonHeader> createState() => _CommonHeaderState();
}

class _CommonHeaderState extends State<CommonHeader> {
  static const String _logName = 'CommonHeader';

  int _notificationCount = 0;
  bool _isFirstLoad = true;

  late NotificationCacheService _cacheService;
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _cacheService = context.read<NotificationCacheService>();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userId = _userProvider.currentUser?.id;
    if (userId != null && _isFirstLoad) {
      _isFirstLoad = false;
      _loadNotificationCount(userId);
      _cacheService.startAutoRefresh(userId);
    }
  }

  @override
  void dispose() {
    _cacheService.stopAutoRefresh();
    super.dispose();
  }

  // ===== 通知数取得 =====

  Future<void> _loadNotificationCount(String userId) async {
    try {
      final count = await _cacheService.getCount(userId: userId);

      if (!mounted) return;
      if (count != _notificationCount) {
        setState(() => _notificationCount = count);
      }
    } catch (e) {
      logger.error('通知数取得エラー: $e', name: _logName, error: e);
    }
  }

  // ===== イベントハンドラー =====

  Future<void> _handleNotificationPressed() async {
    if (widget.onNotificationPressed != null) {
      widget.onNotificationPressed!();
      return;
    }

    await Navigator.of(context).pushNamed(AppRoutes.friendRequests);

    final userId = _userProvider.currentUser?.id;
    if (userId != null && mounted) {
      _cacheService.invalidateCache();
      await _loadNotificationCount(userId);
    }
  }

  void _handleProfilePressed() {
    if (widget.onProfilePressed != null) {
      widget.onProfilePressed!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: const RouteSettings(name: AppRoutes.profile),
        ),
      );
    }
  }

  // ===== ビルド =====

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMobile = context.isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: _buildTitle(context, isDark),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
      foregroundColor: isDark ? Colors.white : AppColors.textWhite,
      elevation: isDark ? 2 : 4,
      centerTitle: isMobile,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : AppColors.textWhite,
      ),
      actions: _buildActions(context, userProvider, isMobile, isDark),
    );
  }

  /// タイトル部分を構築（ダークモード対応）
  Widget _buildTitle(BuildContext context, bool isDark) {
    final isMobile = context.isMobile;

    if (isMobile && widget.title.length > 15) {
      return Text(
        widget.title.length > 12
            ? '${widget.title.substring(0, 12)}...'
            : widget.title,
        style: AppTextStyles.titleMedium.copyWith(
          color: isDark ? Colors.white : AppColors.textWhite,
          fontSize: context.responsiveFontSize(18),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      widget.title,
      style: AppTextStyles.titleLarge.copyWith(
        color: isDark ? Colors.white : AppColors.textWhite,
        fontSize: context.responsiveFontSize(20),
      ),
    );
  }

  /// アクション部分を構築（ダークモード対応）
  List<Widget> _buildActions(
    BuildContext context,
    UserProvider userProvider,
    bool isMobile,
    bool isDark,
  ) {
    final actions = <Widget>[];

    if (widget.showNotifications) {
      actions.add(_buildNotificationButton(isMobile, isDark));
    }

    if (widget.showProfile) {
      actions.add(_buildProfileButton(isMobile, isDark));
    }

    if (widget.showPremiumBadge && userProvider.isPremium) {
      actions.add(_buildPremiumBadge(context, isMobile, isDark));
    }

    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }

    return actions;
  }

  /// 通知ボタンを構築（ダークモード対応）
  Widget _buildNotificationButton(bool isMobile, bool isDark) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            size: isMobile ? 22 : 24,
            color: isDark ? Colors.white : AppColors.textWhite,
          ),
          onPressed: _handleNotificationPressed,
          tooltip: '通知',
          padding:
              isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
        ),
        if (_notificationCount > 0)
          _buildNotificationBadge(_notificationCount, isMobile, isDark),
      ],
    );
  }

  /// 通知バッジを構築（ダークモード対応）
  Widget _buildNotificationBadge(int count, bool isMobile, bool isDark) {
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
          color: isDark ? Colors.red[400] : AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  isDark ? Colors.red.withOpacity(0.4) : AppColors.shadowDark,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            count > 99 ? '99+' : '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 9 : 10,
            ),
          ),
        ),
      ),
    );
  }

  /// プロフィールボタンを構築（ダークモード対応）
  Widget _buildProfileButton(bool isMobile, bool isDark) {
    return IconButton(
      icon: Icon(
        Icons.person,
        size: isMobile ? 22 : 24,
        color: isDark ? Colors.white : AppColors.textWhite,
      ),
      onPressed: _handleProfilePressed,
      tooltip: 'プロフィール',
      padding: isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
    );
  }

  /// プレミアムバッジを構築（ダークモード対応）
  Widget _buildPremiumBadge(BuildContext context, bool isMobile, bool isDark) {
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
              colors: isDark
                  ? [
                      AppColors.premiumGold.withOpacity(0.9),
                      AppColors.premiumGold.darken(0.1).withOpacity(0.9),
                    ]
                  : [
                      AppColors.premiumGold,
                      AppColors.premiumGold.darken(0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.premiumGold.withOpacity(isDark ? 0.4 : 0.3),
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
                color: Colors.white,
              ),
              if (!isMobile) ...[
                const SizedBox(width: 4),
                Text(
                  'Premium',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
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