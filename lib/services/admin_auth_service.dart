import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home_screen.dart';
import '../utils/app_logger.dart';

class AdminLoginService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  static const String _logName = 'AdminLoginService';

  /// 管理者ログイン処理
  Future<bool> login(String email, String password) async {
    logger.section('login() 開始', name: _logName);
    logger.info('入力メール: $email', name: _logName);

    try {
      // Firebase Auth ログイン
      logger.start('FirebaseAuth にログイン中...', name: _logName);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      logger.success('Auth ログイン成功: UID=${credential.user?.uid}',
          name: _logName);

      // Firestore 管理者チェック
      logger.start('Firestore administrator/$email を確認中...', name: _logName);

      final adminDoc =
          await _firestore.collection('administrator').doc(email).get();

      if (!adminDoc.exists) {
        logger.error('Firestore 管理者情報なし → 権限拒否: $email', name: _logName);

        await _auth.signOut();
        logger.info('FirebaseAuth サインアウト完了（不正管理者ログイン拒否）', name: _logName);

        return false;
      }

      logger.success('Firestore 管理者チェック OK: $email', name: _logName);

      // 最終ログインを更新
      await _firestore.collection('administrator').doc(email).set(
        {'LastLogin': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      logger.info('最終ログイン時刻 更新完了', name: _logName);
      logger.section('login() 正常終了（true）', name: _logName);

      return true;
    } catch (e, stack) {
      logger.error(
        'ログイン処理エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );

      return false;
    }
  }

  /// 画面遷移込みの管理者ログイン処理
  Future<void> loginAdmin(
      String email, String password, BuildContext context) async {
    logger.section('loginAdmin() 開始 - メール: $email', name: _logName);

    final ok = await login(email, password);

    if (!ok) {
      logger.error('管理者ログイン失敗（Auth 失敗 or Firestore 権限なし）: $email',
          name: _logName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("管理者アカウントではありません")),
        );
      }

      return;
    }

    // ここに到達したら100%成功
    logger.success('管理者ログイン成功: $email → AdminHomeScreen へ遷移', name: _logName);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    }
  }
}
