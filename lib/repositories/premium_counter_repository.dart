import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/admin/premium_counter.dart';
import '../utils/app_logger.dart';

/// プレミアム会員数カウンターのリポジトリ
class PremiumCounterRepository {
  static const String _logName = 'PremiumCounterRepository';
  static const String _collectionName = AppConstants.premiumCounterCollection;
  static const String _documentId = 'counter';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// カウンターを取得
  Future<PremiumCounter> getCounter() async {
    logger.debug('getCounter() 開始', name: _logName);

    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        logger.warning('カウンタードキュメントが存在しません → 初期化', name: _logName);
        return await _initializeCounter();
      }

      final data = doc.data();
      if (data == null) {
        logger.warning('カウンターデータがnull → 初期化', name: _logName);
        return await _initializeCounter();
      }

      final counter = PremiumCounter.fromMap(data);
      logger.success('カウンター取得: ${counter.count}人', name: _logName);
      return counter;
    } catch (e, stack) {
      logger.error('getCounter() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// カウンターを初期化（実際の会員数を計算）
  Future<PremiumCounter> _initializeCounter() async {
    logger.section('カウンター初期化開始', name: _logName);

    try {
      // 実際のプレミアム会員数を計算
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('premium', isEqualTo: true)
          .where('deletedAt', isNull: true)
          .get();

      final actualCount = snapshot.docs.length;

      logger.info('実際のプレミアム会員数: $actualCount人', name: _logName);

      // カウンターを初期化
      final counter = PremiumCounter(
        count: actualCount,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(counter.toMap());

      logger.success('カウンター初期化完了: $actualCount人', name: _logName);
      logger.section('カウンター初期化完了', name: _logName);

      return counter;
    } catch (e, stack) {
      logger.error('初期化エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// カウンターをインクリメント（契約時）
  Future<void> increment() async {
    logger.section('カウンターインクリメント開始', name: _logName);

    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set({
        'count': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logger.success('カウンター +1 完了', name: _logName);
      logger.section('カウンターインクリメント完了', name: _logName);
    } catch (e, stack) {
      logger.error('インクリメントエラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// カウンターをデクリメント（解約時）
  Future<void> decrement() async {
    logger.section('カウンターデクリメント開始', name: _logName);

    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set({
        'count': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      logger.success('カウンター -1 完了', name: _logName);
      logger.section('カウンターデクリメント完了', name: _logName);
    } catch (e, stack) {
      logger.error('デクリメントエラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// カウンターをリアルタイム監視
  Stream<PremiumCounter> watchCounter() {
    logger.debug('watchCounter() - Stream開始', name: _logName);

    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        logger.warning('カウンタードキュメントが存在しません', name: _logName);
        return PremiumCounter(
          count: 0,
          lastUpdated: DateTime.now(),
        );
      }

      final counter = PremiumCounter.fromMap(snapshot.data()!);
      logger.debug('カウンター更新: ${counter.count}人', name: _logName);
      return counter;
    });
  }

  /// カウンターを手動で再計算（修正用）
  Future<PremiumCounter> recalculate() async {
    logger.section('カウンター再計算開始', name: _logName);

    try {
      // 実際のプレミアム会員数を計算
      final snapshot = await _firestore
          .collection('users')
          .where('premium', isEqualTo: true)
          .where('deletedAt', isNull: true)
          .get();

      final actualCount = snapshot.docs.length;

      logger.info('実際のプレミアム会員数: $actualCount人', name: _logName);

      // 現在のカウンターを取得
      final currentDoc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      final currentCount = currentDoc.exists
          ? (currentDoc.data()?['count'] as int? ?? 0)
          : 0;

      logger.info('カウンター値: $currentCount人', name: _logName);

      if (currentCount != actualCount) {
        logger.warning(
          'カウンター不一致! カウンター:$currentCount ≠ 実際:$actualCount',
          name: _logName,
        );
        logger.info('カウンターを修正します...', name: _logName);
      }

      // カウンターを正しい値に更新
      final counter = PremiumCounter(
        count: actualCount,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(counter.toMap());

      logger.success('カウンター再計算完了: $actualCount人', name: _logName);
      logger.section('カウンター再計算完了', name: _logName);

      return counter;
    } catch (e, stack) {
      logger.error('再計算エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }
}