# ⚙️ 05 — 主要機能の実装詳細

## 1. 認証システム

Firebase Authentication + Firestoreを組み合わせ、パスワードはPBKDF2でハッシュ化します。

```dart
// PBKDF2 (10,000回イテレーション) でパスワードをハッシュ化
final salt = PasswordHasher.generateSalt();
final passwordHash = PasswordHasher.hashPassword(password, salt);

// Firebase Authにユーザー作成
await _auth.createUserWithEmailAndPassword(email: user.id, password: password);

// Firestoreにハッシュ済みパスワードを保存
storageService.users.add(userWithHashedPassword);
await storageService.save();
```

---

## 2. パブリック / プライベートルーム

ルーム作成時に `private` フラグを設定します。

```dart
final newRoom = ChatRoom(
  id: roomId,
  topic: roomName,
  status: AppConstants.roomStatusWaiting,
  id1: currentUserEmail,
  private: _isPrivate, // ← true でプライベート
);
```

プライベートルームは検索結果から自動除外されます。

```dart
// chat_service.dart — searchRooms() 内
if (room.private) return false; // 検索から除外
```

---

## 3. フレンド招待機能

`InvitationService.showInviteFriendDialog()` がUIまで一括処理します。

```dart
await _invitationService.showInviteFriendDialog(
  context: context,
  roomId: widget.roomId,
  currentUserId: currentUserId,
);
```

---

## 4. 通知キャッシュシステム

**5分間キャッシュ + 自動リフレッシュ**でFirestoreクエリ回数を削減します。

```dart
class NotificationCacheService {
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<int> getCount({required String userId, bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid) return totalCount; // キャッシュを返す
    await _fetch(userId);     // キャッシュ切れなら再取得
    return totalCount;
  }

  void startAutoRefresh(String userId) {
    _autoRefreshTimer = Timer.periodic(_cacheDuration, (_) async {
      await _fetch(userId);
    });
  }
}
```

---

## 5. リアルタイムチャット・タイマー管理

`Timer` でルームの有効期限を管理します。

```dart
void startRoomTimer(String roomId, DateTime expiresAt) {
  _roomTimers[roomId]?.cancel();
  final duration = expiresAt.difference(DateTime.now());
  if (duration.isNegative) { deleteRoom(roomId); return; }

  _roomTimers[roomId] = Timer(duration, () async {
    await deleteRoom(roomId); // 時間切れで自動削除
  });
}
```

---

## 6. Repository Pattern

すべてのリポジトリは `BaseRepository<T>` を継承します。

```dart
abstract class BaseRepository<T> {
  String get collectionName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T model);

  Future<String> create(T model, {String? id});
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<void> update(String id, T model);
  Future<void> delete(String id);
  Stream<T?> watchById(String id);
  Stream<List<T>> watchAll();
}
```

---

## 7. レスポンシブデザイン

`context` 拡張メソッドで手軽に分岐できます。

```dart
// ブレークポイント
// Mobile  : < 600px
// Tablet  : 600px - 900px
// Desktop : ≥ 900px

if (context.isMobile) { /* モバイルレイアウト */ }
final fontSize = context.responsiveFontSize(16);
final padding  = context.responsivePadding;
```

---

## 8. ロギングシステム

`AppLogger` でコンソール・Dart DevTools・ファイルに同時出力します。

```dart
logger.section('処理開始', name: 'ServiceName');
logger.start('処理中...', name: 'ServiceName');
logger.success('成功',     name: 'ServiceName');
logger.error('失敗: $e',  name: 'ServiceName', error: e, stackTrace: stack);
```

> Web環境ではファイル出力をスキップし、print / developer.log のみ使用します。