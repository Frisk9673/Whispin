import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_cache_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/routes.dart';
import '../../constants/responsive.dart';
import '../../utils/app_logger.dart';

/// レスポンシブ対応の統一ヘッダーコンポーネント
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

    // ユーザー情報が読み込まれた後に初回ロード＋自動リフレッシュ開始
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

  /// キャッシュから通知数を取得し、必要に応じて再取得する。
  /// 画面遷移時に呼ばれる。
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

    // 通知画面へ遷移
    await Navigator.of(context).pushNamed(AppRoutes.friendRequests);

    // 戻ってきたら強制リフレッシュ
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
      Navigator.of(context).pushNamed(AppRoutes.profile);
    }
  }

  // ===== ビルド =====

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isMobile = context.isMobile;

    return AppBar(
      title: _buildTitle(context),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
      elevation: 4,
      centerTitle: isMobile,
      actions: _buildActions(context, userProvider, isMobile),
    );
  }

  /// タイトル部分を構築（レスポンシブ対応）
  Widget _buildTitle(BuildContext context) {
    if (context.isMobile && widget.title.length > 15) {
      return Text(
        widget.title.length > 12
            ? '${widget.title.substring(0, 12)}...'
            : widget.title,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textWhite,
          fontSize: context.responsiveFontSize(18),
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      widget.title,
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

    if (widget.showNotifications) {
      actions.add(_buildNotificationButton(isMobile));
    }

    if (widget.showProfile) {
      actions.add(_buildProfileButton(isMobile));
    }

    if (widget.showPremiumBadge && userProvider.isPremium) {
      actions.add(_buildPremiumBadge(context, isMobile));
    }

    if (widget.additionalActions != null) {
      actions.addAll(widget.additionalActions!);
    }

    return actions;
  }

  /// 通知ボタンを構築
  /// キャッシュから保持中の _notificationCount を直接使用
  Widget _buildNotificationButton(bool isMobile) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            size: isMobile ? 22 : 24,
          ),
          onPressed: _handleNotificationPressed,
          tooltip: '通知',
          padding:
              isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
        ),
        if (_notificationCount > 0)
          _buildNotificationBadge(_notificationCount, isMobile),
      ],
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
  Widget _buildProfileButton(bool isMobile) {
    return IconButton(
      icon: Icon(
        Icons.person,
        size: isMobile ? 22 : 24,
      ),
      onPressed: _handleProfilePressed,
      tooltip: 'プロフィール',
      padding: isMobile ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
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