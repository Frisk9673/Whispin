import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/premium_log_model.dart';
import '../utils/app_logger.dart';

class PremiumLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _logName = 'PremiumLogService';

  /// Log_Premium 全件取得
  Future<List<PremiumLog>> fetchLogs() async {
    logger.section('fetchLogs() 開始', name: _logName);

    try {
      logger.start('Firestore Log_Premium コレクション取得中...', name: _logName);
      
      final snapshot = await _db.collection('Log_Premium')
          .orderBy('Timestamp', descending: true)
          .get();

      logger.info('Firestore 取得件数: ${snapshot.docs.length}', name: _logName);

      for (var doc in snapshot.docs) {
        logger.debug('ドキュメント: ${doc.data()}', name: _logName);
      }

      final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();

      logger.info('マッピング後ログ件数: ${logs.length}', name: _logName);
      for (var log in logs) {
        logger.debug(
            'TEL_ID: ${log.email} / DETAIL: ${log.detail} / TIME: ${log.timestamp}',
            name: _logName);
      }

      logger.section('fetchLogs() 完了', name: _logName);

      return logs;
    } catch (e, stack) {
      logger.error('fetchLogs() エラー発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 電話番号でフィルタ
  Future<List<PremiumLog>> fetchLogsByTel(String tel) async {
    logger.section('fetchLogsByTel() 開始', name: _logName);
    logger.info('検索電話番号: $tel', name: _logName);

    try {
      logger.start('Firestore Log_Premium を電話番号で検索中...', name: _logName);
      
      final snapshot = await _db.collection('Log_Premium')
          .where('ID', isEqualTo: tel)
          .orderBy('Timestamp', descending: true)
          .get();

      logger.info('取得件数: ${snapshot.docs.length}', name: _logName);

      for (var doc in snapshot.docs) {
        logger.debug('ドキュメント: ${doc.data()}', name: _logName);
      }

      final logs = snapshot.docs.map((d) => PremiumLog.fromMap(d.data())).toList();

      logger.info('マッピング後ログ件数: ${logs.length}', name: _logName);
      for (var log in logs) {
        logger.debug(
            'TEL_ID: ${log.email} / DETAIL: ${log.detail} / TIME: ${log.timestamp}',
            name: _logName);
      }

      logger.section('fetchLogsByTel() 完了', name: _logName);

      return logs;
    } catch (e, stack) {
      logger.error('fetchLogsByTel() エラー発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 対象ユーザ取得
  Future<User?> fetchUser(String tel) async {
    logger.section('fetchUser() 開始', name: _logName);
    logger.info('検索 TEL_ID: $tel', name: _logName);

    try {
      logger.start('Firestore User ドキュメント取得中...', name: _logName);
      
      final doc = await _db.collection('User').doc(tel).get();

      if (!doc.exists) {
        logger.warning('ユーザデータなし', name: _logName);
        logger.section('fetchUser() 完了（null）', name: _logName);
        return null;
      }

      logger.info('取得ユーザデータ:', name: _logName);
      logger.debug('${doc.data()}', name: _logName);

      final user = User.fromMap(doc.data()!);
      
      logger.success('fetchUser() 完了', name: _logName);
      logger.info('  名前: ${user.lastName} ${user.firstName}', name: _logName);
      logger.info('  Premium: ${user.premium}', name: _logName);

      return user;
    } catch (e, stack) {
      logger.error('fetchUser() エラー発生: $e', 
        name: _logName, 
        error: e, 
        stackTrace: stack,
      );
      rethrow;
    }
  }
}