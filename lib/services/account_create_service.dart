// services/user_register_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRegisterService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<bool> register(UserModel user, String password) async {
    try {
      // Auth に登録
      await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // Firestore に登録（主キー = TEL_ID）
      await _firestore.collection('User').doc(user.telId).set({
        ...user.toMap(),
        "CreateAt": FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      throw "Auth エラー: ${e.code}";
    } catch (e) {
      throw "登録エラー: $e";
    }
  }
}
