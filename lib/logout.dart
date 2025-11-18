import 'package:flutter/material.dart';

import 'account_create.dart';

/// シンプルなログアウトヘルパー
/// 必要なら FirebaseAuth.signOut() 等を追加してください。
Future<void> signOutAndGoToRegister(BuildContext context) async {
  // TODO: FirebaseAuth が導入されている場合はここで signOut を呼ぶ
  // 例:
  // await FirebaseAuth.instance.signOut();

  // 画面遷移: ユーザー登録画面へ置き換え
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const UserRegisterPage()),
    (route) => false,
  );
}
