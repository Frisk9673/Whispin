import '../../models/user/user.dart';
import 'storage_service.dart';

/// 認証サービス（セッション管理特化版）
///
/// Firebase Authによる認証は各専用サービスで実施:
/// - 新規登録: UserRegisterService
/// - ログイン: UserAuthService
/// - アカウント削除: UserProvider経由
///
/// このサービスはセッション状態の管理のみを担当します。
class AuthService {
  final StorageService _storageService;
  User? _currentUser;

  AuthService(this._storageService);

  /// 現在ログイン中のユーザー
  User? get currentUser => _currentUser ?? _storageService.currentUser;

  /// サービスの初期化
  Future<void> initialize() async {
    _currentUser = _storageService.currentUser;
  }

  /// ログアウト
  Future<void> logout() async {
    _storageService.currentUser = null;
    _currentUser = null;
    await _storageService.save();
  }

  /// ログイン状態を確認
  bool isLoggedIn() {
    return currentUser != null;
  }
}