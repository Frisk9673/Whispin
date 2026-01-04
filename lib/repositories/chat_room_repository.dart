import '../models/chat_room.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// チャットルームデータのリポジトリ
class ChatRoomRepository extends BaseRepository<ChatRoom> {
  static const String _logName = 'ChatRoomRepository';

  ChatRoomRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.roomsCollection;

  @override
  ChatRoom fromMap(Map<String, dynamic> map) => ChatRoom.fromMap(map);

  @override
  Map<String, dynamic> toMap(ChatRoom model) => model.toMap();

  // ===== ChatRoom Specific Methods =====

  /// ステータス別にルームを取得
  Future<List<ChatRoom>> findByStatus(int status) async {
    logger.debug('findByStatus($status)', name: _logName);

    try {
      final snapshot = await collection
          .where('status', isEqualTo: status)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('ステータス$status のルーム数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findByStatus() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 待機中のルームを取得
  Future<List<ChatRoom>> findWaitingRooms() async {
    return findByStatus(AppConstants.roomStatusWaiting);
  }

  /// アクティブなルームを取得
  Future<List<ChatRoom>> findActiveRooms() async {
    return findByStatus(AppConstants.roomStatusActive);
  }

  /// ユーザーが参加中のルームを取得
  Future<List<ChatRoom>> findUserRooms(String userId) async {
    logger.debug('findUserRooms($userId)', name: _logName);

    try {
      // id1がuserIdのルームを検索
      final snapshot1 = await collection
          .where('id1', isEqualTo: userId)
          .get();

      // id2がuserIdのルームを検索
      final snapshot2 = await collection
          .where('id2', isEqualTo: userId)
          .get();

      final results = [
        ...snapshot1.docs.map((doc) => fromMap(doc.data())),
        ...snapshot2.docs.map((doc) => fromMap(doc.data())),
      ];

      logger.success('ユーザー$userId のルーム数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findUserRooms() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 参加可能なルームを取得（1人待ちのルーム）
  Future<List<ChatRoom>> findJoinableRooms({String? excludeUserId}) async {
    logger.debug('findJoinableRooms(exclude: $excludeUserId)', name: _logName);

    try {
      final snapshot = await collection
          .where('status', isEqualTo: AppConstants.roomStatusWaiting)
          .get();

      var results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      // 期限切れでないルームのみフィルタ
      results = results.where((room) {
        final now = DateTime.now();
        return room.expiresAt.isAfter(now);
      }).toList();

      // 指定ユーザーのルームを除外
      if (excludeUserId != null) {
        results = results.where((room) {
          return room.id1 != excludeUserId && room.id2 != excludeUserId;
        }).toList();
      }

      logger.success('参加可能なルーム数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findJoinableRooms() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ルームステータスを更新
  Future<void> updateStatus(String roomId, int status) async {
    logger.debug('updateStatus($roomId, $status)', name: _logName);

    try {
      await updateFields(roomId, {'status': status});
      logger.success('ルームステータス更新完了', name: _logName);
    } catch (e, stack) {
      logger.error('updateStatus() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ルームにユーザーを参加させる
  Future<void> joinRoom(String roomId, String userId) async {
    logger.start('joinRoom($roomId, $userId) 開始', name: _logName);

    try {
      final room = await findById(roomId);
      if (room == null) {
        throw Exception('ルームが見つかりません: $roomId');
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: AppConstants.defaultChatDurationMinutes));

      if (room.id1 == null || room.id1!.isEmpty) {
        // id1スロットに参加
        await updateFields(roomId, {
          'id1': userId,
          'status': AppConstants.roomStatusActive,
          'startedAt': now.toIso8601String(),
          'expiresAt': expiresAt.toIso8601String(),
        });
      } else if (room.id2 == null || room.id2!.isEmpty) {
        // id2スロットに参加
        await updateFields(roomId, {
          'id2': userId,
          'status': AppConstants.roomStatusActive,
          'startedAt': now.toIso8601String(),
          'expiresAt': expiresAt.toIso8601String(),
        });
      } else {
        throw Exception('ルームは満員です');
      }

      logger.success('ルーム参加完了', name: _logName);
    } catch (e, stack) {
      logger.error('joinRoom() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ルームからユーザーを退出させる
  Future<void> leaveRoom(String roomId, String userId) async {
    logger.start('leaveRoom($roomId, $userId) 開始', name: _logName);

    try {
      final room = await findById(roomId);
      if (room == null) {
        logger.warning('ルームが見つかりません: $roomId', name: _logName);
        return;
      }

      if (room.id1 == userId) {
        await updateFields(roomId, {'id1': ''});
      } else if (room.id2 == userId) {
        await updateFields(roomId, {'id2': ''});
      }

      // 両方が退出した場合はルームを削除
      final updatedRoom = await findById(roomId);
      if (updatedRoom != null &&
          (updatedRoom.id1?.isEmpty ?? true) &&
          (updatedRoom.id2?.isEmpty ?? true)) {
        await delete(roomId);
        logger.success('ルーム削除完了（全員退出）', name: _logName);
      } else {
        logger.success('ルーム退出完了', name: _logName);
      }
    } catch (e, stack) {
      logger.error('leaveRoom() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// コメントを更新
  Future<void> updateComment(String roomId, String userId, String comment) async {
    logger.debug('updateComment($roomId, $userId)', name: _logName);

    try {
      final room = await findById(roomId);
      if (room == null) {
        throw Exception('ルームが見つかりません: $roomId');
      }

      if (room.id1 == userId) {
        await updateFields(roomId, {'comment1': comment});
      } else if (room.id2 == userId) {
        await updateFields(roomId, {'comment2': comment});
      } else {
        throw Exception('このルームのメンバーではありません');
      }

      logger.success('コメント更新完了', name: _logName);
    } catch (e, stack) {
      logger.error('updateComment() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 延長回数をインクリメント
  Future<void> incrementExtensionCount(String roomId) async {
    logger.debug('incrementExtensionCount($roomId)', name: _logName);

    try {
      final room = await findById(roomId);
      if (room == null) {
        throw Exception('ルームが見つかりません: $roomId');
      }

      final newCount = room.extensionCount + 1;
      await updateFields(roomId, {'extensionCount': newCount});

      logger.success('延長回数更新: $newCount', name: _logName);
    } catch (e, stack) {
      logger.error('incrementExtensionCount() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 有効期限を延長
  Future<void> extendExpiration(String roomId, int minutes) async {
    logger.start('extendExpiration($roomId, $minutes分)', name: _logName);

    try {
      final room = await findById(roomId);
      if (room == null) {
        throw Exception('ルームが見つかりません: $roomId');
      }

      final newExpiresAt = room.expiresAt.add(Duration(minutes: minutes));
      await updateFields(roomId, {
        'expiresAt': newExpiresAt.toIso8601String(),
      });

      await incrementExtensionCount(roomId);

      logger.success('有効期限延長完了: ${newExpiresAt.toIso8601String()}', name: _logName);
    } catch (e, stack) {
      logger.error('extendExpiration() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 期限切れルームを取得
  Future<List<ChatRoom>> findExpiredRooms() async {
    logger.debug('findExpiredRooms()', name: _logName);

    try {
      final snapshot = await collection
          .where('status', isEqualTo: AppConstants.roomStatusActive)
          .get();

      final now = DateTime.now();
      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .where((room) => room.expiresAt.isBefore(now))
          .toList();

      logger.success('期限切れルーム数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findExpiredRooms() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーのルーム参加を監視
  Stream<List<ChatRoom>> watchUserRooms(String userId) {
    logger.debug('watchUserRooms($userId) - Stream開始', name: _logName);

    // 両方のクエリ結果を結合する必要があるため、
    // 簡易実装として全ルームを監視してフィルタ
    return watchAll().map((rooms) {
      return rooms.where((room) {
        return room.id1 == userId || room.id2 == userId;
      }).toList();
    });
  }
}