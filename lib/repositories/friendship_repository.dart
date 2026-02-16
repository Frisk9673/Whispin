import '../models/user/friendship.dart';
import '../models/user/friend_request.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// フレンドシップデータのリポジトリ。
///
/// 対象コレクション: `AppConstants.friendshipsCollection`
/// 提供クエリの目的:
/// - ユーザーのフレンド関係（双方向）取得
/// - 2ユーザー間のフレンド成立判定
/// - フレンド関係の非アクティブ化
///
/// 利用方針:
/// - Service 層経由で利用する前提
/// - UI から直接参照しない
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
      // 次は Firestore.collection.where(...).get() で Friendship 実データ取得へ渡す。
      final snapshot1 = await collection
          // Firestore制約: 複合where（userId + active）は複合インデックス前提。
          .where('userId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();

      final snapshot2 = await collection
          // Firestore制約: 複合where（friendId + active）は複合インデックス前提。
          .where('friendId', isEqualTo: userId)
          .where('active', isEqualTo: true)
          .get();

      final results = [
        ...snapshot1.docs.map(
          (doc) => fromMap({...doc.data(), 'id': doc.id}),
        ),
        ...snapshot2.docs.map(
          (doc) => fromMap({...doc.data(), 'id': doc.id}),
        ),
      ];

      logger.success('フレンド数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error(
        'findUserFriends() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'isFriend() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'deactivateFriendship() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'removeFriendship() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// ユーザーのフレンド変更を監視
  Stream<List<Friendship>> watchUserFriends(String userId) {
    logger.debug('watchUserFriends($userId) - Stream開始', name: _logName);

    return watchAll().map((friendships) {
      return friendships.where((f) {
        return f.active && (f.userId == userId || f.friendId == userId);
      }).toList();
    });
  }
}

/// フレンドリクエストのリポジトリ（相互承認機能付き）。
///
/// 対象コレクション: `AppConstants.friendRequestsCollection`
/// 提供クエリの目的:
/// - 受信/送信リクエストの検索
/// - 重複/相互リクエストの判定
/// - 承認・拒否ステータス更新
///
/// 利用方針:
/// - Service 層経由で利用する前提
/// - UI から直接参照しない
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
          .where(
            (r) => r.status == AppConstants.friendRequestStatusPending,
          )
          .toList();

      logger.success('受信リクエスト数: ${pending.length}件', name: _logName);
      return pending;
    } catch (e, stack) {
      logger.error(
        'findReceivedRequests() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'findSentRequests() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'acceptRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
      logger.error(
        'rejectRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
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
          .where(
            'status',
            isEqualTo: AppConstants.friendRequestStatusPending,
          )
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stack) {
      logger.error(
        'hasExistingRequest() エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// 相互フレンドリクエストをチェック
  Future<FriendRequest?> findMutualRequest(
    String senderId,
    String receiverId,
  ) async {
    final snap = await collection
        // Firestore制約: senderId + receiverId + status の3条件whereは
        // 複合インデックス前提。未作成時はコンソール提示リンクで作成すること。
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where(
          'status',
          isEqualTo: AppConstants.friendRequestStatusPending,
        )
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return fromMap({...doc.data(), 'id': doc.id});
  }

  /// フレンドリクエスト送信（相互リクエスト自動承認）
  Future<Map<String, dynamic>> sendFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    logger.section('sendFriendRequest', name: _logName);

    if (senderId == receiverId) {
      throw Exception('自分自身には送れません');
    }

    final friendshipRepo = FriendshipRepository();

    // 既にフレンドなら何もしない
    final alreadyFriend =
        await friendshipRepo.isFriend(senderId, receiverId);

    if (alreadyFriend) {
      return {
        'success': false,
        'message': '既にフレンドです',
      };
    }

    // 片方向リクエスト重複防止
    if (await hasExistingRequest(senderId, receiverId)) {
      throw Exception('既にリクエストを送信しています');
    }

    // 相互リクエストチェック
    final mutual =
        await findMutualRequest(receiverId, senderId);

    if (mutual != null) {
      await acceptRequest(mutual.id);

      // friendship 作成前に再チェック（保険）
      final stillNotFriend =
          !(await friendshipRepo.isFriend(senderId, receiverId));

      if (stillNotFriend) {
        final friendship = Friendship(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: senderId,
          friendId: receiverId,
          active: true,
          createdAt: DateTime.now(),
        );

        await friendshipRepo.create(friendship, id: friendship.id);
      }

      return {
        'success': true,
        'autoAccepted': true,
        'message': '相互リクエストにより自動承認されました',
      };
    }

    // 通常のリクエスト作成
    final request = FriendRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      status: AppConstants.friendRequestStatusPending,
      createdAt: DateTime.now(),
    );

    await create(request, id: request.id);

    return {
      'success': true,
      'autoAccepted': false,
      'message': 'フレンドリクエストを送信しました',
    };
  }

  /// 受信リクエストを監視
  Stream<List<FriendRequest>> watchReceivedRequests(String userId) {
    return collection
        .where('receiverId', isEqualTo: userId)
        .where(
          'status',
          isEqualTo: AppConstants.friendRequestStatusPending,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
