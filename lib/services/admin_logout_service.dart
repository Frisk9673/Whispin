// services/admin_logout_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AdminLogoutService {
  final _auth = FirebaseAuth.instance;

  Future<void> logout() async {
    await _auth.signOut();
  }
}
