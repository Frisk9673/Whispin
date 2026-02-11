import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:whispin/providers/premium_log_provider.dart';
import 'package:whispin/screens/admin/admin_question_list_screen.dart';
import 'package:whispin/screens/user/notifications_screen.dart';
import '../constants/routes.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/friend_list_screen.dart';
import '../screens/user/block_list_screen.dart';
import '../screens/user/room_create_screen.dart';
import '../screens/user/room_join_screen.dart';
import '../screens/user/question_chat_screen.dart';
import '../screens/user/login_screen.dart';
import '../screens/user/account_create_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/premium_log_list_screen.dart';
import '../services/user/auth_service.dart';
import '../services/user/storage_service.dart';
import '../services/user/chat_service.dart';
import '../utils/app_logger.dart';

/// アプリケーション全体のルーティングを管理するクラス
class AppRouter {
  static const String _logName = 'AppRouter';

  // プライベートコンストラクタ
  AppRouter._();

  /// ルート生成
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = _normalizeRouteName(settings.name);
    logger.navigation(
      'current',
      routeName,
      name: _logName,
    );

    switch (routeName) {
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
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final authService = (args != null && args['authService'] != null)
                ? args['authService'] as AuthService
                : context.read<AuthService>();
            final storageService =
                (args != null && args['storageService'] != null)
                    ? args['storageService'] as StorageService
                    : context.read<StorageService>();

            final isLoggedIn = FirebaseAuth.instance.currentUser != null ||
                authService.isLoggedIn();
            if (!isLoggedIn) {
              return const UserLoginPage();
            }

            return HomeScreen(
              authService: authService,
              storageService: storageService,
            );
          },
        );

      case AppRoutes.profile:
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const ProfileScreen(),
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
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const RoomCreateScreen(),
        );

      case AppRoutes.joinRoom:
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const RoomJoinScreen(),
        );

      // ===== Friend Routes =====
      case AppRoutes.friendList:
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const FriendListScreen(),
        );

      // ✅ 追加: フレンドリクエスト画面
      case AppRoutes.friendRequests:
        return _buildRoute(
          const FriendRequestsScreen(),
          settings: settings,
        );

      case AppRoutes.blockList:
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const BlockListScreen(),
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
        return _buildAuthGuardedRoute(
          settings: settings,
          pageBuilder: (_) => const UserChatScreen(),
        );

      default:
        logger.warning(
          '未定義のルート: $routeName (raw: ${settings.name}) → ホーム/ログインへフォールバック',
          name: _logName,
        );
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final authService = context.read<AuthService>();
            final storageService = context.read<StorageService>();
            final isLoggedIn = FirebaseAuth.instance.currentUser != null ||
                authService.isLoggedIn();

            if (!isLoggedIn) {
              return const UserLoginPage();
            }

            return HomeScreen(
              authService: authService,
              storageService: storageService,
            );
          },
        );
    }
  }



  /// ルート名を正規化（webのURL/fragment形式を含めて吸収）
  static String _normalizeRouteName(String? rawName) {
    final raw = (rawName ?? AppRoutes.home).trim();

    if (raw.isEmpty) {
      return AppRoutes.home;
    }

    var name = raw;

    // Hash URL（例: #/profile, /#/profile）を優先的に処理
    final hashRouteMatch = RegExp(r'#(/[^?#]*)').firstMatch(name);
    if (hashRouteMatch != null) {
      name = hashRouteMatch.group(1)!;
    } else {
      final parsed = Uri.tryParse(name);
      if (parsed != null) {
        // フルURL入力時は path を利用（例: https://host/profile?x=1）
        if (parsed.hasScheme || name.startsWith('//')) {
          name = parsed.path;
        }

        // fragment が / で始まる場合は fragment を優先
        if (parsed.fragment.startsWith('/')) {
          name = parsed.fragment;
        }
      }

      // query/hash を除去
      final queryIndex = name.indexOf('?');
      if (queryIndex >= 0) {
        name = name.substring(0, queryIndex);
      }

      final hashIndex = name.indexOf('#');
      if (hashIndex >= 0) {
        name = name.substring(0, hashIndex);
      }
    }

    name = Uri.decodeComponent(name).trim();

    if (name.isEmpty) {
      return AppRoutes.home;
    }

    if (!name.startsWith('/')) {
      name = '/$name';
    }

    if (name.length > 1 && name.endsWith('/')) {
      name = name.substring(0, name.length - 1);
    }

    return name;
  }

  static bool _isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static MaterialPageRoute _buildAuthGuardedRoute({
    required RouteSettings settings,
    required WidgetBuilder pageBuilder,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final authService = context.read<AuthService>();
        final isLoggedIn = _isLoggedIn() || authService.isLoggedIn();

        if (!isLoggedIn) {
          logger.warning('未認証のためログイン画面へ遷移: ${settings.name}', name: _logName);
          return const UserLoginPage();
        }

        return pageBuilder(context);
      },
    );
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
