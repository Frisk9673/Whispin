import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home_screen.dart';

class AdminLoginService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 実際のログイン処理
  Future<bool> login(String email, String password) async {
    developer.log("=== admin_auth_service.login() 呼び出し ===");
    developer.log("入力メール: $email");
    developer.log("入力パスワード: （非表示）");

    try {
      developer.log("FirebaseAuth へログインリクエスト送信...");
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      developer.log("ログイン成功！ 取得 UID: $uid");

      if (uid == null) {
        developer.log("❌ UID が null のためログイン扱いにできません");
        return false;
      }

      developer.log("Firestore に最終ログイン時刻を更新します...");
      await _firestore
          .collection('administrator')
          .doc(uid)
          .set({'LastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      developer.log("最終ログイン時刻 更新完了");
      developer.log("=== admin_auth_service.login() 正常終了 ===\n");

      return true;

    } catch (e, stack) {
      developer.log(
        "❌ FirebaseAuth ログイン時に例外発生: $e",
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 管理者ログイン + 成功時に AdminHomeScreen へ遷移
  Future<void> loginAdmin(String email, String password, BuildContext context) async {
    developer.log("=== loginAdmin() 開始 ===");
    developer.log("email=$email");

    final success = await login(email, password);

    if (!success) {
      developer.log("❌ login() から失敗が返されました → Snackbar 表示");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ログインに失敗しました")),
        );
      }
      developer.log("=== loginAdmin() 終了（失敗） ===\n");
      return;
    }

    developer.log("ログインに成功 → AdminHomeScreen に画面遷移します");

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }

    developer.log("=== loginAdmin() 完了（成功） ===\n");
  }
}
