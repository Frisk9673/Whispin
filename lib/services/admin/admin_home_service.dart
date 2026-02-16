import '../../repositories/user_repository.dart';
import '../../utils/app_logger.dart';

/// 管理者権限前提: 管理ダッシュボード向け集計データを扱うサービス。
/// 管理者サービス（Repository層を使用）
class AdminService {
  final UserRepository _userRepository = UserRepository();
  static const String _logName = 'AdminService';

  /// 取得対象データ: プレミアム会員数（読み取り専用）。
  /// 更新可否: このサービスでは更新しない（Repository経由で集計のみ）。
  /// Firestoreから有料会員数を取得
  Future<int> fetchPaidMemberCount() async {
    logger.section('fetchPaidMemberCount() 開始', name: _logName);

    try {
      // user 側の会員情報取得処理と同系統だが、差分理由: 管理画面では個別プロフィールではなく運営用集計値を返す。
      logger.start('UserRepository経由で有料会員数を取得中...', name: _logName);

      final count = await _userRepository.countPremiumUsers();

      logger.success('有料会員数: $count 人', name: _logName);
      logger.section('fetchPaidMemberCount() 完了', name: _logName);

      return count;
    } catch (e, stack) {
      logger.error(
        'エラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 取得対象データ: プレミアムユーザーID一覧（読み取り専用）。
  /// 更新可否: このサービスでは更新しない（閲覧用途のみ）。
  /// プレミアムユーザー一覧を取得
  Future<List<String>> fetchPremiumUserIds() async {
    logger.section('fetchPremiumUserIds() 開始', name: _logName);

    try {
      final users = await _userRepository.findPremiumUsers();

      final userIds = users.map((user) => user.id).toList();

      logger.success('プレミアムユーザーID数: ${userIds.length}件', name: _logName);
      logger.section('fetchPremiumUserIds() 完了', name: _logName);

      return userIds;
    } catch (e, stack) {
      logger.error(
        'エラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
