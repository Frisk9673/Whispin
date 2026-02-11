import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_logger.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _logName = 'UserAuthService';

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    logger.section('loginUser() 開始', name: _logName);

    // 入力ログ（パスワードは伏せ字）
    logger.info('入力されたログイン情報', name: _logName);
    logger.info('  email: $email', name: _logName);
    logger.info('  password: ${'*' * password.length}', name: _logName);
    logger.info('----------------------------------------------',
        name: _logName);

    try {
      logger.start('FirebaseAuth.signInWithEmailAndPassword() 呼び出し中...',
          name: _logName);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      logger.success('Auth ログイン成功!', name: _logName);
      logger.info('  UID: ${user?.uid}', name: _logName);

      // Firestore のユーザーデータを取得
      logger.start('Firestore(User) を email=$email で検索中...', name: _logName);

      final query = await _firestore
          .collection("User")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        logger.warning('Firestore に該当ユーザーデータがありません', name: _logName);
        logger.section('loginUser() 異常終了（Firestore未登録）', name: _logName);
        return user;
      }

      final doc = query.docs.first;
      final data = doc.data();

      logger.section('Firestore に保存されているデータ', name: _logName);
      data.forEach((key, value) {
        logger.info('  $key: $value', name: _logName);
      });
      logger.info('============================================',
          name: _logName);

      // 自動整合性チェック
      logger.section('自動整合性チェック開始', name: _logName);

      _compare("email", email, data["email"]);
      _compare("UID", user?.uid, data["uid"]);
      _compare("premium", null, data["premium"]);

      logger.section('自動整合性チェック終了', name: _logName);
      logger.section('loginUser() 正常終了', name: _logName);

      return user;
    } catch (e, stack) {
      logger.error(
        'ログインエラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      logger.section('loginUser() 異常終了', name: _logName);
      rethrow;
    }
  }

  /// 比較用メソッド（値の一致／不一致をログ出力）
  void _compare(String key, dynamic input, dynamic saved) {
    if (input == null) {
      logger.info('  ℹ $key (入力なし) → Firestore 値: $saved', name: _logName);
      return;
    }

    if (input == saved) {
      logger.success('  $key 一致 ($input)', name: _logName);
    } else {
      logger.warning('  $key 不一致!', name: _logName);
      logger.info('     入力値: $input', name: _logName);
      logger.info('     Firestore値: $saved', name: _logName);
    }
  }
}
