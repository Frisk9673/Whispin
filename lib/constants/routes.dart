/// ルート名の定数管理
class AppRoutes {
  // インスタンス化を防ぐ
  AppRoutes._();

  /// ルート名と画面の対応表
  /// - /login: ユーザーログイン画面
  /// - /register: ユーザー新規登録画面
  /// - /admin/login: 管理者ログイン画面
  /// - /: ユーザーホーム画面
  /// - /profile: プロフィール編集画面
  /// - /settings: 設定画面
  /// - /room/create: ルーム作成画面
  /// - /room/join: ルーム参加画面
  /// - /chat: チャット画面
  /// - /friends: フレンド一覧画面
  /// - /friends/requests: フレンド申請一覧画面
  /// - /blocks: ブロック一覧画面
  /// - /admin: 管理者ホーム画面
  /// - /admin/premium-logs: プレミアム履歴管理画面
  /// - /admin/questions: 問い合わせチャット管理画面
  /// - /contact: 問い合わせ送信画面
  /// - /user/chat: ユーザーサポートチャット画面

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
