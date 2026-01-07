import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/premium_log_model.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// プレミアムログのリポジトリ
class PremiumLogRepository extends BaseRepository<PremiumLog> {
  static const String _logName = 'PremiumLogRepository';

  PremiumLogRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.premiumLogCollection;

  @override
  PremiumLog fromMap(Map<String, dynamic> map) => PremiumLog.fromMap(map);

  @override
  Map<String, dynamic> toMap(PremiumLog model) {
    return {
      'ID': model.email,
      'Timestamp': Timestamp.fromDate(model.timestamp),
      'Detail': model.detail,
    };
  }

  // ===== PremiumLog Specific Methods =====

  /// 全てのプレミアムログを取得（降順）
  Future<List<PremiumLog>> findAllOrderedByTimestamp() async {
    logger.start('findAllOrderedByTimestamp() 開始', name: _logName);

    try {
      final snapshot = await collection
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('取得件数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findAllOrderedByTimestamp() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 電話番号でログを検索
  Future<List<PremiumLog>> findByPhoneNumber(String phoneNumber) async {
    logger.debug('findByPhoneNumber($phoneNumber)', name: _logName);

    try {
      final snapshot = await collection
          .where('ID', isEqualTo: phoneNumber)
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('検索結果: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findByPhoneNumber() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ログを追加
  Future<void> addLog({
    required String email,
    required String detail,
  }) async {
    logger.start('addLog() 開始 - email: $email, detail: $detail', name: _logName);

    try {
      await collection.add({
        'ID': email,
        'Timestamp': FieldValue.serverTimestamp(),
        'Detail': detail,
      });

      logger.success('ログ追加完了', name: _logName);
    } catch (e, stack) {
      logger.error('addLog() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 期間でログを検索
  Future<List<PremiumLog>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    logger.debug('findByDateRange($startDate ~ $endDate)', name: _logName);

    try {
      final snapshot = await collection
          .where('Timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('Timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('期間検索結果: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findByDateRange() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 詳細でフィルタ（加入/解約）
  Future<List<PremiumLog>> findByDetail(String detail) async {
    logger.debug('findByDetail($detail)', name: _logName);

    try {
      final snapshot = await collection
          .where('Detail', isEqualTo: detail)
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('フィルタ結果($detail): ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findByDetail() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 最新のN件を取得
  Future<List<PremiumLog>> findLatest(int limit) async {
    logger.debug('findLatest($limit)', name: _logName);

    try {
      final snapshot = await collection
          .orderBy('Timestamp', descending: true)
          .limit(limit)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('最新${limit}件取得完了', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findLatest() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ログをリアルタイム監視
  Stream<List<PremiumLog>> watchAllLogs() {
    logger.debug('watchAllLogs() - Stream開始', name: _logName);

    return collection
        .orderBy('Timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();
    });
  }

  /// 特定ユーザーのログを監視
  Stream<List<PremiumLog>> watchUserLogs(String phoneNumber) {
    logger.debug('watchUserLogs($phoneNumber) - Stream開始', name: _logName);

    return collection
        .where('ID', isEqualTo: phoneNumber)
        .orderBy('Timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();
    });
  }
}