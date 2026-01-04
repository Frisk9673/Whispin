import 'package:flutter/material.dart';
import '../constants/routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import 'app_router.dart';
import '../utils/app_logger.dart';

/// ナビゲーションのヘルパー関数を提供するクラス
class NavigationHelper {
  static const String _logName = 'NavigationHelper';

  // プライベートコンストラクタ
  NavigationHelper._();

  // ===== Authentication Navigation =====

  /// ログイン画面へ遷移
  static Future<void> toLogin(BuildContext context) {
    logger.navigation('current', 'Login', name: _logName);
    return AppRouter.navigateAndRemoveUntil(context, AppRoutes.login);
  }

  /// 新規登録画面へ遷移
  static Future<void> toRegister(BuildContext context) {
    logger.navigation('current', 'Register', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.register);
  }

  /// 管理者ログイン画面へ遷移
  static Future<void> toAdminLogin(BuildContext context) {
    logger.navigation('current', 'AdminLogin', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.adminLogin);
  }

  // ===== User Navigation =====

  /// ホーム画面へ遷移
  static Future<void> toHome(
    BuildContext context, {
    required AuthService authService,
    required StorageService storageService,
  }) {
    logger.navigation('current', 'Home', name: _logName);
    
    return AppRouter.navigateAndRemoveUntil(
      context,
      AppRoutes.home,
      arguments: {
        'authService': authService,
        'storageService': storageService,
      },
    );
  }

  /// プロフィール画面へ遷移
  static Future<void> toProfile(BuildContext context) {
    logger.navigation('current', 'Profile', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.profile);
  }

  // ===== Chat Navigation =====

  /// ルーム作成画面へ遷移
  static Future<void> toCreateRoom(
    BuildContext context, {
    required AuthService authService,
    required ChatService chatService,
    required StorageService storageService,
  }) {
    logger.navigation('current', 'CreateRoom', name: _logName);
    
    return AppRouter.navigateTo(
      context,
      AppRoutes.createRoom,
      arguments: {
        'authService': authService,
        'chatService': chatService,
        'storageService': storageService,
      },
    );
  }

  /// チャット画面へ遷移
  static Future<void> toChat(
    BuildContext context, {
    required String roomId,
    required AuthService authService,
    required ChatService chatService,
    required StorageService storageService,
  }) {
    logger.navigation('current', 'Chat(roomId=$roomId)', name: _logName);
    
    return AppRouter.navigateTo(
      context,
      AppRoutes.chat,
      arguments: {
        'roomId': roomId,
        'authService': authService,
        'chatService': chatService,
        'storageService': storageService,
      },
    );
  }

  // ===== Room Navigation =====

  /// 新しいルーム作成画面へ遷移（Firestore版）
  static Future<void> toRoomCreate(BuildContext context) {
    logger.navigation('current', 'RoomCreate', name: _logName);
    return AppRouter.navigateTo(context, '/room/create-new');
  }

  /// ルーム参加画面へ遷移（Firestore版）
  static Future<void> toRoomJoin(BuildContext context) {
    logger.navigation('current', 'RoomJoin', name: _logName);
    return AppRouter.navigateTo(context, '/room/join-new');
  }

  // ===== Friend Navigation =====

  /// フレンド一覧画面へ遷移
  static Future<void> toFriendList(BuildContext context) {
    logger.navigation('current', 'FriendList', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.friendList);
  }

  /// ブロック一覧画面へ遷移
  static Future<void> toBlockList(BuildContext context) {
    logger.navigation('current', 'BlockList', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.blockList);
  }

  // ===== Admin Navigation =====

  /// 管理者ホーム画面へ遷移
  static Future<void> toAdminHome(BuildContext context) {
    logger.navigation('current', 'AdminHome', name: _logName);
    return AppRouter.navigateAndRemoveUntil(context, AppRoutes.adminHome);
  }

  /// プレミアムログ画面へ遷移
  static Future<void> toPremiumLogs(BuildContext context) {
    logger.navigation('current', 'PremiumLogs', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.premiumLogs);
  }

  // ===== Support Navigation =====

  /// お問い合わせチャット画面へ遷移
  static Future<void> toUserChat(BuildContext context) {
    logger.navigation('current', 'UserChat', name: _logName);
    return AppRouter.navigateTo(context, AppRoutes.userChat);
  }

  // ===== Common Navigation =====

  /// 戻る
  static void back<T>(BuildContext context, [T? result]) {
    AppRouter.pop(context, result);
  }

  /// ルートまで戻る
  static void backToRoot(BuildContext context) {
    AppRouter.popUntilRoot(context);
  }

  /// モーダルボトムシートを表示
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
    Color? backgroundColor,
  }) {
    logger.debug('BottomSheet表示', name: _logName);
    
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }

  /// ダイアログを表示
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    logger.debug('Dialog表示', name: _logName);
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }

  /// スナックバーを表示
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    logger.debug('SnackBar表示: $message', name: _logName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 成功メッセージを表示
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
    );
  }

  /// エラーメッセージを表示
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red,
    );
  }

  /// 警告メッセージを表示
  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
    );
  }

  /// 情報メッセージを表示
  static void showInfo(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue,
    );
  }
}