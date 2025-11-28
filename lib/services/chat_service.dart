import 'dart:async';
import '../models/chat_room.dart';
import '../models/message.dart';
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
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: 10));
    
    final newRoom = ChatRoom(
      id: roomId,
      topic: roomName,
      id1: '',
      id2: currentUserId,
      createdAt: now,
      expiresAt: expiresAt,
      extensionCount: 0,
      extension: 2,
    );
    
    _storageService.rooms.add(newRoom);
    await _storageService.save();
    
    startRoomTimer(roomId, expiresAt);
    
    return newRoom;
  }
  
  Future<ChatRoom?> joinRoom(String roomId, String currentUserId) async {
    final roomIndex = _storageService.rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }
    
    final room = _storageService.rooms[roomIndex];
    
    if (room.id1?.isEmpty ?? true) {
      final updatedRoom = room.copyWith(id1: currentUserId);
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
      return updatedRoom;
    } else if (room.id2?.isEmpty ?? true) {
      final updatedRoom = room.copyWith(id2: currentUserId);
      _storageService.rooms[roomIndex] = updatedRoom;
      await _storageService.save();
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
    _storageService.messages.removeWhere((m) => m.roomId == roomId);
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
  
  Future<void> sendMessage(String roomId, String userId, String username, String text) async {
    if (text.isEmpty || text.length > 100) {
      throw Exception('メッセージは1〜100文字で入力してください');
    }
    
    final existingMessageIndex = _storageService.messages.indexWhere(
      (m) => m.roomId == roomId && m.userId == userId,
    );
    
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      userId: userId,
      username: username,
      text: text,
      timestamp: DateTime.now(),
    );
    
    if (existingMessageIndex != -1) {
      _storageService.messages[existingMessageIndex] = newMessage;
    } else {
      _storageService.messages.add(newMessage);
    }
    
    await _storageService.save();
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
