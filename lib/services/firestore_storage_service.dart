import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/friendship.dart';
import '../models/friend_request.dart';
import '../models/user_evaluation.dart';
import '../models/extension_request.dart';
import '../models/block.dart';
import '../models/local_auth_user.dart';

/// Firestore を使用したデータ永続化サービス
/// 
/// Firebase Cloud Firestore を使用してデータを保存・読み込みします。
/// リアルタイム更新をサポートし、複数デバイス間でのデータ同期が可能です。
class FirestoreStorageService implements StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // データストア
  List<User> _users = [];
  List<ChatRoom> _rooms = [];
  List<Message> _messages = [];
  List<LocalAuthUser> _authUsers = [];
  List<Friendship> _friendships = [];
  List<FriendRequest> _friendRequests = [];
  List<UserEvaluation> _evaluations = [];
  List<ExtensionRequest> _extensionRequests = [];
  List<Block> _blocks = [];
  User? _currentUser;
  
  // リアルタイム更新用のStreamSubscription
  StreamSubscription? _usersSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _friendshipsSubscription;
  StreamSubscription? _friendRequestsSubscription;
  StreamSubscription? _evaluationsSubscription;
  StreamSubscription? _extensionRequestsSubscription;
  StreamSubscription? _blocksSubscription;
  
  // 変更通知用（オプション）
  final _changeController = StreamController<void>.broadcast();
  Stream<void> get onChanged => _changeController.stream;
  
  @override
  List<User> get users => _users;
  
  @override
  set users(List<User> value) => _users = value;
  
  @override
  List<ChatRoom> get rooms => _rooms;
  
  @override
  set rooms(List<ChatRoom> value) => _rooms = value;
  
  @override
  List<Message> get messages => _messages;
  
  @override
  set messages(List<Message> value) => _messages = value;
  
  @override
  List<LocalAuthUser> get authUsers => _authUsers;
  
  @override
  set authUsers(List<LocalAuthUser> value) => _authUsers = value;
  
  @override
  List<Friendship> get friendships => _friendships;
  
  @override
  set friendships(List<Friendship> value) => _friendships = value;
  
  @override
  List<FriendRequest> get friendRequests => _friendRequests;
  
  @override
  set friendRequests(List<FriendRequest> value) => _friendRequests = value;
  
  @override
  List<UserEvaluation> get evaluations => _evaluations;
  
  @override
  set evaluations(List<UserEvaluation> value) => _evaluations = value;
  
  @override
  List<ExtensionRequest> get extensionRequests => _extensionRequests;
  
  @override
  set extensionRequests(List<ExtensionRequest> value) => _extensionRequests = value;
  
  @override
  List<Block> get blocks => _blocks;
  
  @override
  set blocks(List<Block> value) => _blocks = value;
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  set currentUser(User? value) {
    _currentUser = value;
    _saveCurrentUserId();
  }
  
  @override
  Future<void> initialize() async {
    print('📦 Initializing FirestoreStorageService...');
    
    // Firestoreエミュレータ接続（開発環境）
    if (kDebugMode) {
      try {
        _firestore.useFirestoreEmulator('localhost', 8080);
        print('🔧 Connected to Firestore Emulator');
      } catch (e) {
        print('⚠️  Firestore Emulator connection failed: $e');
      }
    }
    
    print('✅ FirestoreStorageService initialized');
  }
  
  @override
  Future<void> load() async {
    print('📥 Loading data from Firestore...');
    
    try {
      // ユーザー読み込み
      final usersSnapshot = await _firestore.collection('users').get();
      _users = usersSnapshot.docs
          .map((doc) => User.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_users.length} users');
      
      // チャットルーム読み込み
      final roomsSnapshot = await _firestore.collection('rooms').get();
      _rooms = roomsSnapshot.docs
          .map((doc) => ChatRoom.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_rooms.length} rooms');
      
      // メッセージ読み込み
      final messagesSnapshot = await _firestore.collection('messages').get();
      _messages = messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_messages.length} messages');
      
      // フレンドシップ読み込み
      final friendshipsSnapshot = await _firestore.collection('friendships').get();
      _friendships = friendshipsSnapshot.docs
          .map((doc) => Friendship.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_friendships.length} friendships');
      
      // フレンドリクエスト読み込み
      final friendRequestsSnapshot = await _firestore.collection('friendRequests').get();
      _friendRequests = friendRequestsSnapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_friendRequests.length} friend requests');
      
      // 評価読み込み
      final evaluationsSnapshot = await _firestore.collection('evaluations').get();
      _evaluations = evaluationsSnapshot.docs
          .map((doc) => UserEvaluation.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_evaluations.length} evaluations');
      
      // 延長リクエスト読み込み
      final extensionRequestsSnapshot = await _firestore.collection('extensionRequests').get();
      _extensionRequests = extensionRequestsSnapshot.docs
          .map((doc) => ExtensionRequest.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_extensionRequests.length} extension requests');
      
      // ブロック読み込み
      final blocksSnapshot = await _firestore.collection('blocks').get();
      _blocks = blocksSnapshot.docs
          .map((doc) => Block.fromMap(doc.data()))
          .toList();
      print('📥 Loaded ${_blocks.length} blocks');
      
      // 現在のユーザーID読み込み
      await _loadCurrentUserId();
      
      print('✅ Firestore data loaded successfully');
    } catch (e) {
      print('❌ Error loading from Firestore: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> save() async {
    print('💾 Saving data to Firestore...');
    print('   Data counts: Users: ${_users.length}, Rooms: ${_rooms.length}, Messages: ${_messages.length}, Friendships: ${_friendships.length}, Evaluations: ${_evaluations.length}, ExtensionRequests: ${_extensionRequests.length}, Blocks: ${_blocks.length}');
    
    try {
      final batch = _firestore.batch();
      
      // ユーザー保存
      for (var user in _users) {
        batch.set(
          _firestore.collection('users').doc(user.id),
          user.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // チャットルーム保存
      for (var room in _rooms) {
        batch.set(
          _firestore.collection('rooms').doc(room.id),
          room.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // メッセージ保存
      for (var message in _messages) {
        batch.set(
          _firestore.collection('messages').doc(message.id),
          message.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // フレンドシップ保存
      for (var friendship in _friendships) {
        batch.set(
          _firestore.collection('friendships').doc(friendship.id),
          friendship.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // フレンドリクエスト保存
      for (var request in _friendRequests) {
        batch.set(
          _firestore.collection('friendRequests').doc(request.id),
          request.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // 評価保存
      for (var evaluation in _evaluations) {
        batch.set(
          _firestore.collection('evaluations').doc(evaluation.id),
          evaluation.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // 延長リクエスト保存
      for (var request in _extensionRequests) {
        batch.set(
          _firestore.collection('extensionRequests').doc(request.id),
          request.toMap(),
          SetOptions(merge: true),
        );
      }
      
      // ブロック保存
      for (var block in _blocks) {
        batch.set(
          _firestore.collection('blocks').doc(block.id),
          block.toMap(),
          SetOptions(merge: true),
        );
      }
      
      await batch.commit();
      
      print('✅ Firestore save completed successfully');
      _changeController.add(null);
    } catch (e) {
      print('❌ Error saving to Firestore: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> clear() async {
    print('🗑️  Clearing all Firestore data...');
    
    try {
      final batch = _firestore.batch();
      
      // すべてのコレクションをクリア
      final collections = [
        'users',
        'rooms',
        'messages',
        'friendships',
        'friendRequests',
        'evaluations',
        'extensionRequests',
        'blocks',
      ];
      
      for (var collectionName in collections) {
        final snapshot = await _firestore.collection(collectionName).get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
      
      // ローカルデータもクリア
      _users.clear();
      _rooms.clear();
      _messages.clear();
      _friendships.clear();
      _friendRequests.clear();
      _evaluations.clear();
      _extensionRequests.clear();
      _blocks.clear();
      _currentUser = null;
      
      print('✅ All data cleared successfully');
      _changeController.add(null);
    } catch (e) {
      print('❌ Error clearing Firestore: $e');
      rethrow;
    }
  }
  
  /// リアルタイム更新のリスニングを開始
  void startListening() {
    print('👂 Starting real-time listeners...');
    
    // ユーザー変更監視
    _usersSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
      _users = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // チャットルーム変更監視
    _roomsSubscription = _firestore.collection('rooms').snapshots().listen((snapshot) {
      _rooms = snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // メッセージ変更監視
    _messagesSubscription = _firestore.collection('messages').snapshots().listen((snapshot) {
      _messages = snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // フレンドシップ変更監視
    _friendshipsSubscription = _firestore.collection('friendships').snapshots().listen((snapshot) {
      _friendships = snapshot.docs.map((doc) => Friendship.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // フレンドリクエスト変更監視
    _friendRequestsSubscription = _firestore.collection('friendRequests').snapshots().listen((snapshot) {
      _friendRequests = snapshot.docs.map((doc) => FriendRequest.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // 評価変更監視
    _evaluationsSubscription = _firestore.collection('evaluations').snapshots().listen((snapshot) {
      _evaluations = snapshot.docs.map((doc) => UserEvaluation.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // 延長リクエスト変更監視
    _extensionRequestsSubscription = _firestore.collection('extensionRequests').snapshots().listen((snapshot) {
      _extensionRequests = snapshot.docs.map((doc) => ExtensionRequest.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    // ブロック変更監視
    _blocksSubscription = _firestore.collection('blocks').snapshots().listen((snapshot) {
      _blocks = snapshot.docs.map((doc) => Block.fromMap(doc.data())).toList();
      _changeController.add(null);
    });
    
    print('✅ Real-time listeners started');
  }
  
  /// リスニングを停止
  void stopListening() {
    print('🛑 Stopping real-time listeners...');
    
    _usersSubscription?.cancel();
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _friendshipsSubscription?.cancel();
    _friendRequestsSubscription?.cancel();
    _evaluationsSubscription?.cancel();
    _extensionRequestsSubscription?.cancel();
    _blocksSubscription?.cancel();
    
    print('✅ Real-time listeners stopped');
  }
  
  /// 現在のユーザーIDを保存
  Future<void> _saveCurrentUserId() async {
    if (_currentUser != null) {
      await _firestore.collection('_system').doc('currentUser').set({
        'userId': _currentUser!.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('_system').doc('currentUser').delete();
    }
  }
  
  /// 現在のユーザーIDを読み込み
  Future<void> _loadCurrentUserId() async {
    try {
      final doc = await _firestore.collection('_system').doc('currentUser').get();
      if (doc.exists) {
        final userId = doc.data()?['userId'] as String?;
        if (userId != null) {
          _currentUser = _users.firstWhere(
            (user) => user.id == userId,
            orElse: () => User(id: userId),
          );
          print('✅ Restored current user: ${_currentUser!.displayName}');
        }
      }
    } catch (e) {
      print('⚠️  Could not load current user: $e');
    }
  }
  
  /// リソースのクリーンアップ
  void dispose() {
    stopListening();
    _changeController.close();
  }
}
