import '../models/friendship.dart';
import '../models/friend_request.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// フレンドシップデータのリポジトリ
class FriendshipRepository extends BaseRepository<Friendship> {
  static const String _logName = 'FriendshipRepository';

  FriendshipRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.friendshipsCollection;

  @override
  Friendship fromMap(Map<String, dynamic> map) => Friendship.fromMap(map);

  @override
  Map<String, dynamic> toMap(Friendship model) => model.toMap();

  // ===== Friendship Specific Methods =====

  /// ユーザーのフレンド一覧を取得
  Future<List<Friendship>> findUserFriends(String userId) async {
    logger.debug('findUserFriends($userId)', name: _logName);

    try {
      // userIdがuserIdのフレンドシップ
      final snapshot1 = await collection
          .where('userId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();

      // userIdがfriendIdのフレンドシップ
      final snapshot2 = await collection
          .where('friendId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();

      final results = [
        ...snapshot1.docs.map((doc) => fromMap(doc.data())),
        ...snapshot2.docs.map((doc) => fromMap(doc.data())),
      ];

      logger.success('フレンド数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findUserFriends() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// フレンドシップが存在するか確認
  Future<bool> isFriend(String userId1, String userId2) async {
    logger.debug('isFriend($userId1, $userId2)', name: _logName);

    try {
      final snapshot1 = await collection
          .where('userId', isEqualTo: userId1)
          .where('friendId', isEqualTo: userId2)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot1.docs.isNotEmpty) return true;

      final snapshot2 = await collection
          .where('userId', isEqualTo: userId2)
          .where('friendId', isEqualTo: userId1)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      return snapshot2.docs.isNotEmpty;
    } catch (e, stack) {
      logger.error('isFriend() エラー: $e', name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// フレンドシップを非アクティブ化（削除）
  Future<void> deactivateFriendship(String friendshipId) async {
    logger.start('deactivateFriendship($friendshipId) 開始', name: _logName);

    try {
      await updateFields(friendshipId, {'active': false});
      logger.success('フレンドシップ削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('deactivateFriendship() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 2人のユーザー間のフレンドシップを削除
  Future<void> removeFriendship(String userId1, String userId2) async {
    logger.start('removeFriendship($userId1, $userId2) 開始', name: _logName);

    try {
      final snapshot1 = await collection
          .where('userId', isEqualTo: userId1)
          .where('friendId', isEqualTo: userId2)
          .get();

      for (var doc in snapshot1.docs) {
        await updateFields(doc.id, {'active': false});
      }

      final snapshot2 = await collection
          .where('userId', isEqualTo: userId2)
          .where('friendId', isEqualTo: userId1)
          .get();

      for (var doc in snapshot2.docs) {
        await updateFields(doc.id, {'active': false});
      }

      logger.success('フレンドシップ削除完了', name: _logName);
    } catch (e, stack) {
      logger.error('removeFriendship() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーのフレンド変更を監視
  Stream<List<Friendship>> watchUserFriends(String userId) {
    logger.debug('watchUserFriends($userId) - Stream開始', name: _logName);

    // 簡易実装：全体を監視してフィルタ
    return watchAll().map((friendships) {
      return friendships.where((f) {
        return f.active && (f.userId == userId || f.friendId == userId);
      }).toList();
    });
  }
}

/// フレンドリクエストのリポジトリ
class FriendRequestRepository extends BaseRepository<FriendRequest> {
  static const String _logName = 'FriendRequestRepository';

  FriendRequestRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.friendRequestsCollection;

  @override
  FriendRequest fromMap(Map<String, dynamic> map) => FriendRequest.fromMap(map);

  @override
  Map<String, dynamic> toMap(FriendRequest model) => model.toMap();

  // ===== FriendRequest Specific Methods =====

  /// ユーザーが受け取ったフレンドリクエストを取得
  Future<List<FriendRequest>> findReceivedRequests(String userId) async {
    logger.debug('findReceivedRequests($userId)', name: _logName);

    try {
      final results = await findWhere(field: 'receiverId', value: userId);
      
      final pending = results
          .where((r) => r.status == AppConstants.friendRequestStatusPending)
          .toList();

      logger.success('受信リクエスト数: ${pending.length}件', name: _logName);
      return pending;
    } catch (e, stack) {
      logger.error('findReceivedRequests() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーが送信したフレンドリクエストを取得
  Future<List<FriendRequest>> findSentRequests(String userId) async {
    logger.debug('findSentRequests($userId)', name: _logName);

    try {
      final results = await findWhere(field: 'senderId', value: userId);
      logger.success('送信リクエスト数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findSentRequests() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// リクエストを承認
  Future<void> acceptRequest(String requestId) async {
    logger.start('acceptRequest($requestId) 開始', name: _logName);

    try {
      await updateFields(requestId, {
        'status': AppConstants.friendRequestStatusAccepted,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      logger.success('リクエスト承認完了', name: _logName);
    } catch (e, stack) {
      logger.error('acceptRequest() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// リクエストを拒否
  Future<void> rejectRequest(String requestId) async {
    logger.start('rejectRequest($requestId) 開始', name: _logName);

    try {
      await updateFields(requestId, {
        'status': AppConstants.friendRequestStatusRejected,
        'respondedAt': DateTime.now().toIso8601String(),
      });

      logger.success('リクエスト拒否完了', name: _logName);
    } catch (e, stack) {
      logger.error('rejectRequest() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 既存のリクエストが存在するか確認
  Future<bool> hasExistingRequest(String senderId, String receiverId) async {
    logger.debug('hasExistingRequest($senderId, $receiverId)', name: _logName);

    try {
      final snapshot = await collection
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: AppConstants.friendRequestStatusPending)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stack) {
      logger.error('hasExistingRequest() エラー: $e', name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// ユーザーの受信リクエストを監視
  Stream<List<FriendRequest>> watchReceivedRequests(String userId) {
    logger.debug('watchReceivedRequests($userId) - Stream開始', name: _logName);

    return collection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: AppConstants.friendRequestStatusPending)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();
    });
  }
}