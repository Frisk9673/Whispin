/// ルート名の定数管理
class AppRoutes {
  // インスタンス化を防ぐ
  AppRoutes._();

  // 認証ルート
  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin/login';

  // ユーザー向けルート
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // チャットルート
  static const String createRoom = '/room/create';
  static const String joinRoom = '/room/join';
  static const String chat = '/chat';

  // フレンドルート
  static const String friendList = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String blockList = '/blocks';

  // 管理者ルート
  static const String adminHome = '/admin';
  static const String premiumLogs = '/admin/premium-logs';
  static const String questionChat = '/admin/questions';

  // サポートルート
  static const String contact = '/contact';
  static const String userChat = '/user/chat';
}
