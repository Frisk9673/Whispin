// services/account_create_service.dart 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRegisterService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<bool> register(UserModel user, String password) async {
    print("===== [UserRegisterService] register() 開始 =====");

    try {
      // ==== 入力値ログ ====
      print("▶ 入力されたユーザーデータ（UserModel → toMap）:");
      user.toMap().forEach((key, value) {
        print("  $key: $value");
      });
      print("=============================================");

      print("▶ FirebaseAuth にユーザー作成リクエスト送信中...");

      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      print("✔ Auth 登録成功!");
      print("  UID: ${credential.user?.uid}");

      print("▶ Firestore(User/${user.telId}) にユーザーデータ登録中...");

      final inputData = {
        ...user.toMap(),
        "CreateAt": FieldValue.serverTimestamp(),
      };

      await _firestore.collection('User').doc(user.telId).set(inputData);

      print("✔ Firestore 登録完了!");

      // ==== Firestore から取得して整合性チェック ====
      print("▶ Firestore(User/${user.telId}) の保存済みデータ取得中...");

      final doc = await _firestore.collection('User').doc(user.telId).get();

      if (!doc.exists) {
        print("⚠ Firestore にデータが存在しません！（保存失敗の可能性）");
        return false;
      }

      print("===== Firestore に保存された実データ =====");
      final savedData = doc.data()!;
      savedData.forEach((key, value) {
        print("  $key: $value");
      });
      print("=========================================");

      // ==== 自動整合性チェック ====
      print("===== 自動整合性チェック開始 =====");

      for (final entry in user.toMap().entries) {
        final key = entry.key;
        final inputValue = entry.value;
        final savedValue = savedData[key];

        if (inputValue == savedValue) {
          print("✔ OK: $key → 一致 ($inputValue)");
        } else {
          print("❌ NG: $key → 不一致");
          print("     入力値: $inputValue");
          print("     Firestore値: $savedValue");
        }
      }

      print("===== 自動整合性チェック終了 =====");

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
