import '../../models/user/user.dart';
import '../../models/user/chat_room.dart';
import '../../models/user/friendship.dart';
import '../../models/user/friend_request.dart';
import '../../models/user/user_evaluation.dart';
import '../../models/user/extension_request.dart';
import '../../models/user/block.dart';
import '../../models/user/invitation.dart';

/// データ永続化のための抽象インターフェース
///
/// Firestore実装をサポートします。
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

  /// 招待一覧
  List<Invitation> get invitations;
  set invitations(List<Invitation> value);

  /// 現在ログイン中のユーザー
  User? get currentUser;
  set currentUser(User? value);

  /// データベースのクリア
  Future<void> clear();
}