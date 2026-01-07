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
    
    // 🔧 修正: startedAt を遠い未来にする（仮の日時）
    // 2人揃った時点で正式に設定される
    final farFuture = DateTime.now().add(const Duration(days: 365));
    
    final newRoom = ChatRoom(
      id: roomId,
      topic: roomName,
      status: AppConstants.roomStatusWaiting,
      id1: currentUserId,
      id2: null, // 参加者待ち
      startedAt: farFuture, // 🔧 仮の値（2人揃ったら更新）
      expiresAt: farFuture,  // 🔧 仮の値（2人揃ったら10分後に更新）
      extensionCount: 0,
      extension: AppConstants.defaultExtensionLimit,
      comment1: '',
      comment2: '',
    );
    
    // Repository経由でFirestoreに保存
    await _roomRepository.create(newRoom, id: roomId);
    
    // StorageServiceにも追加（互換性維持）
    _storageService.rooms.add(newRoom);
    await _storageService.save();

    logger.success('ルーム作成完了: $roomId', name: _logName);
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
    
    // 🔧 2人目が参加したらチャット開始
    final now = DateTime.now();
    final expiresAt = now.add(
      Duration(minutes: AppConstants.defaultChatDurationMinutes)
    );
    
    ChatRoom updatedRoom;
    
    if (room.id2?.isEmpty ?? true) {
      // id2 スロットが空いている場合
      updatedRoom = room.copyWith(
        id2: currentUserId,
        status: AppConstants.roomStatusActive,
        startedAt: now,
        expiresAt: expiresAt,
      );
      
      logger.success('2人目が参加 → チャット開始', name: _logName);
      logger.info('  startedAt: $now', name: _logName);
      logger.info('  expiresAt: $expiresAt', name: _logName);
      
      // Repository経由で更新
      await _roomRepository.update(roomId, updatedRoom);
      
      // StorageServiceも更新（互換性維持）
      final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
      if (roomIndex != -1) {
        _storageService.rooms[roomIndex] = updatedRoom;
        await _storageService.save();
      }
      
      startRoomTimer(roomId, expiresAt);
      
      logger.section('joinRoom() 正常終了', name: _logName);
      return updatedRoom;
      
    } else if (room.id1?.isEmpty ?? true) {
      // id1 スロットに参加
      updatedRoom = room.copyWith(
        id1: currentUserId,
        status: AppConstants.roomStatusActive,
        startedAt: now,
        expiresAt: expiresAt,
      );
      
      logger.success('id1スロットに参加 → チャット開始', name: _logName);
      
      // Repository経由で更新
      await _roomRepository.update(roomId, updatedRoom);
      
      // StorageServiceも更新
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
    
    // Repository経由でルーム取得
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
    if ((updatedRoom.id1?.isEmpty ?? true) && (updatedRoom.id2?.isEmpty ?? true)) {
      logger.info('全員退出 → ルーム削除', name: _logName);
      await deleteRoom(roomId);
    } else {
      // Repository経由で更新
      await _roomRepository.update(roomId, updatedRoom);
      
      // StorageServiceも更新
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

    // タイマーをキャンセル
    _roomTimers[roomId]?.cancel();
    _roomTimers.remove(roomId);
    _extensionPollingTimers[roomId]?.cancel();
    _extensionPollingTimers.remove(roomId);
    
    // Repository経由で削除
    await _roomRepository.delete(roomId);
    
    // StorageServiceからも削除
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
    
    final duration = expiresAt.difference(DateTime.now());
    if (duration.isNegative) {
      logger.warning('既に期限切れのため削除します', name: _logName);
      deleteRoom(roomId);
      return;
    }

    logger.info('タイマー設定: ${duration.inMinutes}分${duration.inSeconds % 60}秒', name: _logName);
    
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
    
    // バリデーション
    if (text.isEmpty || text.length > AppConstants.messageMaxLength) {
      logger.error('メッセージ長が不正: ${text.length}文字', name: _logName);
      throw Exception('メッセージは1〜${AppConstants.messageMaxLength}文字で入力してください');
    }
    
    // Repository経由でルーム取得
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
    
    // Repository経由で更新
    await _roomRepository.update(roomId, updatedRoom);
    
    // StorageServiceも更新
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
  Future<ExtensionRequest> requestExtension(String roomId, String requesterId) async {
    logger.section('requestExtension() 開始', name: _logName);
    logger.info('roomId: $roomId, requesterId: $requesterId', name: _logName);
    
    // Repository経由でルーム取得
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
      (e) => e.roomId == roomId && e.status == AppConstants.extensionStatusPending,
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
    
    // Repository経由でルーム取得
    final room = await _roomRepository.findById(request.roomId);
    if (room == null) {
      logger.error('ルームが見つかりません', name: _logName);
      throw Exception('ルームが見つかりません');
    }
    
    final newExpiresAt = room.expiresAt.add(
      Duration(minutes: AppConstants.extensionDurationMinutes)
    );
    
    final updatedRoom = room.copyWith(
      expiresAt: newExpiresAt,
      extensionCount: room.extensionCount + 1,
    );
    
    // Repository経由で更新
    await _roomRepository.update(room.id, updatedRoom);
    
    // StorageServiceも更新
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