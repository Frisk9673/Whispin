import '../../models/user/friendship.dart';
import '../../models/user/friend_request.dart';
import '../../repositories/friendship_repository.dart';
import '../../utils/app_logger.dart';

/// フレンドシップ管理サービス
///
/// フレンドリクエストの承認・拒否、フレンドの削除などのビジネスロジックを提供
class FriendshipService {
  final FriendshipRepository _friendshipRepository;
  final FriendRequestRepository _friendRequestRepository;
  static const String _logName = 'FriendshipService';

  FriendshipService({
    required FriendshipRepository friendshipRepository,
    required FriendRequestRepository friendRequestRepository,
  })  : _friendshipRepository = friendshipRepository,
        _friendRequestRepository = friendRequestRepository;

  // ===== フレンドリクエスト承認 =====

  /// フレンドリクエストを承認してフレンドシップを作成
  ///
  /// [request] 承認するフレンドリクエスト
  ///
  /// 処理内容:
  /// 1. リクエストステータスを'accepted'に更新
  /// 2. Friendshipドキュメントを作成
  ///
  /// エラー:
  /// - リクエストが見つからない
  /// - リクエストが既に処理済み
  /// - Firestore更新エラー
  Future<void> acceptFriendRequest(FriendRequest request) async {
    logger.section('acceptFriendRequest() 開始', name: _logName);
    logger.info('requestId: ${request.id}', name: _logName);
    logger.info('senderId: ${request.senderId}', name: _logName);
    logger.info('receiverId: ${request.receiverId}', name: _logName);

    try {
      // === 1. リクエストを承認状態に更新 ===
      logger.start('リクエスト承認処理中...', name: _logName);
      await _friendRequestRepository.acceptRequest(request.id);
      logger.success('リクエスト承認完了', name: _logName);

      // === 2. フレンドシップを作成 ===
      logger.start('フレンドシップ作成中...', name: _logName);
      
      final friendship = Friendship(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: request.senderId,
        friendId: request.receiverId,
        active: true,
        createdAt: DateTime.now(),
      );

      logger.debug('Friendship作成:', name: _logName);
      logger.debug('  id: ${friendship.id}', name: _logName);
      logger.debug('  userId: ${friendship.userId}', name: _logName);
      logger.debug('  friendId: ${friendship.friendId}', name: _logName);
      logger.debug('  active: ${friendship.active}', name: _logName);

      await _friendshipRepository.create(friendship, id: friendship.id);
      logger.success('フレンドシップ作成完了', name: _logName);

      logger.section('acceptFriendRequest() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'acceptFriendRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンドリクエスト拒否 =====

  /// フレンドリクエストを拒否
  ///
  /// [requestId] 拒否するリクエストのID
  ///
  /// 処理内容:
  /// - リクエストステータスを'rejected'に更新
  ///
  /// エラー:
  /// - リクエストが見つからない
  /// - リクエストが既に処理済み
  Future<void> rejectFriendRequest(String requestId) async {
    logger.section('rejectFriendRequest() 開始', name: _logName);
    logger.info('requestId: $requestId', name: _logName);

    try {
      logger.start('リクエスト拒否処理中...', name: _logName);
      await _friendRequestRepository.rejectRequest(requestId);
      logger.success('リクエスト拒否完了', name: _logName);

      logger.section('rejectFriendRequest() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'rejectFriendRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンド削除 =====

  /// フレンドシップを削除（非アクティブ化）
  ///
  /// [userId1] ユーザー1のID
  /// [userId2] ユーザー2のID
  ///
  /// 処理内容:
  /// - 両方向のフレンドシップをactiveをfalseに更新
  ///
  /// エラー:
  /// - フレンドシップが見つからない
  Future<void> removeFriend({
    required String userId1,
    required String userId2,
  }) async {
    logger.section('removeFriend() 開始', name: _logName);
    logger.info('userId1: $userId1', name: _logName);
    logger.info('userId2: $userId2', name: _logName);

    try {
      logger.start('フレンドシップ削除中...', name: _logName);
      await _friendshipRepository.removeFriendship(userId1, userId2);
      logger.success('フレンドシップ削除完了', name: _logName);

      logger.section('removeFriend() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'removeFriend() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== ブロック&フレンド削除 =====

  /// フレンドをブロックしてフレンドシップを削除
  ///
  /// [blockerId] ブロックする側のユーザーID
  /// [blockedId] ブロックされる側のユーザーID
  /// [blockRepository] BlockRepositoryインスタンス
  ///
  /// 処理内容:
  /// 1. ブロック追加
  /// 2. フレンドシップ削除
  ///
  /// エラー:
  /// - ブロック追加失敗
  /// - フレンドシップ削除失敗
  Future<void> blockAndRemoveFriend({
    required String blockerId,
    required String blockedId,
    required dynamic blockRepository, // BlockRepository型
  }) async {
    logger.section('blockAndRemoveFriend() 開始', name: _logName);
    logger.info('blockerId: $blockerId', name: _logName);
    logger.info('blockedId: $blockedId', name: _logName);

    try {
      // === 1. ブロック追加 ===
      logger.start('ブロック追加中...', name: _logName);
      await blockRepository.blockUser(blockerId, blockedId);
      logger.success('ブロック追加完了', name: _logName);

      // === 2. フレンドシップ削除 ===
      logger.start('フレンドシップ削除中...', name: _logName);
      await _friendshipRepository.removeFriendship(blockerId, blockedId);
      logger.success('フレンドシップ削除完了', name: _logName);

      logger.section('blockAndRemoveFriend() 完了', name: _logName);
    } catch (e, stack) {
      logger.error(
        'blockAndRemoveFriend() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンドリクエスト送信 =====

  /// フレンドリクエストを送信（相互リクエスト自動承認対応）
  ///
  /// [senderId] 送信者のID
  /// [receiverId] 受信者のID
  ///
  /// 戻り値:
  /// - success: 成功したかどうか
  /// - autoAccepted: 相互リクエストで自動承認されたか
  /// - message: 結果メッセージ
  ///
  /// エラー:
  /// - 自分自身への送信
  /// - 既にフレンド
  /// - 既にリクエスト送信済み
  Future<Map<String, dynamic>> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    logger.section('sendFriendRequest() 開始', name: _logName);
    logger.info('senderId: $senderId', name: _logName);
    logger.info('receiverId: $receiverId', name: _logName);

    try {
      final result = await _friendRequestRepository.sendFriendRequest(
        senderId: senderId,
        receiverId: receiverId,
      );

      logger.success('sendFriendRequest() 完了', name: _logName);
      logger.info('Result: $result', name: _logName);

      return result;
    } catch (e, stack) {
      logger.error(
        'sendFriendRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンド一覧取得 =====

  /// ユーザーのフレンド一覧を取得
  ///
  /// [userId] ユーザーID
  ///
  /// 戻り値: アクティブなフレンドシップのリスト
  Future<List<Friendship>> getUserFriends(String userId) async {
    logger.debug('getUserFriends($userId)', name: _logName);

    try {
      // 次は FriendshipRepository.findUserFriends() で永続層クエリ処理へ渡す。
      final friends = await _friendshipRepository.findUserFriends(userId);
      logger.success('フレンド数: ${friends.length}人', name: _logName);
      return friends;
    } catch (e, stack) {
      logger.error(
        'getUserFriends() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンドリクエスト一覧取得 =====

  /// 受信したフレンドリクエスト一覧を取得
  ///
  /// [userId] ユーザーID
  ///
  /// 戻り値: ペンディング状態のリクエストリスト
  Future<List<FriendRequest>> getReceivedRequests(String userId) async {
    logger.debug('getReceivedRequests($userId)', name: _logName);

    try {
      final requests = await _friendRequestRepository.findReceivedRequests(userId);
      logger.success('受信リクエスト数: ${requests.length}件', name: _logName);
      return requests;
    } catch (e, stack) {
      logger.error(
        'getReceivedRequests() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// 送信したフレンドリクエスト一覧を取得
  ///
  /// [userId] ユーザーID
  ///
  /// 戻り値: 送信したリクエストリスト
  Future<List<FriendRequest>> getSentRequests(String userId) async {
    logger.debug('getSentRequests($userId)', name: _logName);

    try {
      final requests = await _friendRequestRepository.findSentRequests(userId);
      logger.success('送信リクエスト数: ${requests.length}件', name: _logName);
      return requests;
    } catch (e, stack) {
      logger.error(
        'getSentRequests() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ===== フレンド状態チェック =====

  /// 2人のユーザーがフレンドかどうかを確認
  ///
  /// [userId1] ユーザー1のID
  /// [userId2] ユーザー2のID
  ///
  /// 戻り値: フレンドであればtrue
  Future<bool> isFriend(String userId1, String userId2) async {
    logger.debug('isFriend($userId1, $userId2)', name: _logName);

    try {
      final result = await _friendshipRepository.isFriend(userId1, userId2);
      logger.debug('結果: $result', name: _logName);
      return result;
    } catch (e, stack) {
      logger.error(
        'isFriend() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}