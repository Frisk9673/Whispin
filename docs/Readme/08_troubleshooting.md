# 🔧 08 — トラブルシューティング

## Firebaseエミュレーターに接続できない

```bash
# エミュレーターが起動しているか確認
firebase emulators:start

# ポート使用確認
lsof -i :8080   # Firestore
lsof -i :9099   # Auth
```

`.env` の設定を確認してください。

```env
FIREBASE_MODE=emulator
EMULATOR_HOST=localhost
```

---

## ログイン後にユーザー情報が表示されない

`HomeScreen` の `didChangeDependencies()` でユーザー情報を読み込んでいるか確認してください。

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final userProvider = context.read<UserProvider>();

  if (userProvider.currentUser == null && !userProvider.isLoading) {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) userProvider.loadUserData(email);
  }
}
```

---

## 通知数が更新されない

```dart
final cacheService = context.read<NotificationCacheService>();

// 強制リフレッシュ
await cacheService.getCount(userId: currentUserId, forceRefresh: true);

// キャッシュ無効化
cacheService.invalidateCache();
```

---

## プライベートルームが検索結果に表示される

`ChatService.searchRooms()` のフィルタリングを確認してください。

```dart
if (room.private) {
  logger.debug('除外: プライベートルーム - ${room.topic}');
  return false;
}
```