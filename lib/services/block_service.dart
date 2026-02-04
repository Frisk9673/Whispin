import '../models/block.dart';
import '../repositories/block_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';

/// ブロック機能を管理するサービス
///
/// ブロック・解除のビジネスロジックを提供
class BlockService {
  final BlockRepository _blockRepository;
  final UserRepository _userRepository;
  static const String _logName = 'BlockService';

  BlockService({
    required BlockRepository blockRepository,
    required UserRepository userRepository,
  })  : _blockRepository = blockRepository,
        _userRepository = userRepository;

  // ===== ブロックリスト取得（UI用拡張版） =====

  /// ブロックユーザー一覧を取得（ユーザー情報付き）
  ///
  /// [blockerId] ブロックしているユーザーのID
  ///
  /// 戻り値: ブロック情報とユーザー情報のマップのリスト
  /// - id: ブロックされているユーザーのID
  /// - name: ブロックされているユーザーの表示名
  /// - blockId: ブロックID
  Future<List<Map<String, String>>> getBlockedUsersWithInfo(
    String blockerId,
  ) async {
    logger.section('getBlockedUsersWithInfo() 開始', name: _logName);
    logger.info('blockerId: $blockerId', name: _logName);

    try {
      logger.start('Repository経由でブロック一覧取得中...', name: _logName);

      final blocks = await _blockRepository.findBlockedUsers(blockerId);

      logger.success('ブロック取得: ${blocks.length}件', name: _logName);

      // ブロックユーザーの情報を取得
      final List<Map<String, String>> blockedList = [];

      for (var block in blocks) {
        logger.debug('ブロックユーザーID: ${block.blockedId} を取得中...', name: _logName);

        try {
          // Repository経由でユーザー情報を取得
          final blockedUser = await _userRepository.findById(block.blockedId);

          if (blockedUser != null) {
            blockedList.add({
              'id': block.blockedId,
              'name': blockedUser.displayName,
              'blockId': block.id,
            });
            logger.debug('  → ${blockedUser.displayName}', name: _logName);
          } else {
            logger.warning('ユーザー情報なし: ${block.blockedId}', name: _logName);
            blockedList.add({
              'id': block.blockedId,
              'name': block.blockedId,
              'blockId': block.id,
            });
          }
        } catch (e) {
          logger.error('ブロックユーザー情報取得エラー: $e', name: _logName, error: e);
          blockedList.add({
            'id': block.blockedId,
            'name': block.blockedId,
            'blockId': block.id,
          });
        }
      }

      logger.success('ブロック一覧準備完了: ${blockedList.length}人', name: _logName);
      logger.section('getBlockedUsersWithInfo() 完了', name: _logName);

      return blockedList;
    } catch (e, stack) {
      logger.error(
        'getBlockedUsersWithInfo() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== ブロックリスト取得 =====

  /// ユーザーがブロックしているユーザー一覧を取得
  ///
  /// [blockerId] ブロックしているユーザーのID
  ///
  /// 戻り値: ブロック中のユーザーリスト
  Future<List<Block>> getBlockedUsers(String blockerId) async {
    logger.section('getBlockedUsers() 開始', name: _logName);
    logger.info('blockerId: $blockerId', name: _logName);

    try {
      logger.start('Repository経由でブロック一覧取得中...', name: _logName);
      
      final blocks = await _blockRepository.findBlockedUsers(blockerId);
      
      logger.success('ブロック取得: ${blocks.length}件', name: _logName);
      logger.section('getBlockedUsers() 完了', name: _logName);
      
      return blocks;
    } catch (e, stack) {
      logger.error(
        'getBlockedUsers() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// ユーザーをブロックしているユーザー一覧を取得
  ///
  /// [blockedId] ブロックされているユーザーのID
  ///
  /// 戻り値: このユーザーをブロックしているユーザーリスト
  Future<List<Block>> getBlockedBy(String blockedId) async {
    logger.section('getBlockedBy() 開始', name: _logName);
    logger.info('blockedId: $blockedId', name: _logName);

    try {
      logger.start('Repository経由でブロック元一覧取得中...', name: _logName);
      
      final blocks = await _blockRepository.findBlockedBy(blockedId);
      
      logger.success('ブロックされている数: ${blocks.length}件', name: _logName);
      logger.section('getBlockedBy() 完了', name: _logName);
      
      return blocks;
    } catch (e, stack) {
      logger.error(
        'getBlockedBy() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== ブロック実行 =====

  /// ユーザーをブロック
  ///
  /// [blockerId] ブロックする側のユーザーID
  /// [blockedId] ブロックされる側のユーザーID
  ///
  /// 戻り値: 作成されたブロックID
  ///
  /// エラー:
  /// - 自分自身をブロックしようとした
  /// - 既にブロック済み（再アクティブ化される）
  Future<String> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    logger.section('blockUser() 開始', name: _logName);
    logger.info('blockerId: $blockerId', name: _logName);
    logger.info('blockedId: $blockedId', name: _logName);

    // バリデーション: 自分自身をブロックできない
    if (blockerId == blockedId) {
      logger.error('自分自身をブロックすることはできません', name: _logName);
      throw Exception('自分自身をブロックすることはできません');
    }

    try {
      logger.start('Repository経由でブロック実行中...', name: _logName);
      
      final blockId = await _blockRepository.blockUser(blockerId, blockedId);
      
      logger.success('ブロック完了: $blockId', name: _logName);
      logger.section('blockUser() 完了', name: _logName);
      
      return blockId;
    } catch (e, stack) {
      logger.error(
        'blockUser() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== ブロック解除 =====

  /// ブロックを解除（ブロックIDで指定）
  ///
  /// [blockId] ブロックID
  ///
  /// 処理内容:
  /// - activeをfalseに更新（ソフトデリート）
  ///
  /// エラー:
  /// - ブロックが見つからない
  /// - 既に解除済み
  Future<void> unblockById(String blockId) async {
    logger.section('unblockById() 開始', name: _logName);
    logger.info('blockId: $blockId', name: _logName);

    try {
      logger.start('Repository経由でブロック解除中...', name: _logName);
      
      await _blockRepository.unblockById(blockId);
      
      logger.success('ブロック解除完了', name: _logName);
      logger.section('unblockById() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'unblockById() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// ブロックを解除（ユーザーIDで指定）
  ///
  /// [blockerId] ブロックしている側のユーザーID
  /// [blockedId] ブロックされている側のユーザーID
  ///
  /// 処理内容:
  /// - 該当するブロック関係を全て解除
  ///
  /// エラー:
  /// - ブロック関係が見つからない
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    logger.section('unblockUser() 開始', name: _logName);
    logger.info('blockerId: $blockerId', name: _logName);
    logger.info('blockedId: $blockedId', name: _logName);

    try {
      logger.start('Repository経由でブロック解除中...', name: _logName);
      
      await _blockRepository.unblockUser(blockerId, blockedId);
      
      logger.success('ブロック解除完了', name: _logName);
      logger.section('unblockUser() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'unblockUser() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== ブロック状態確認 =====

  /// ブロック関係が存在するか確認
  ///
  /// [blockerId] ブロックしている側のユーザーID
  /// [blockedId] ブロックされている側のユーザーID
  ///
  /// 戻り値: ブロック関係が存在すればtrue
  Future<bool> isBlocked({
    required String blockerId,
    required String blockedId,
  }) async {
    logger.debug('isBlocked($blockerId, $blockedId)', name: _logName);

    try {
      final result = await _blockRepository.isBlocked(blockerId, blockedId);
      
      logger.debug('結果: $result', name: _logName);
      return result;
    } catch (e, stack) {
      logger.error(
        'isBlocked() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 相互ブロック関係を確認
  ///
  /// [userId1] ユーザー1のID
  /// [userId2] ユーザー2のID
  ///
  /// 戻り値: どちらか一方でもブロックしていればtrue
  Future<bool> isMutuallyBlocked({
    required String userId1,
    required String userId2,
  }) async {
    logger.debug('isMutuallyBlocked($userId1, $userId2)', name: _logName);

    try {
      final result = await _blockRepository.isMutuallyBlocked(userId1, userId2);
      
      logger.debug('結果: $result', name: _logName);
      return result;
    } catch (e, stack) {
      logger.error(
        'isMutuallyBlocked() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  // ===== アクティブなブロック数取得 =====

  /// ユーザーのアクティブなブロック数を取得
  ///
  /// [blockerId] ユーザーID
  ///
  /// 戻り値: アクティブなブロック数
  Future<int> countActiveBlocks(String blockerId) async {
    logger.debug('countActiveBlocks($blockerId)', name: _logName);

    try {
      final count = await _blockRepository.countActiveBlocks(blockerId);
      
      logger.success('アクティブなブロック数: $count', name: _logName);
      return count;
    } catch (e, stack) {
      logger.error(
        'countActiveBlocks() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return 0;
    }
  }

  // ===== リアルタイム監視 =====

  /// ブロックリストの変更を監視
  ///
  /// [blockerId] ユーザーID
  ///
  /// 戻り値: ブロックリストのStream
  Stream<List<Block>> watchBlockedUsers(String blockerId) {
    logger.debug('watchBlockedUsers($blockerId) - Stream開始', name: _logName);
    
    return _blockRepository.watchBlockedUsers(blockerId);
  }
}