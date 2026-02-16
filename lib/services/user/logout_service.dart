// services/admin_logout_service.dart
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../screens/admin/admin_login_screen.dart';

/// 【担当ユースケース】
/// - 管理者ログアウトの実行と、ログアウト後のログイン画面への遷移。
/// - 認証ライフサイクル上、ログイン処理（UserAuthService）と対になる終了処理。
///
/// 【依存するRepository/Service】
/// - [FirebaseAuth]: signOut 実行。
/// - [Navigator]: 認証解除後の画面遷移。
///
/// 【主な副作用（DB更新/通知送信）】
/// - FirebaseAuth のサインイン状態を破棄する。
class AdminLogoutService {
  final _auth = FirebaseAuth.instance;

  /// 入力: [context]。
  /// 前提条件: 呼び出し元の BuildContext が有効であること（mounted チェックあり）。
  /// 成功時結果: サインアウト後に AdminLoginScreen へスタックを初期化して遷移。
  /// 失敗時挙動: 例外は握りつぶし、ログ出力のみ実施する。
  ///
  /// 認証ライフサイクル参照:
  /// - サインイン開始: UserAuthService.loginUser
  /// - セッション破棄（一般）: AuthService.logout
  Future<void> logout(BuildContext context) async {
    developer.log("=== AdminLogoutService.logout() 開始 ===");

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        developer.log("⚠️ 現在ログインユーザーなし");
      } else {
        developer.log("ログアウト対象 UID: ${currentUser.uid}");
      }

      developer.log("FirebaseAuth.signOut() を実行中...");
      await _auth.signOut();
      developer.log("🔵 ログアウト成功");

      if (context.mounted) {
        developer.log("➡ AdminLoginScreen へ遷移");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (_) => false,
        );
      }
    } catch (e, stack) {
      developer.log(
        "❌ ログアウトエラー: $e",
        error: e,
        stackTrace: stack,
      );
    }

    developer.log("=== AdminLogoutService.logout() 終了 ===\n");
  }
}
