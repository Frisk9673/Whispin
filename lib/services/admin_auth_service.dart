import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home_screen.dart'; // AdminHomeScreen のパスに合わせて修正

class AdminLoginService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// 実際のログイン処理
  Future<bool> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return false;

      // 最終ログイン日時を更新
      await _firestore
          .collection('administrator')
          .doc(uid)
          .set({'LastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  /// 管理者ログイン + 成功時に AdminHomeScreen へ遷移
  Future<void> loginAdmin(String email, String password, BuildContext context) async {
    final success = await login(email, password);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ログインに失敗しました")),
      );
      return;
    }

    // 成功 → AdminHomeScreen へ直接遷移
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminHomeScreen()),
      );
    }
  }
}
