import '../models/user/block.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// ブロックデータのリポジトリ
class BlockRepository extends BaseRepository<Block> {
  static const String _logName = 'BlockRepository';

  BlockRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.blocksCollection;

  @override
  Block fromMap(Map<String, dynamic> map) => Block.fromMap(map);

  @override
  Map<String, dynamic> toMap(Block model) => model.toMap();

  // ===== Block Specific Methods =====

  /// ユーザーがブロックしているユーザー一覧を取得
  Future<List<Block>> findBlockedUsers(String blockerId) async {
    logger.debug('findBlockedUsers($blockerId)', name: _logName);

    try {
      final snapshot = await collection
          .where('blockerId', isEqualTo: blockerId)
          .where('active', isEqualTo: true)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('ブロック数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findBlockedUsers() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーをブロックしているユーザー一覧を取得
  Future<List<Block>> findBlockedBy(String blockedId) async {
    logger.debug('findBlockedBy($blockedId)', name: _logName);

    try {
      final snapshot = await collection
          .where('blockedId', isEqualTo: blockedId)
          .where('active', isEqualTo: true)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('ブロックされている数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findBlockedBy() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ブロック関係が存在するか確認
  Future<bool> isBlocked(String blockerId, String blockedId) async {
    logger.debug('isBlocked($blockerId, $blockedId)', name: _logName);

    try {
      final snapshot = await collection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stack) {
      logger.error('isBlocked() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// 相互ブロック関係を確認
  Future<bool> isMutuallyBlocked(String userId1, String userId2) async {
    logger.debug('isMutuallyBlocked($userId1, $userId2)', name: _logName);

    try {
      final blocked1 = await isBlocked(userId1, userId2);
      final blocked2 = await isBlocked(userId2, userId1);

      return blocked1 || blocked2;
    } catch (e, stack) {
      logger.error('isMutuallyBlocked() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// ブロックを作成または再アクティブ化
  Future<String> blockUser(String blockerId, String blockedId) async {
    logger.start('blockUser($blockerId, $blockedId) 開始', name: _logName);

    try {
      // 既存のブロック関係を検索
      final snapshot = await collection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // 既存のブロックを再アクティブ化
        final blockId = snapshot.docs.first.id;
        await updateFields(blockId, {'active': true});
        logger.success('ブロック再アクティブ化完了: $blockId', name: _logName);
        return blockId;
      } else {
        // 新規ブロック作成
        final block = Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          blockerId: blockerId,
          blockedId: blockedId,
          active: true,
          createdAt: DateTime.now(),
        );

        final blockId = await create(block, id: block.id);
        logger.success('ブロック作成完了: $blockId', name: _logName);
        return blockId;
      }
    } catch (e, stack) {
      logger.error('blockUser() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ブロックを解除
  Future<void> unblockUser(String blockerId, String blockedId) async {
    logger.start('unblockUser($blockerId, $blockedId) 開始', name: _logName);

    try {
      final snapshot = await collection
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedId', isEqualTo: blockedId)
          .get();

      for (var doc in snapshot.docs) {
        await updateFields(doc.id, {'active': false});
      }

      logger.success('ブロック解除完了', name: _logName);
    } catch (e, stack) {
      logger.error('unblockUser() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ブロックIDでブロック解除
  Future<void> unblockById(String blockId) async {
    logger.start('unblockById($blockId) 開始', name: _logName);

    try {
      await updateFields(blockId, {'active': false});
      logger.success('ブロック解除完了', name: _logName);
    } catch (e, stack) {
      logger.error('unblockById() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーのブロックリストを監視
  Stream<List<Block>> watchBlockedUsers(String blockerId) {
    logger.debug('watchBlockedUsers($blockerId) - Stream開始', name: _logName);

    return collection
        .where('blockerId', isEqualTo: blockerId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  /// アクティブなブロック数を取得
  Future<int> countActiveBlocks(String blockerId) async {
    logger.debug('countActiveBlocks($blockerId)', name: _logName);

    try {
      final snapshot = await collection
          .where('blockerId', isEqualTo: blockerId)
          .where('active', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e, stack) {
      logger.error('countActiveBlocks() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return 0;
    }
  }
}
