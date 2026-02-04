import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whispin/providers/premium_log_provider.dart';
import 'package:whispin/screens/admin/admin_question_list_screen.dart';
import 'package:whispin/screens/user/notifications.dart';
import '../constants/routes.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/profile.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/friend_list_screen.dart';
import '../screens/user/block_list_screen.dart';
import '../screens/user/room_create_screen.dart';
import '../screens/user/room_join_screen.dart';
import '../screens/user/question_chat_user.dart';
import '../screens/user/user_login_page.dart';
import '../screens/user/account_create_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/premium_log_list_screen.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import '../utils/app_logger.dart';

/// アプリケーション全体のルーティングを管理するクラス
class AppRouter {
  static const String _logName = 'AppRouter';

  // プライベートコンストラクタ
  AppRouter._();

  /// ルート生成
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    logger.navigation(
      'current',
      settings.name ?? 'unknown',
      name: _logName,
    );

    switch (settings.name) {
      // ===== Authentication Routes =====
      case AppRoutes.login:
        return _buildRoute(
          const UserLoginPage(),
          settings: settings,
        );

      case AppRoutes.register:
        return _buildRoute(
          const UserRegisterPage(),
          settings: settings,
        );

      case AppRoutes.adminLogin:
        return _buildRoute(
          const AdminLoginScreen(),
          settings: settings,
        );

      // ===== User Routes =====
      case AppRoutes.home:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _buildErrorRoute('HomeScreen requires arguments');
        }
        return _buildRoute(
          HomeScreen(
            authService: args['authService'] as AuthService,
            storageService: args['storageService'] as StorageService,
          ),
          settings: settings,
        );

      case AppRoutes.profile:
        return _buildRoute(
          const ProfileScreen(),
          settings: settings,
        );

      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _buildErrorRoute('ChatScreen requires arguments');
        }
        return _buildRoute(
          ChatScreen(
            roomId: args['roomId'] as String,
            authService: args['authService'] as AuthService,
            chatService: args['chatService'] as ChatService,
            storageService: args['storageService'] as StorageService,
          ),
          settings: settings,
        );

      // ===== Room Routes =====
      case AppRoutes.createRoom:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const RoomCreateScreen(),
        );

      case AppRoutes.joinRoom:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const RoomJoinScreen(),
        );

      // ===== Friend Routes =====
      case AppRoutes.friendList:
        return _buildRoute(
          const FriendListScreen(),
          settings: settings,
        );

      // ✅ 追加: フレンドリクエスト画面
      case AppRoutes.friendRequests:
        return _buildRoute(
          const FriendRequestsScreen(),
          settings: settings,
        );

      case AppRoutes.blockList:
        return _buildRoute(
          const BlockListScreen(),
          settings: settings,
        );

      // ===== Admin Routes =====
      case AppRoutes.adminHome:
        return _buildRoute(
          const AdminHomeScreen(),
          settings: settings,
        );

      case AppRoutes.premiumLogs:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => PremiumLogProvider()..loadAllLogs(),
            child: const PremiumLogListScreen(),
          ),
        );

      case AppRoutes.questionChat:
        return _buildRoute(
          const AdminQuestionListScreen(),
          settings: settings,
        );

      // ===== Support Routes =====
      case AppRoutes.userChat:
        return _buildRoute(
          const UserChatScreen(),
          settings: settings,
        );

      default:
        logger.warning(
          '未定義のルート: ${settings.name}',
          name: _logName,
        );
        return _buildErrorRoute('Route not found: ${settings.name}');
    }
  }

  /// ルートを構築（共通処理）
  static MaterialPageRoute _buildRoute(
    Widget page, {
    required RouteSettings settings,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// エラールートを構築
  static MaterialPageRoute _buildErrorRoute(String message) {
    logger.error('ルートエラー: $message', name: _logName);

    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('エラー'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'ページが見つかりません',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigatorのコンテキストを取得してホームに戻る
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('ホームに戻る'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 名前付きルートでナビゲート
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    logger.navigation(
      ModalRoute.of(context)?.settings.name ?? 'unknown',
      routeName,
      name: _logName,
    );

    if (replace) {
      return Navigator.of(context).pushReplacementNamed<T, dynamic>(
        routeName,
        arguments: arguments,
      );
    }

    return Navigator.of(context).pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// ルートを完全に置き換え（戻れない）
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    logger.navigation(
      ModalRoute.of(context)?.settings.name ?? 'unknown',
      '$routeName (removeUntil)',
      name: _logName,
    );

    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// 戻る
  static void pop<T>(BuildContext context, [T? result]) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';
    logger.navigation(currentRoute, 'back', name: _logName);

    Navigator.of(context).pop<T>(result);
  }

  /// ダイアログやボトムシートを全て閉じてから戻る
  static void popUntilRoot(BuildContext context) {
    logger.info('ルートまで戻る', name: _logName);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
