import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    developer.log("=== UserAuthService.loginUser() 開始 ===");
    developer.log("入力メール: $email");
    developer.log("パスワード: （非表示）");

    try {
      developer.log("FirebaseAuth.signInWithEmailAndPassword() を呼び出し中...");
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      developer.log("✅ ログイン成功");
      developer.log("UID: ${credential.user?.uid}");
      developer.log("=== UserAuthService.loginUser() 完了 ===\n");

      return credential.user;
    } catch (e, stack) {
      developer.log(
        "❌ ログインエラー発生: $e",
        error: e,
        stackTrace: stack,
      );
      developer.log("=== UserAuthService.loginUser() 異常終了 ===\n");
      rethrow; // UI 側でキャッチ
    }
  }
}
