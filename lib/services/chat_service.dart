import 'dart:async';
import '../models/chat_room.dart';
import '../models/extension_request.dart';
import 'storage_service.dart';

class ChatService {
  final StorageService _storageService;
  final Map<String, Timer> _roomTimers = {};
  final Map<String, Timer> _extensionPollingTimers = {};
  
  ChatService(this._storageService);
  
  Future<ChatRoom> createRoom(String roomName, String currentUserId) async {
    if (roomName.isEmpty) {
      throw Exception('ルーム名を入力してください');
    }
    
    if (roomName.length > 30) {
      throw Exception('ルーム名は30文字以内で入力してください');
    }
    
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 🔧 修正: startedAt を遠い未来にする(仮の日時を入れない)
    // 2人揃った時点で正式に設定される
    final farFuture = DateTime.now().add(Duration(days: 365)); // 仮の遠い未来
    
    final newRoom = ChatRoom(
      id: roomId,
      topic: roomName,
      status: 0, // 待機中
      id1: currentUserId,
      id2: null, // 参加者待ち
      startedAt: farFuture, // 🔧 仮の値(2人揃ったら更新)
      expiresAt: farFuture,  // 🔧 仮の値(2人揃ったら10分後に更新)
      extensionCount: 0,
      extension: 2,
      comment1: '',
      comment2: '',
    );
    
    _storageService.rooms.add(newRoom);
    await _storageService.save();
    
    // 🔧 タイマーは2人揃ってから開始するので、ここでは開始しない
    
    return newRoom;
  }
  
  Future<ChatRoom?> joinRoom(String roomId, String currentUserId) async {
    print('🚪 [ChatService] joinRoom 開始: roomId=$roomId, userId=$currentUserId');
    
    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }
    
    final room = _storageService.rooms[roomIndex];
    
    // 🔧 2人目が参加したらチャット開始
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: 10));
    
    ChatRoom updatedRoom;
    
    if (room.id2?.isEmpty ?? true) {
      // id2 スロットが空いている場合
      updatedRoom = room.copyWith(
        id2: currentUserId,
        status: 1,        // 🔧 会話中に変更
        startedAt: now,   // 🔧 チャット開始時刻を記録
        expiresAt: expiresAt, // 🔧 10分後に設定
      );
      
      print('✅ [ChatService] 2人目が参加 → チャット開始');
      print('   startedAt: $now');
      print('   expiresAt: $expiresAt');
      
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
      
      // 🔧 タイマー開始
      startRoomTimer(roomId, expiresAt);
      
      return updatedRoom;
    } else if (room.id1?.isEmpty ?? true) {
      // id1 スロットが空いている場合（まれなケース）
      updatedRoom = room.copyWith(
        id1: currentUserId,
        status: 1,
        startedAt: now,
        expiresAt: expiresAt,
      );
      
      print('✅ [ChatService] id1スロットに参加 → チャット開始');
      
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
      
      startRoomTimer(roomId, expiresAt);
      
      return updatedRoom;
    }
    
    throw Exception('ルームは満員です');
  }
  
  Future<void> leaveRoom(String roomId, String currentUserId) async {
    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;
    
    final room = _storageService.rooms[roomIndex];
    ChatRoom updatedRoom;
    
    if (room.id1 == currentUserId) {
      updatedRoom = room.copyWith(id1: '');
    } else if (room.id2 == currentUserId) {
      updatedRoom = room.copyWith(id2: '');
    } else {
      return;
    }
    
    if ((updatedRoom.id1?.isEmpty ?? true) && (updatedRoom.id2?.isEmpty ?? true)) {
      await deleteRoom(roomId);
    } else {
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
    }
  }
  
  Future<void> deleteRoom(String roomId) async {
    _roomTimers[roomId]?.cancel();
    _roomTimers.remove(roomId);
    _extensionPollingTimers[roomId]?.cancel();
    _extensionPollingTimers.remove(roomId);
    
    _storageService.rooms.removeWhere((r) => r.id == roomId);
    _storageService.extensionRequests.removeWhere((e) => e.roomId == roomId);
    
    await _storageService.save();
  }
  
  void startRoomTimer(String roomId, DateTime expiresAt) {
    _roomTimers[roomId]?.cancel();
    
    final duration = expiresAt.difference(DateTime.now());
    if (duration.isNegative) {
      deleteRoom(roomId);
      return;
    }
    
    _roomTimers[roomId] = Timer(duration, () async {
      await deleteRoom(roomId);
    });
  }
  
  /// コメントを送信（comment1 または comment2 を更新）
  /// 
  /// [roomId] ルームID
  /// [userId] ユーザーID
  /// [text] コメント内容（1〜100文字）
  Future<void> sendComment(String roomId, String userId, String text) async {
    print('💬 [ChatService] sendComment 開始');
    print('   roomId: $roomId');
    print('   userId: $userId');
    print('   text: $text');
    
    if (text.isEmpty || text.length > 100) {
      throw Exception('メッセージは1〜100文字で入力してください');
    }
    
    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }
    
    final room = _storageService.rooms[roomIndex];
    
    // ユーザーが id1 か id2 かを判定してコメントを更新
    ChatRoom updatedRoom;
    
    if (room.id1 == userId) {
      updatedRoom = room.copyWith(comment1: text);
      print('   → comment1 を更新');
    } else if (room.id2 == userId) {
      updatedRoom = room.copyWith(comment2: text);
      print('   → comment2 を更新');
    } else {
      throw Exception('このルームのメンバーではありません');
    }
    
    _storageService.rooms[roomIndex] = updatedRoom;
    await _storageService.save();
    
    print('✅ [ChatService] sendComment 完了');
  }
  
  /// 特定ルームのコメントを取得
  /// 
  /// 戻り値: {userId1: comment1, userId2: comment2}
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
  
  Future<ExtensionRequest> requestExtension(String roomId, String requesterId) async {
    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }
    
    final room = _storageService.rooms[roomIndex];
    if (room.extensionCount >= room.extension) {
      throw Exception('延長回数の上限に達しました');
    }
    
    final existingRequest = _storageService.extensionRequests.firstWhere(
      (e) => e.roomId == roomId && e.status == 'pending',
      orElse: () => ExtensionRequest(
        id: '',
        roomId: '',
        requesterId: '',
        status: '',
        createdAt: DateTime.now(),
      ),
    );
    
    if (existingRequest.id.isNotEmpty) {
      throw Exception('延長リクエストが既に存在します');
    }
    
    final request = ExtensionRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      requesterId: requesterId,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    
    _storageService.extensionRequests.add(request);
    await _storageService.save();
    
    return request;
  }
  
  Future<void> approveExtension(String requestId) async {
    final requestIndex = _storageService.extensionRequests.indexWhere(
      (e) => e.id == requestId,
    );
    
    if (requestIndex == -1) {
      throw Exception('延長リクエストが見つかりません');
    }
    
    final request = _storageService.extensionRequests[requestIndex];
    final roomIndex = _storageService.rooms.indexWhere(
      (r) => r.id == request.roomId,
    );
    
    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }
    
    final room = _storageService.rooms[roomIndex];
    final newExpiresAt = room.expiresAt.add(Duration(minutes: 5));
    final updatedRoom = room.copyWith(
      expiresAt: newExpiresAt,
      extensionCount: room.extensionCount + 1,
    );
    
    _storageService.rooms[roomIndex] = updatedRoom;
    _storageService.extensionRequests[requestIndex] = request.copyWith(
      status: 'approved',
    );
    
    await _storageService.save();
    
    startRoomTimer(room.id, newExpiresAt);
  }
  
  Future<void> rejectExtension(String requestId) async {
    final requestIndex = _storageService.extensionRequests.indexWhere(
      (e) => e.id == requestId,
    );
    
    if (requestIndex == -1) {
      throw Exception('延長リクエストが見つかりません');
    }
    
    final request = _storageService.extensionRequests[requestIndex];
    _storageService.extensionRequests[requestIndex] = request.copyWith(
      status: 'rejected',
    );
    
    await _storageService.save();
  }
  
  void dispose() {
    for (var timer in _roomTimers.values) {
      timer.cancel();
    }
    _roomTimers.clear();
    
    for (var timer in _extensionPollingTimers.values) {
      timer.cancel();
    }
    _extensionPollingTimers.clear();
  }
}