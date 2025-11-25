// lib/auth/user_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    print('🔐 [UserAuth] ログイン処理開始');
    print('📧 入力メール: $email');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      print('✅ [UserAuth] ログイン成功');
      print('👤 UID: ${credential.user?.uid}');

      return credential.user;
    } catch (e) {
      print('❌ [UserAuth] ログインエラー: $e');
      rethrow; // UI 側でキャッチさせる
    }
  }
}
