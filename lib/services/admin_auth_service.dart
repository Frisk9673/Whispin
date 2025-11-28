import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home_screen.dart';

class AdminLoginService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 管理者ログイン処理
  Future<bool> login(String email, String password) async {
    developer.log("=== AdminLoginService.login() 開始 ===");
    developer.log("入力メール: $email");

    try {
      // -------------------------------
      // Firebase Auth ログイン
      // -------------------------------
      developer.log("FirebaseAuth にログイン中...");
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      developer.log("Auth ログイン成功: UID=${credential.user?.uid}");

      // -------------------------------
      // Firestore 管理者チェック
      // -------------------------------
      developer.log("Firestore administrator/$email を確認中...");

      final adminDoc = await _firestore
          .collection('administrator')
          .doc(email)
          .get();

      if (!adminDoc.exists) {
        // ❌ Firestore に存在しない → 管理者ではない
        developer.log("❌ Firestore 管理者情報なし → 権限拒否: $email");

        // Firebase Authは成功してるのでここでログアウト
        await _auth.signOut();

        developer.log("FirebaseAuth サインアウト完了（不正管理者ログイン拒否）");

        return false;
      }

      developer.log("✔ Firestore 管理者チェック OK: $email");

      // -------------------------------
      // 最終ログインを更新
      // -------------------------------
      await _firestore
          .collection('administrator')
          .doc(email)
          .set(
            {'LastLogin': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );

      developer.log("最終ログイン時刻 更新完了");

      developer.log("=== AdminLoginService.login() 正常終了（true） ===");

      return true;

    } catch (e, stack) {
      developer.log(
        "❌ ログイン処理エラー: $e",
        error: e,
        stackTrace: stack,
      );

      return false;
    }
  }

  /// 画面遷移込みの管理者ログイン処理
  Future<void> loginAdmin(
      String email, String password, BuildContext context) async {
    developer.log("=== loginAdmin() 開始 === メール: $email");

    final ok = await login(email, password);

    if (!ok) {
      developer.log("❌ 管理者ログイン失敗（Auth 失敗 or Firestore 権限なし）: $email");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("管理者アカウントではありません")),
        );
      }

      return;
    }

    // -------------------------------
    // ここに到達したら100%成功
    // -------------------------------
    developer.log("✅ 管理者ログイン成功: $email → AdminHomeScreen へ遷移");

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }
  }
}
