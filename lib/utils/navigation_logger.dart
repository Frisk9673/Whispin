import 'package:flutter/material.dart';
import 'app_logger.dart';

/// ページ遷移をログに記録するNavigatorObserver
class NavigationLogger extends NavigatorObserver {
  static const String _logName = 'Navigation';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final currentPage = _getRouteName(route);
    final previousPage = _getRouteName(previousRoute);

    logger.section('📱 ページ遷移: PUSH', name: _logName);
    logger.info('前のページ: ${previousPage ?? "(なし)"}', name: _logName);
    logger.info('新しいページ: $currentPage', name: _logName);
    logger.info('時刻: ${DateTime.now().toString().substring(11, 19)}',
        name: _logName);

    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final currentPage = _getRouteName(route);
    final previousPage = _getRouteName(previousRoute);

    logger.section('📱 ページ遷移: POP (戻る)', name: _logName);
    logger.info('閉じたページ: $currentPage', name: _logName);
    logger.info('戻り先ページ: ${previousPage ?? "(なし)"}', name: _logName);
    logger.info('時刻: ${DateTime.now().toString().substring(11, 19)}',
        name: _logName);

    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final newPage = _getRouteName(newRoute);
    final oldPage = _getRouteName(oldRoute);

    logger.section('📱 ページ遷移: REPLACE (置き換え)', name: _logName);
    logger.info('古いページ: ${oldPage ?? "(なし)"}', name: _logName);
    logger.info('新しいページ: ${newPage ?? "(なし)"}', name: _logName);
    logger.info('時刻: ${DateTime.now().toString().substring(11, 19)}',
        name: _logName);

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final removedPage = _getRouteName(route);
    final previousPage = _getRouteName(previousRoute);

    logger.section('📱 ページ遷移: REMOVE (削除)', name: _logName);
    logger.info('削除されたページ: $removedPage', name: _logName);
    logger.info('前のページ: ${previousPage ?? "(なし)"}', name: _logName);
    logger.info('時刻: ${DateTime.now().toString().substring(11, 19)}',
        name: _logName);

    super.didRemove(route, previousRoute);
  }

  /// ルートから画面名を取得
  String _getRouteName(Route<dynamic>? route) {
    if (route == null) return '(null)';

    // Named routeの場合
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!;
    }

    // MaterialPageRouteの場合、Widgetの型名を取得
    if (route is MaterialPageRoute) {
      final widget = route.builder(route.navigator!.context);
      final widgetType = widget.runtimeType.toString();

      // クラス名から画面名を推測
      return _formatScreenName(widgetType);
    }

    // その他のRouteタイプ
    return route.runtimeType.toString();
  }

  /// クラス名を読みやすい形式にフォーマット
  String _formatScreenName(String className) {
    // ジェネリクス記号を削除
    className = className.replaceAll(RegExp(r'<.*>'), '');

    // よく使われる画面名のマッピング
    final screenNames = {
      'HomeScreen': 'ホーム画面',
      'ProfileScreen': 'プロフィール画面',
      'UserLoginPage': 'ログイン画面',
      'UserRegisterPage': 'ユーザー登録画面',
      'AdminLoginScreen': '管理者ログイン画面',
      'AdminHomeScreen': '管理者ホーム画面',
      'ChatScreen': 'チャット画面',
      'CreateRoomScreen': 'ルーム作成画面',
      'RoomCreateScreen': 'ルーム作成画面',
      'RoomJoinScreen': 'ルーム参加画面',
      'FriendListScreen': 'フレンド一覧画面',
      'BlockListScreen': 'ブロック一覧画面',
      'UserChatScreen': 'お問い合わせ画面',
      'PremiumLogListScreen': 'プレミアムログ一覧画面',
      'AuthScreen': '認証画面',
    };

    // マッピングに該当する場合は日本語名を返す
    if (screenNames.containsKey(className)) {
      return '${screenNames[className]} ($className)';
    }

    // マッピングにない場合はクラス名をそのまま返す
    return className;
  }
}
