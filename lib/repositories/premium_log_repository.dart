import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin/premium_log_model.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// プレミアムログのリポジトリ
/// ※ 検索キーはすべて「メールアドレス」で統一
///
/// 対象コレクション: `AppConstants.premiumLogCollection`
/// 提供クエリの目的:
/// - メールアドレス単位の課金ログ検索
/// - Timestamp基準の時系列・期間検索
/// - 管理画面向けの一覧/監視ストリーム提供
///
/// 利用方針:
/// - 管理系 Service 層経由で利用する前提
/// - UI から直接参照しない
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
      'ID': model.email, // メールアドレス
      'Timestamp': Timestamp.fromDate(model.timestamp),
      'Detail': model.detail,
    };
  }

  // ===== PremiumLog Specific Methods =====

  /// 全てのプレミアムログを取得（Timestamp 降順）
  Future<List<PremiumLog>> findAllOrderedByTimestamp() async {
    logger.start('findAllOrderedByTimestamp() 開始', name: _logName);

    try {
      final snapshot =
          await collection.orderBy('Timestamp', descending: true).get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('取得件数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error(
        'findAllOrderedByTimestamp() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// メールアドレスでログを検索（フィールド名の互換性対応）
  Future<List<PremiumLog>> findByEmail(String email) async {
    logger.section('findByEmail($email) 開始', name: _logName);
    logger.info('検索email: $email', name: _logName);

    try {
      // ===== 方法1: 'ID' フィールドで検索 =====
      logger.start('方法1: ID フィールドで検索中...', name: _logName);
      var snapshot = await collection
          // Firestore制約: where + orderBy の複合クエリはインデックス前提。
          .where('ID', isEqualTo: email)
          .orderBy('Timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        logger.success('方法1で発見: ${snapshot.docs.length}件', name: _logName);
        final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();
        logger.section('findByEmail() 完了', name: _logName);
        return results;
      }

      logger.warning('方法1: 見つかりませんでした', name: _logName);

      // ===== 方法2: 'email' フィールドで検索（フォールバック） =====
      logger.start('方法2: email フィールドで検索中...', name: _logName);
      snapshot = await collection
          // Firestore制約: 代替フィールドでも where + orderBy のインデックスが必要。
          .where('email', isEqualTo: email)
          .orderBy('Timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        logger.success('方法2で発見: ${snapshot.docs.length}件', name: _logName);
        final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();
        logger.section('findByEmail() 完了', name: _logName);
        return results;
      }

      logger.warning('方法2: 見つかりませんでした', name: _logName);

      // ===== デバッグ: コレクション内のドキュメント確認 =====
      logger.section('デバッグ: Log_Premium コレクション内容確認', name: _logName);
      final allDocs = await collection.limit(5).get();

      if (allDocs.docs.isEmpty) {
        logger.warning('Log_Premium コレクションが空です！', name: _logName);
      } else {
        logger.info('最初の5件のドキュメント:', name: _logName);
        for (var doc in allDocs.docs) {
          final data = doc.data();
          logger.debug('  Document ID: ${doc.id}', name: _logName);
          logger.debug('    ID: ${data["ID"]}', name: _logName);
          logger.debug('    email: ${data["email"]}', name: _logName);
          logger.debug('    Detail: ${data["Detail"]}', name: _logName);
        }
      }

      logger.warning(
        '検索対象のメールアドレスが見つかりません: $email',
        name: _logName,
      );
      logger.section('findByEmail() 完了（0件）', name: _logName);
      return [];
    } catch (e, stack) {
      logger.error(
        'findByEmail() エラー: $e',
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
    logger.start(
      'addLog() 開始 - email: $email, detail: $detail',
      name: _logName,
    );

    try {
      await collection.add({
        'ID': email,
        'Timestamp': FieldValue.serverTimestamp(),
        'Detail': detail,
      });

      logger.success('ログ追加完了', name: _logName);
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

  /// 期間でログを検索
  Future<List<PremiumLog>> findByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    logger.debug(
      'findByDateRange($startDate ~ $endDate)',
      name: _logName,
    );

    try {
      final snapshot = await collection
          // Firestore制約: 同一フィールド Timestamp の範囲条件 + orderBy は有効。
          // ただし他フィールドと組み合わせる場合は追加インデックスが必要。
          .where(
            'Timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'Timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('期間検索結果: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error(
        'findByDateRange() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 詳細でフィルタ（加入 / 解約など）
  Future<List<PremiumLog>> findByDetail(String detail) async {
    logger.debug('findByDetail($detail)', name: _logName);

    try {
      final snapshot = await collection
          // Firestore制約: where + orderBy の複合クエリはインデックス前提。
          .where('Detail', isEqualTo: detail)
          .orderBy('Timestamp', descending: true)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success(
        'フィルタ結果($detail): ${results.length}件',
        name: _logName,
      );
      return results;
    } catch (e, stack) {
      logger.error(
        'findByDetail() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 最新の N 件を取得
  Future<List<PremiumLog>> findLatest(int limit) async {
    logger.debug('findLatest($limit)', name: _logName);

    try {
      final snapshot = await collection
          .orderBy('Timestamp', descending: true)
          .limit(limit)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('最新${limit}件取得完了', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error(
        'findLatest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// ログをリアルタイム監視（全件）
  Stream<List<PremiumLog>> watchAllLogs() {
    logger.debug('watchAllLogs() - Stream開始', name: _logName);

    return collection
        .orderBy('Timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  /// 特定ユーザー（メールアドレス）のログをリアルタイム監視
  Stream<List<PremiumLog>> watchUserLogsByEmail(String email) {
    logger.debug(
      'watchUserLogsByEmail($email) - Stream開始',
      name: _logName,
    );

    return collection
        // Firestore制約: where + orderBy の複合クエリはインデックス前提。
        .where('ID', isEqualTo: email)
        .orderBy('Timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }
}
