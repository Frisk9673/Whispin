import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
// import '../models/message.dart'; ← 削除
import '../models/friendship.dart';
import '../models/friend_request.dart';
import '../models/user_evaluation.dart';
import '../models/extension_request.dart';
import '../models/block.dart';
import '../models/local_auth_user.dart';

/// データ永続化のための抽象インターフェース
abstract class StorageService {
  /// サービスの初期化
  Future<void> initialize();
  
  /// データの読み込み
  Future<void> load();
  
  /// データの保存
  Future<void> save();
  
  /// ユーザー一覧
  List<User> get users;
  set users(List<User> value);
  
  /// チャットルーム一覧
  List<ChatRoom> get rooms;
  set rooms(List<ChatRoom> value);
  
  // /// メッセージ一覧 ← 削除
  // List<Message> get messages;
  // set messages(List<Message> value);
  
  /// ローカル認証ユーザー一覧（localStorage mode only）
  List<LocalAuthUser> get authUsers;
  set authUsers(List<LocalAuthUser> value);
  
  /// フレンドシップ一覧
  List<Friendship> get friendships;
  set friendships(List<Friendship> value);
  
  /// フレンドリクエスト一覧
  List<FriendRequest> get friendRequests;
  set friendRequests(List<FriendRequest> value);
  
  /// ユーザー評価一覧
  List<UserEvaluation> get evaluations;
  set evaluations(List<UserEvaluation> value);
  
  /// 延長リクエスト一覧
  List<ExtensionRequest> get extensionRequests;
  set extensionRequests(List<ExtensionRequest> value);
  
  /// ブロック一覧
  List<Block> get blocks;
  set blocks(List<Block> value);
  
  /// 現在ログイン中のユーザー
  User? get currentUser;
  set currentUser(User? value);
  
  /// データベースのクリア
  Future<void> clear();
}