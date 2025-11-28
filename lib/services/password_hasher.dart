import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _iterations = 10000;
  static const int _keyLength = 64;
  
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }
  
  static String hashPassword(String password, String salt) {
    final saltBytes = base64.decode(salt);
    final passwordBytes = utf8.encode(password);
    
    var hash = passwordBytes + saltBytes;
    for (var i = 0; i < _iterations; i++) {
      hash = sha256.convert(hash).bytes;
    }
    
    return base64.encode(hash);
  }
  
  static bool verifyPassword(String password, String storedHash, String salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
  }
}
