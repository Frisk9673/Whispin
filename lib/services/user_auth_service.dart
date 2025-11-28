import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    developer.log("===== [UserAuthService] loginUser() 開始 =====");

    // 入力ログ（パスワードは伏せ字）
    developer.log("▶ 入力されたログイン情報");
    developer.log("  email: $email");
    developer.log("  password: ${'*' * password.length}");
    developer.log("----------------------------------------------");

    try {
      developer.log("▶ FirebaseAuth.signInWithEmailAndPassword() 呼び出し中...");

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      developer.log("✔ Auth ログイン成功!");
      developer.log("  UID: ${user?.uid}");

      // Firestore のユーザーデータを取得
      developer.log("▶ Firestore(User) を email=$email で検索中...");

      final query = await _firestore
          .collection("User")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        developer.log("⚠ Firestore に該当ユーザーデータがありません");
        developer.log("===== loginUser() 異常終了（Firestore未登録） =====");
        return user;
      }

      final doc = query.docs.first;
      final data = doc.data();

      developer.log("===== Firestore に保存されているデータ =====");
      data.forEach((key, value) {
        developer.log("  $key: $value");
      });
      developer.log("============================================");

      // -----------------------
      // 🔍 自動整合性チェック
      // -----------------------
      developer.log("===== 自動整合性チェック開始 =====");

      _compare("email", email, data["email"]);
      _compare("UID", user?.uid, data["uid"]); // 使っていれば
      _compare("premium", null, data["premium"]); // premium はユーザー側に入力ないので Firestore値のみ表示

      // 他にも必要なら追加可能
      // _compare("lastName", inputLastName, data["lastName"]);
      // _compare("firstName", inputFirstName, data["firstName"]);
      // _compare("telId", inputTelId, data["telId"]);

      developer.log("===== 自動整合性チェック終了 =====");

      developer.log("===== [UserAuthService] loginUser() 正常終了 =====\n");

      return user;

    } catch (e, stack) {
      developer.log(
        "❌ ログインエラー発生: $e",
        error: e,
        stackTrace: stack,
      );
      developer.log("===== loginUser() 異常終了 =====\n");
      rethrow;
    }
  }

  /// 比較用メソッド（値の一致／不一致をログ出力）
  void _compare(String key, dynamic input, dynamic saved) {
    if (input == null) {
      // 入力値が無い場合は Firestore の値だけ表示する
      developer.log("  ℹ $key (入力なし) → Firestore 値: $saved");
      return;
    }

    if (input == saved) {
      developer.log("  ✔ OK: $key 一致 ($input)");
    } else {
      developer.log("  ❌ NG: $key 不一致!");
      developer.log("     入力値: $input");
      developer.log("     Firestore値: $saved");
    }
  }
}
