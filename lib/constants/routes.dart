/// ルート名の定数管理
class AppRoutes {
  // プライベートコンストラクタ
  AppRoutes._();

  // ===== Authentication Routes =====
  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin/login';

  // ===== User Routes =====
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // ===== Chat Routes =====
  static const String createRoom = '/room/create';
  static const String joinRoom = '/room/join';
  static const String chat = '/chat';

  // ===== Friend Routes =====
  static const String friendList = '/friends';
  static const String friendRequests = '/friends/requests';
  static const String blockList = '/blocks';

  // ===== Admin Routes =====
  static const String adminHome = '/admin';
  static const String premiumLogs = '/admin/premium-logs';
  static const String questionChat = '/admin/questions';

  // ===== Support Routes =====
  static const String contact = '/contact';
  static const String userChat = '/user/chat';
}