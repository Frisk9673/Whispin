// lib/services/user_logout_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/account_create/account_create_screen.dart';

class UserLogoutService {
  /// 静的メソッドとしてログアウト処理を提供
  static Future<void> logout(BuildContext context) async {
    try {
      // FirebaseAuth で正式にログアウト
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('ログアウト時にエラー発生: $e');
    }

    // 履歴を完全に削除して登録画面へ
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserRegisterPage()),
        (_) => false,
      );
    }
  }
}
