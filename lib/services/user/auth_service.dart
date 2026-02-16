import '../../models/user/user.dart';
import 'storage_service.dart';

/// 【担当ユースケース】
/// - 認証ライフサイクルにおける「ログイン後セッション保持」と「ログアウト時のセッション破棄」。
/// - 実認証は [UserAuthService]（login_service.dart）、ログアウトUI遷移は
///   [AdminLogoutService]（logout_service.dart）と連携する。
///
/// 【依存するRepository/Service】
/// - [StorageService]: currentUser の永続化先。
///
/// 【主な副作用（DB更新/通知送信）】
/// - `logout()` で Storage の currentUser を null 化し `save()` で永続状態を更新する。
class AuthService {
  final StorageService _storageService;
  User? _currentUser;

  AuthService(this._storageService);

  /// 現在ログイン中のユーザー
  User? get currentUser => _currentUser ?? _storageService.currentUser;

  /// 入力: なし。
  /// 前提条件: [_storageService] が初期化済みで currentUser を読めること。
  /// 成功時結果: メモリ上の [_currentUser] を Storage の値に同期する。
  /// 失敗時挙動: 例外はそのまま上位へ伝播する。
  Future<void> initialize() async {
    // 次は StorageService.currentUser 参照で永続化済みセッション復元へ渡す。
    _currentUser = _storageService.currentUser;
  }

  /// 入力: なし。
  /// 前提条件: 認証状態の破棄を呼び出し側が許容していること。
  /// 成功時結果: セッションを破棄し、永続化先にも反映される。
  /// 失敗時挙動: `save()` 失敗時は例外送出し、呼び出し側でリカバリする。
  ///
  /// 認証ライフサイクル参照:
  /// - ログイン確立は [UserAuthService.loginUser]
  /// - 管理画面のサインアウト遷移は [AdminLogoutService.logout]
  Future<void> logout() async {
    _storageService.currentUser = null;
    _currentUser = null;
    await _storageService.save();
  }

  /// 入力: なし。
  /// 前提条件: なし。
  /// 成功時結果: セッション有無を bool で返す。
  /// 失敗時挙動: 例外は発生しない想定。
  bool isLoggedIn() {
    return currentUser != null;
  }
}
