import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_logger.dart';

class AdminLogoutService {
  final _auth = FirebaseAuth.instance;
  static const String _logName = 'AdminLogoutService';

  Future<void> logout() async {
    logger.section('logout() 開始', name: _logName);

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        logger.warning('現在ログインしているユーザーがいません（すでにログアウト状態）', name: _logName);
      } else {
        logger.info('ログアウト対象 UID: ${currentUser.uid}', name: _logName);
      }

      logger.start('FirebaseAuth.signOut() を実行します...', name: _logName);
      await _auth.signOut();

      logger.success('ログアウト成功しました！', name: _logName);
      logger.section('logout() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'ログアウト処理中にエラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      logger.section('logout() 強制終了（エラー）', name: _logName);
    }
  }
}
