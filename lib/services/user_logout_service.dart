// services/admin_logout_service.dart
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_login_screen.dart';

class AdminLogoutService {
  final _auth = FirebaseAuth.instance;

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
