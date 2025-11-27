import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class AdminLogoutService {
  final _auth = FirebaseAuth.instance;

  Future<void> logout() async {
    developer.log("=== AdminLogoutService.logout() 開始 ===");

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        developer.log("⚠️ 現在ログインしているユーザーがいません（すでにログアウト状態）");
      } else {
        developer.log("ログアウト対象 UID: ${currentUser.uid}");
      }

      developer.log("FirebaseAuth.signOut() を実行します...");
      await _auth.signOut();

      developer.log("🔵 ログアウト成功しました！");
      developer.log("=== AdminLogoutService.logout() 完了 ===\n");

    } catch (e, stack) {
      developer.log(
        "❌ ログアウト処理中にエラー発生: $e",
        error: e,
        stackTrace: stack,
      );
      developer.log("=== AdminLogoutService.logout() 強制終了（エラー） ===\n");
    }
  }
}
