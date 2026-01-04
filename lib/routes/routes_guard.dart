import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/routes.dart';
import '../utils/app_logger.dart';

/// ルートガード（認証チェック等）を管理するクラス
class RouteGuard {
  static const String _logName = 'RouteGuard';

  // プライベートコンストラクタ
  RouteGuard._();

  /// 認証が必要なルートかチェック
  static bool requiresAuth(String routeName) {
    const protectedRoutes = [
      AppRoutes.home,
      AppRoutes.profile,
      AppRoutes.createRoom,
      AppRoutes.chat,
      AppRoutes.friendList,
      AppRoutes.blockList,
      AppRoutes.userChat,
    ];

    return protectedRoutes.contains(routeName);
  }

  /// 管理者権限が必要なルートかチェック
  static bool requiresAdmin(String routeName) {
    const adminRoutes = [
      AppRoutes.adminHome,
      AppRoutes.premiumLogs,
      AppRoutes.questionChat,
    ];

    return adminRoutes.contains(routeName);
  }

  /// 認証チェック（ユーザー）
  static Future<bool> checkAuth(
    BuildContext context,
    String routeName,
    AuthService authService,
  ) async {
    if (!requiresAuth(routeName)) {
      return true;
    }

    final isLoggedIn = authService.isLoggedIn();

    if (!isLoggedIn) {
      logger.warning(
        '未認証アクセス検出: $routeName → ログイン画面へリダイレクト',
        name: _logName,
      );

      if (context.mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }

      return false;
    }

    logger.debug('認証チェック成功: $routeName', name: _logName);
    return true;
  }

  /// プレミアム会員チェック
  static bool checkPremium(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    
    if (user == null || !user.premium) {
      logger.warning('非プレミアムユーザーのアクセス', name: _logName);
      
      _showPremiumRequiredDialog(context);
      return false;
    }

    return true;
  }

  /// プレミアム必須ダイアログを表示
  static void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.diamond, color: Color(0xFF667EEA)),
            SizedBox(width: 8),
            Text('プレミアム会員限定'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('この機能はプレミアム会員限定です。'),
            SizedBox(height: 16),
            Text('プレミアムに加入すると以下の特典が利用できます:'),
            SizedBox(height: 8),
            _FeatureItem(text: 'チャット延長回数が無制限'),
            _FeatureItem(text: '優先サポート'),
            _FeatureItem(text: '広告非表示'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // プロフィール画面へ遷移
              Navigator.of(context).pushNamed(AppRoutes.profile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
            ),
            child: const Text(
              '加入する',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// ルームの参加可能チェック
  static bool checkRoomAccess(
    BuildContext context,
    String roomId,
    String userId,
  ) {
    // TODO: ルームの参加可能性チェックロジックを実装
    // - ルームが存在するか
    // - ブロックされていないか
    // - 満員でないか
    
    logger.debug('ルームアクセスチェック: roomId=$roomId, userId=$userId', name: _logName);
    return true;
  }

  /// 戻るボタンの無効化（特定画面用）
  static bool preventBack(String routeName) {
    const noBackRoutes = [
      AppRoutes.home,
      AppRoutes.adminHome,
    ];

    return noBackRoutes.contains(routeName);
  }
}

/// プレミアム特典アイテムウィジェット
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Color(0xFF667EEA),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// WillPopScope用のラッパー
class RouteGuardWrapper extends StatelessWidget {
  final Widget child;
  final String routeName;
  final VoidCallback? onBackPressed;

  const RouteGuardWrapper({
    Key? key,
    required this.child,
    required this.routeName,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (RouteGuard.preventBack(routeName)) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            // デフォルト: 確認ダイアログを表示
            _showExitConfirmDialog(context);
          }
        },
        child: child,
      );
    }

    return child;
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アプリを終了しますか？'),
        content: const Text('ホーム画面から戻るとアプリが終了します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // アプリ終了処理
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              '終了',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}