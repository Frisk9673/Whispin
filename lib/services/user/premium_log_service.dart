import '../../models/user/user.dart';
import '../../models/admin/premium_log_model.dart';
import '../../repositories/premium_log_repository.dart';
import '../../repositories/user_repository.dart';
import '../../utils/app_logger.dart';

/// プレミアムログサービス（Repository層を使用）
/// ※ 検索キーはすべて「メールアドレス」で統一
class PremiumLogService {
  final PremiumLogRepository _logRepository = PremiumLogRepository();
  final UserRepository _userRepository = UserRepository();

  static const String _logName = 'PremiumLogService';

  /// プレミアムログ 全件取得（降順）
  Future<List<PremiumLog>> fetchLogs() async {
    logger.section('fetchLogs() 開始', name: _logName);

    try {
      final logs = await _logRepository.findAllOrderedByTimestamp();

      logger.info('取得ログ件数: ${logs.length}', name: _logName);
      logger.section('fetchLogs() 完了', name: _logName);

      return logs;
    } catch (e, stack) {
      logger.error(
        'fetchLogs() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// メールアドレスでログをフィルタ
  Future<List<PremiumLog>> fetchLogsByEmail(String email) async {
    logger.section('fetchLogsByEmail() 開始', name: _logName);
    logger.info('検索 email: $email', name: _logName);

    try {
      final logs = await _logRepository.findByEmail(email);

      logger.info('取得件数: ${logs.length}', name: _logName);
      logger.section('fetchLogsByEmail() 完了', name: _logName);

      return logs;
    } catch (e, stack) {
      logger.error(
        'fetchLogsByEmail() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 対象ユーザー取得（メールアドレス）
  Future<User?> fetchUserByEmail(String email) async {
    logger.section('fetchUserByEmail() 開始', name: _logName);
    logger.info('検索 email: $email', name: _logName);

    try {
      final user = await _userRepository.findByEmail(email);

      if (user == null) {
        logger.warning('ユーザデータなし', name: _logName);
        logger.section('fetchUserByEmail() 完了（null）', name: _logName);
        return null;
      }

      logger.success('fetchUserByEmail() 完了', name: _logName);
      logger.info('  名前: ${user.lastName} ${user.firstName}', name: _logName);
      logger.info('  Premium: ${user.premium}', name: _logName);

      return user;
    } catch (e, stack) {
      logger.error(
        'fetchUserByEmail() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// プレミアムログを追加
  Future<void> addLog({
    required String email,
    required String detail,
  }) async {
    logger.section('addLog() 開始', name: _logName);
    logger.info('email: $email, detail: $detail', name: _logName);

    try {
      await _logRepository.addLog(
        email: email,
        detail: detail,
      );

      logger.success('ログ追加完了', name: _logName);
      logger.section('addLog() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'addLog() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
