// services/account_create_service.dart 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRegisterService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<bool> register(UserModel user, String password) async {
    print("===== [UserRegisterService] register() 開始 =====");
    print("入力されたユーザー情報:");
    print("  email: ${user.email}");
    print("  telId: ${user.telId}");
    print("  lastName: ${user.lastName}");
    print("  firstName: ${user.firstName}");
    print("  nickname: ${user.nickname}");
    print("  premium: ${user.premium}");
    print("  createdAt(Local): ${user.createdAt}");

    try {
      print("▶ FirebaseAuth にユーザー作成リクエスト送信中...");

      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      print("✔ Auth 登録成功!");
      print("  UID: ${credential.user?.uid}");

      print("▶ Firestore(User/${user.telId}) にユーザーデータ登録中...");

      await _firestore.collection('User').doc(user.telId).set({
        ...user.toMap(),
        "CreateAt": FieldValue.serverTimestamp(),
      });

      print("✔ Firestore 登録完了! (User/${user.telId})");

      print("===== [UserRegisterService] register() 正常終了 =====");

      return true;

    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException 発生: ${e.code}");
      print("===== register() 異常終了（Auth エラー） =====");
      throw "Auth エラー: ${e.code}";

    } catch (e) {
      print("❌ その他のエラー発生: $e");
      print("===== register() 異常終了 =====");
      throw "登録エラー: $e";
    }
  }
}
