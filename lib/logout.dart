import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'account_create.dart';

/// --- ログアウト処理 ---
/// ・FirebaseAuth でログアウト
/// ・画面履歴を全削除してユーザー登録へ戻る
Future<void> signOutAndGoToRegister(BuildContext context) async {
  try {
    // FirebaseAuth が導入されている場合の正式なログアウト処理
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('ログアウト時にエラー発生: $e');
  }

  // pushAndRemoveUntil により履歴を完全に消し、戻れなくする
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserRegisterPage()),
      (_) => false,
    );
  }
}
