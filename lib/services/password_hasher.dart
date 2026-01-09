import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _iterations = 10000;
  static const int _keyLength = 64;

  static String generateSalt({int length = 32}) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  static String hashPassword(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);

    List<int> hash = passwordBytes + saltBytes;

    for (var i = 0; i < _iterations; i++) {
      hash = sha256.convert(hash).bytes;
    }

    final derivedKey = _expandKey(hash, _keyLength);

    return base64.encode(derivedKey);
  }

  static bool verifyPassword(
    String password,
    String storedHash,
    String salt,
  ) {
    final computedHash = hashPassword(password, salt);
    return constantTimeEquals(computedHash, storedHash);
  }

  static List<int> _expandKey(List<int> baseHash, int length) {
    if (baseHash.length >= length) {
      return baseHash.sublist(0, length);
    }

    final buffer = <int>[];
    var counter = 0;

    while (buffer.length < length) {
      buffer.addAll(
        sha256.convert([...baseHash, counter]).bytes,
      );
      counter++;
    }

    return buffer.sublist(0, length);
  }

  /// タイミング攻撃対策
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
