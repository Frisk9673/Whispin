import 'dart:async';
import '../models/chat_room.dart';
import '../models/extension_request.dart';
import '../constants/app_constants.dart';
import '../repositories/chat_room_repository.dart';
import 'storage_service.dart';
import '../utils/app_logger.dart';

/// チャットサービス（Repository層を使用）
class ChatService {
  final StorageService _storageService;
  final ChatRoomRepository _roomRepository = ChatRoomRepository();

  final Map<String, Timer> _roomTimers = {};
  final Map<String, Timer> _extensionPollingTimers = {};
  static const String _logName = 'ChatService';

  ChatService(this._storageService);

  // ===== ルーム検索機能 =====

  /// ルームを検索（topic名で検索 + ブロックフィルタ）
  ///
  /// [searchQuery] 検索クエリ（ルーム名）
  /// [currentUserId] 現在のユーザーID
  /// [blockRepository] BlockRepositoryインスタンス
  ///
  /// 戻り値: フィルタリング済みのルームリスト
  ///
  /// 処理内容:
  /// 1. ブロック関係を取得
  /// 2. 全ルームを取得
  /// 3. 以下の条件でフィルタリング:
  ///    - topic名が部分一致（大文字小文字区別なし）
  ///    - 参加待ち状態（status = 0）
  ///    - 期限切れでない
  ///    - ブロック関係のないユーザー
  /// 4. 作成日時でソート（新しい順）
  Future<List<ChatRoom>> searchRooms({
    required String searchQuery,
    required String currentUserId,
    required dynamic blockRepository, // BlockRepository型
  }) async {
    logger.section('searchRooms() 開始', name: _logName);
    logger.info('検索キーワード: $searchQuery', name: _logName);
    logger.info('検索ユーザー: $currentUserId', name: _logName);

    try {
      // ===== ステップ1: ブロック関係を取得 =====
      logger.start('ブロック関係を取得中...', name: _logName);

      final blockedByMe = await blockRepository.findBlockedUsers(currentUserId);
      final blockedMe = await blockRepository.findBlockedBy(currentUserId);

      final blockedUserIds = <String>{
        ...blockedByMe.map((b) => b.blockedId),
        ...blockedMe.map((b) => b.blockerId),
      };

      logger.success('ブロック関係取得: ${blockedUserIds.length}人', name: _logName);
      if (blockedUserIds.isNotEmpty) {
        logger.debug('ブロックユーザー: ${blockedUserIds.join(", ")}', name: _logName);
      }

      // ===== ステップ2: 全ルームを取得 =====
      logger.start('全ルーム取得中...', name: _logName);
      final allRooms = await _roomRepository.findAll();
      logger.success('全ルーム数: ${allRooms.length}件', name: _logName);

      // ===== ステップ3: フィルタリング =====
      logger.start('フィルタリング中...', name: _logName);

      final now = DateTime.now();
      final filteredRooms = allRooms.where((room) {
        // 3-1. topic名で部分一致検索（大文字小文字区別なし）
        final topicLower = room.topic.toLowerCase();
        final queryLower = searchQuery.toLowerCase();
        if (!topicLower.contains(queryLower)) {
          return false;
        }

        // 3-2. プライベートルームは検索結果から除外 ✅ 追加
        if (room.private) {
          logger.debug('除外: プライベートルーム - ${room.topic}', name: _logName);
          return false;
        }

        // 3-3. 参加待ち状態でないルームは除外
        if (!room.isWaiting) {
          logger.debug('除外: 参加待ちでない - ${room.topic}', name: _logName);
          return false;
        }

        // 3-4. アクティブなルームで期限切れの場合は除外
        if (room.isActive && now.isAfter(room.expiresAt)) {
          logger.debug('除外: 期限切れ - ${room.topic}', name: _logName);
          return false;
        }

        // 3-5. ブロック関係チェック
        final creatorId = room.id1;
        if (creatorId != null && blockedUserIds.contains(creatorId)) {
          logger.debug('除外: ブロック関係 - ${room.topic} (作成者: $creatorId)',
              name: _logName);
          return false;
        }

        return true;
      }).toList();

      // ===== ステップ4: 作成日時でソート（新しい順） =====
      filteredRooms.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      logger.success('検索完了: ${filteredRooms.length}件', name: _logName);
      logger.section('searchRooms() 終了', name: _logName);

      return filteredRooms;
    } catch (e, stack) {
      logger.error('searchRooms() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 参加可能なルーム一覧を取得（フィルタリング済み）
  ///
  /// [currentUserId] 現在のユーザーID
  /// [blockRepository] BlockRepositoryインスタンス
  ///
  /// 戻り値: 参加可能なルームリスト
  ///
  /// 処理内容:
  /// - 待機中のルームのみ
  /// - 期限切れでない
  /// - ブロック関係のないユーザー
  /// - 自分が作成したルームを除外
  Future<List<ChatRoom>> getJoinableRooms({
    required String currentUserId,
    required dynamic blockRepository,
  }) async {
    logger.section('getJoinableRooms() 開始', name: _logName);
    logger.info('currentUserId: $currentUserId', name: _logName);

    try {
      // ブロック関係を取得
      logger.start('ブロック関係を取得中...', name: _logName);

      final blockedByMe = await blockRepository.findBlockedUsers(currentUserId);
      final blockedMe = await blockRepository.findBlockedBy(currentUserId);

      final blockedUserIds = <String>{
        ...blockedByMe.map((b) => b.blockedId),
        ...blockedMe.map((b) => b.blockerId),
      };

      logger.success('ブロック関係取得: ${blockedUserIds.length}人', name: _logName);

      // Repository経由で参加可能なルームを取得
      logger.start('参加可能なルーム取得中...', name: _logName);
      final rooms = await _roomRepository.findJoinableRooms(
        excludeUserId: currentUserId,
      );

      logger.success('初期取得: ${rooms.length}件', name: _logName);

      // ブロック関係 + プライベートルームでフィルタリング ✅ 修正
      final filteredRooms = rooms.where((room) {
        // プライベートルームは検索結果から除外
        if (room.private) {
          logger.debug('除外: プライベートルーム - ${room.topic}', name: _logName);
          return false;
        }

        final creatorId = room.id1;
        if (creatorId != null && blockedUserIds.contains(creatorId)) {
          logger.debug('除外: ブロック関係 - ${room.topic}', name: _logName);
          return false;
        }
        return true;
      }).toList();

      // 作成日時でソート（新しい順）
      filteredRooms.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      logger.success('参加可能なルーム: ${filteredRooms.length}件', name: _logName);
      logger.section('getJoinableRooms() 終了', name: _logName);

      return filteredRooms;
    } catch (e, stack) {
      logger.error('getJoinableRooms() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ルーム参加処理（統合版）
  ///
  /// [roomId] 参加先ルームID
  /// [currentUserId] 現在のユーザーID
  /// [userRepository] UserRepositoryインスタンス
  ///
  /// 戻り値: 更新されたルーム
  ///
  /// 処理内容:
  /// 1. Repository経由でルームに参加
  /// 2. ユーザーのルーム参加回数を更新
  /// 3. タイマーを開始
  Future<ChatRoom> joinRoomWithUserUpdate({
    required String roomId,
    required String currentUserId,
    required dynamic userRepository, // UserRepository型
  }) async {
    logger.section('joinRoomWithUserUpdate() 開始', name: _logName);
    logger.info('roomId: $roomId', name: _logName);
    logger.info('userId: $currentUserId', name: _logName);

    try {
      // ===== 1. ルームに参加 =====
      logger.start('Repository経由でルーム参加中...', name: _logName);
      await _roomRepository.joinRoom(roomId, currentUserId);
      logger.success('ルーム参加成功', name: _logName);

      // ===== 2. 更新されたルームを取得 =====
      final updatedRoom = await _roomRepository.findById(roomId);
      if (updatedRoom == null) {
        throw Exception('ルームが見つかりません');
      }

      // StorageServiceも更新
      final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _storageService.rooms[roomIndex] = updatedRoom;
        await _storageService.save();
      }

      // ===== 3. ユーザーのルーム参加回数を更新 =====
      try {
        logger.start('ルーム参加回数更新中...', name: _logName);
        await userRepository.incrementRoomCount(currentUserId);
        logger.success('ルーム参加回数更新完了', name: _logName);
      } catch (e) {
        logger.warning('ルーム参加回数更新失敗: $e', name: _logName);
        // 参加回数更新失敗は致命的エラーではないため続行
      }

      // ===== 4. タイマーを開始 =====
      logger.start('ルームタイマー開始中...', name: _logName);
      startRoomTimer(roomId, updatedRoom.expiresAt);
      logger.success('ルームタイマー開始完了', name: _logName);

      logger.section('joinRoomWithUserUpdate() 完了', name: _logName);

      return updatedRoom;
    } catch (e, stack) {
      logger.error('joinRoomWithUserUpdate() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  // ===== ルーム作成 =====

  /// ルームを作成
  Future<ChatRoom> createRoom(String roomName, String currentUserId) async {
    logger.section('createRoom() 開始', name: _logName);
    logger.info('ルーム名: $roomName', name: _logName);
    logger.info('作成者: $currentUserId', name: _logName);

    // バリデーション
    if (roomName.isEmpty) {
      logger.error('ルーム名が空です', name: _logName);
      throw Exception('ルーム名を入力してください');
    }

    if (roomName.length > AppConstants.roomNameMaxLength) {
      logger.error('ルーム名が長すぎます: ${roomName.length}文字', name: _logName);
      throw Exception('ルーム名は${AppConstants.roomNameMaxLength}文字以内で入力してください');
    }

    final roomId = DateTime.now().millisecondsSinceEpoch.toString();

    // 遠い未来の日時（1年後）
    final farFuture = DateTime.now().add(const Duration(days: 365));

    final newRoom = ChatRoom(
      id: roomId,
      topic: roomName,
      status: AppConstants.roomStatusWaiting,
      id1: currentUserId,
      id2: null,
      startedAt: farFuture,
      expiresAt: farFuture,
      extensionCount: 0,
      extension: AppConstants.defaultExtensionLimit,
      comment1: '',
      comment2: '',
    );

    // Repository経由でFirestoreに保存
    await _roomRepository.create(newRoom, id: roomId);

    logger.success('ルーム作成完了: $roomId', name: _logName);
    logger.info('ルーム情報: $newRoom', name: _logName);
    logger.section('createRoom() 終了', name: _logName);

    return newRoom;
  }

  // ===== ルーム参加 =====

  /// ルームに参加
  Future<ChatRoom?> joinRoom(String roomId, String currentUserId) async {
    logger.section('joinRoom() 開始', name: _logName);
    logger.info('roomId: $roomId', name: _logName);
    logger.info('userId: $currentUserId', name: _logName);

    // Repository経由でルーム取得
    final room = await _roomRepository.findById(roomId);

    if (room == null) {
      logger.error('ルームが見つかりません: $roomId', name: _logName);
      throw Exception('ルームが見つかりません');
    }

    final now = DateTime.now();
    final expiresAt =
        now.add(Duration(minutes: AppConstants.defaultChatDurationMinutes));

    ChatRoom updatedRoom;

    if (room.id2?.isEmpty ?? true) {
      updatedRoom = room.copyWith(
        id2: currentUserId,
        status: AppConstants.roomStatusActive,
        startedAt: now,
        expiresAt: expiresAt,
      );

      logger.success('2人目が参加 → チャット開始', name: _logName);
      logger.info('  startedAt: $now', name: _logName);
      logger.info('  expiresAt: $expiresAt', name: _logName);

      await _roomRepository.update(roomId, updatedRoom);

      final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _storageService.rooms[roomIndex] = updatedRoom;
        await _storageService.save();
      }

      startRoomTimer(roomId, expiresAt);

      logger.section('joinRoom() 正常終了', name: _logName);
      return updatedRoom;
    } else if (room.id1?.isEmpty ?? true) {
      updatedRoom = room.copyWith(
        id1: currentUserId,
        status: AppConstants.roomStatusActive,
        startedAt: now,
        expiresAt: expiresAt,
      );

      logger.success('id1スロットに参加 → チャット開始', name: _logName);

      await _roomRepository.update(roomId, updatedRoom);

      final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _storageService.rooms[roomIndex] = updatedRoom;
        await _storageService.save();
      }

      startRoomTimer(roomId, expiresAt);

      logger.section('joinRoom() 正常終了', name: _logName);
      return updatedRoom;
    }

    logger.error('ルームは満員です', name: _logName);
    throw Exception('ルームは満員です');
  }

  // ===== ルーム退出 =====

  /// ルームから退出
  Future<void> leaveRoom(String roomId, String currentUserId) async {
    logger.section('leaveRoom() 開始', name: _logName);
    logger.info('roomId: $roomId, userId: $currentUserId', name: _logName);

    final room = await _roomRepository.findById(roomId);
    if (room == null) {
      logger.warning('ルームが見つかりません: $roomId', name: _logName);
      return;
    }

    ChatRoom updatedRoom;

    if (room.id1 == currentUserId) {
      updatedRoom = room.copyWith(id1: '');
      logger.info('id1から退出', name: _logName);
    } else if (room.id2 == currentUserId) {
      updatedRoom = room.copyWith(id2: '');
      logger.info('id2から退出', name: _logName);
    } else {
      logger.warning('このユーザーはルームのメンバーではありません', name: _logName);
      return;
    }

    // 両方が退出した場合はルームを削除
    if ((updatedRoom.id1?.isEmpty ?? true) &&
        (updatedRoom.id2?.isEmpty ?? true)) {
      logger.info('全員退出 → ルーム削除', name: _logName);
      await deleteRoom(roomId);
    } else {
      await _roomRepository.update(roomId, updatedRoom);

      final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _storageService.rooms[roomIndex] = updatedRoom;
        await _storageService.save();
      }

      logger.success('退出完了', name: _logName);
    }

    logger.section('leaveRoom() 終了', name: _logName);
  }

  // ===== ルーム削除 =====

  /// ルームを削除
  Future<void> deleteRoom(String roomId) async {
    logger.section('deleteRoom() 開始 - roomId: $roomId', name: _logName);

    _roomTimers[roomId]?.cancel();
    _roomTimers.remove(roomId);
    _extensionPollingTimers[roomId]?.cancel();
    _extensionPollingTimers.remove(roomId);

    await _roomRepository.delete(roomId);

    _storageService.rooms.removeWhere((r) => r.id == roomId);
    _storageService.extensionRequests.removeWhere((e) => e.roomId == roomId);
    await _storageService.save();

    logger.success('ルーム削除完了', name: _logName);
    logger.section('deleteRoom() 終了', name: _logName);
  }

  // ===== タイマー管理 =====

  /// ルームタイマーを開始
  void startRoomTimer(String roomId, DateTime expiresAt) {
    logger.debug('startRoomTimer() - roomId: $roomId', name: _logName);
    _roomTimers[roomId]?.cancel();

    final now = DateTime.now();
    final duration = expiresAt.difference(now);

    if (duration.isNegative) {
      logger.warning('既に期限切れのため削除します', name: _logName);
      logger.info('  現在時刻: $now', name: _logName);
      logger.info('  期限時刻: $expiresAt', name: _logName);
      deleteRoom(roomId);
      return;
    }

    logger.info('タイマー設定: ${duration.inMinutes}分${duration.inSeconds % 60}秒',
        name: _logName);
    logger.info('  期限時刻: $expiresAt', name: _logName);

    _roomTimers[roomId] = Timer(duration, () async {
      logger.warning('ルームタイマー期限切れ - 削除: $roomId', name: _logName);
      await deleteRoom(roomId);
    });
  }

  // ===== コメント送信 =====

  /// コメントを送信
  Future<void> sendComment(String roomId, String userId, String text) async {
    logger.debug('sendComment() 開始', name: _logName);
    logger.debug('  roomId: $roomId', name: _logName);
    logger.debug('  userId: $userId', name: _logName);
    logger.debug('  text length: ${text.length}', name: _logName);

    if (text.isEmpty || text.length > AppConstants.messageMaxLength) {
      logger.error('メッセージ長が不正: ${text.length}文字', name: _logName);
      throw Exception('メッセージは1〜${AppConstants.messageMaxLength}文字で入力してください');
    }

    final room = await _roomRepository.findById(roomId);
    if (room == null) {
      logger.error('ルームが見つかりません: $roomId', name: _logName);
      throw Exception('ルームが見つかりません');
    }

    ChatRoom updatedRoom;

    if (room.id1 == userId) {
      updatedRoom = room.copyWith(comment1: text);
      logger.debug('  → comment1 を更新', name: _logName);
    } else if (room.id2 == userId) {
      updatedRoom = room.copyWith(comment2: text);
      logger.debug('  → comment2 を更新', name: _logName);
    } else {
      logger.error('このルームのメンバーではありません', name: _logName);
      throw Exception('このルームのメンバーではありません');
    }

    await _roomRepository.update(roomId, updatedRoom);

    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
    }

    logger.debug('sendComment() 完了', name: _logName);
  }

  // ===== コメント取得 =====

  /// ルームのコメントを取得
  Map<String, String> getRoomComments(String roomId) {
    final room = _storageService.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => ChatRoom(
        id: '',
        topic: '',
        id1: '',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now(),
      ),
    );

    if (room.id.isEmpty) return {};

    return {
      if (room.id1 != null && room.id1!.isNotEmpty)
        room.id1!: room.comment1 ?? '',
      if (room.id2 != null && room.id2!.isNotEmpty)
        room.id2!: room.comment2 ?? '',
    };
  }

  // ===== 延長リクエスト =====

  /// 延長リクエストを送信
  Future<ExtensionRequest> requestExtension(
      String roomId, String requesterId) async {
    logger.section('requestExtension() 開始', name: _logName);
    logger.info('roomId: $roomId, requesterId: $requesterId', name: _logName);

    final room = await _roomRepository.findById(roomId);
    if (room == null) {
      logger.error('ルームが見つかりません', name: _logName);
      throw Exception('ルームが見つかりません');
    }

    if (room.extensionCount >= room.extension) {
      logger.error('延長回数の上限に達しました', name: _logName);
      throw Exception('延長回数の上限に達しました');
    }

    final existingRequest = _storageService.extensionRequests.firstWhere(
      (e) =>
          e.roomId == roomId && e.status == AppConstants.extensionStatusPending,
      orElse: () => ExtensionRequest(
        id: '',
        roomId: '',
        requesterId: '',
        status: '',
        createdAt: DateTime.now(),
      ),
    );

    if (existingRequest.id.isNotEmpty) {
      logger.error('延長リクエストが既に存在します', name: _logName);
      throw Exception('延長リクエストが既に存在します');
    }

    final request = ExtensionRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      requesterId: requesterId,
      status: AppConstants.extensionStatusPending,
      createdAt: DateTime.now(),
    );

    _storageService.extensionRequests.add(request);
    await _storageService.save();

    logger.success('延長リクエスト送信完了: ${request.id}', name: _logName);
    logger.section('requestExtension() 終了', name: _logName);

    return request;
  }

  /// 延長リクエストを承認
  Future<void> approveExtension(String requestId) async {
    logger.section('approveExtension() 開始', name: _logName);
    logger.info('requestId: $requestId', name: _logName);

    final requestIndex = _storageService.extensionRequests.indexWhere(
      (e) => e.id == requestId,
    );

    if (requestIndex == -1) {
      logger.error('延長リクエストが見つかりません', name: _logName);
      throw Exception('延長リクエストが見つかりません');
    }

    final request = _storageService.extensionRequests[requestIndex];

    final room = await _roomRepository.findById(request.roomId);
    if (room == null) {
      logger.error('ルームが見つかりません', name: _logName);
      throw Exception('ルームが見つかりません');
    }

    // 延長後の有効期限を計算
    final newExpiresAt = room.expiresAt
        .add(Duration(minutes: AppConstants.extensionDurationMinutes));

    final updatedRoom = room.copyWith(
      expiresAt: newExpiresAt,
      extensionCount: room.extensionCount + 1,
    );

    await _roomRepository.update(room.id, updatedRoom);

    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      _storageService.rooms[roomIndex] = updatedRoom;
    }

    _storageService.extensionRequests[requestIndex] = request.copyWith(
      status: AppConstants.extensionStatusApproved,
    );

    await _storageService.save();

    startRoomTimer(room.id, newExpiresAt);

    logger.success('延長承認完了: 新期限=$newExpiresAt', name: _logName);
    logger.section('approveExtension() 終了', name: _logName);
  }

  /// 延長リクエストを拒否
  Future<void> rejectExtension(String requestId) async {
    logger.section('rejectExtension() 開始', name: _logName);
    logger.info('requestId: $requestId', name: _logName);

    final requestIndex = _storageService.extensionRequests.indexWhere(
      (e) => e.id == requestId,
    );

    if (requestIndex == -1) {
      logger.error('延長リクエストが見つかりません', name: _logName);
      throw Exception('延長リクエストが見つかりません');
    }

    final request = _storageService.extensionRequests[requestIndex];
    _storageService.extensionRequests[requestIndex] = request.copyWith(
      status: AppConstants.extensionStatusRejected,
    );

    await _storageService.save();

    logger.success('延長拒否完了', name: _logName);
    logger.section('rejectExtension() 終了', name: _logName);
  }

  // ===== クリーンアップ =====

  /// サービスを破棄
  void dispose() {
    logger.info('dispose() - 全タイマーをキャンセル', name: _logName);

    for (var timer in _roomTimers.values) {
      timer.cancel();
    }
    _roomTimers.clear();

    for (var timer in _extensionPollingTimers.values) {
      timer.cancel();
    }
    _extensionPollingTimers.clear();

    logger.success('dispose() 完了', name: _logName);
  }
}
