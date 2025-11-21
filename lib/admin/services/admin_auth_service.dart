import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Auth でサインイン。成功したら Firestore に LastLogin を serverTimestamp で記録。
  Future<bool> login(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = userCred.user?.uid;
      if (uid == null) return false;

      // Firestore の管理者ドキュメントは UID を doc id にしてあるのでそれを更新
      final docRef = _firestore.collection('administrator').doc(uid);
      // serverTimestamp を使ってタイムスタンプで保存
      await docRef.set({'LastLogin': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      print('Login succeeded for $email (uid: $uid). LastLogin updated.');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Auth error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
