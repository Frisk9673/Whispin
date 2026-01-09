# 拡張メソッド活用リファクタリング - チェックリスト

## 対象拡張メソッド
1. ✅ ContextExtensions (context_extensions.dart)
2. ✅ DateTimeExtensions (datetime_extensions.dart)
3. ✅ StringExtensions (string_extensions.dart)

---

## 📋 変更対象ファイル一覧

### 🔴 優先度: 高（多数の改善箇所）

- [ ] 1. `lib/screens/user/chat_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - ダイアログ表示 → context拡張メソッド
  - 時間フォーマット → DateTime拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 2. `lib/screens/user/profile.dart`
  - SnackBar表示 → context拡張メソッド
  - ダイアログ表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 3. `lib/screens/user/home_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - ダイアログ表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 4. `lib/screens/user/room_create_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 5. `lib/screens/user/room_join_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 6. `lib/screens/user/create_room_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 7. `lib/screens/user/auth_screen.dart`
  - バリデーション → String拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 8. `lib/screens/login/user_login_page.dart`
  - SnackBar表示 → context拡張メソッド
  - バリデーション → String拡張メソッド

- [ ] 9. `lib/screens/account_create/account_create_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - バリデーション → String拡張メソッド

### 🟡 優先度: 中（中程度の改善箇所）

- [ ] 10. `lib/screens/user/question_chat_user.dart`
  - 時間フォーマット → DateTime拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 11. `lib/screens/user/friend_list_screen.dart`
  - SnackBar表示 → context拡張メソッド

- [ ] 12. `lib/screens/user/block_list_screen.dart`
  - SnackBar表示 → context拡張メソッド

- [ ] 13. `lib/screens/admin/admin_login_screen.dart`
  - SnackBar表示 → context拡張メソッド
  - MediaQuery → context拡張メソッド

- [ ] 14. `lib/screens/admin/premium_log_list_screen.dart`
  - MediaQuery → context拡張メソッド

### 🟢 優先度: 低（少数の改善箇所）

- [ ] 15. `lib/widgets/evaluation_dialog.dart`
  - MediaQuery → context拡張メソッド

- [ ] 16. `lib/services/auth_service.dart`
  - バリデーション → String拡張メソッド

- [ ] 17. `lib/services/chat_service.dart`
  - 日時計算 → DateTime拡張メソッド

---

## 📊 改善内容の内訳

### ContextExtensions の活用
```dart
// SnackBar表示
ScaffoldMessenger.of(context).showSnackBar(...) 
→ context.showSuccessSnackBar(...)
→ context.showErrorSnackBar(...)
→ context.showWarningSnackBar(...)

// ダイアログ表示
showDialog(context: context, ...) 
→ context.showCustomDialog(...)
→ context.showConfirmDialog(...)
→ context.showLoadingDialog(...)

// MediaQuery
MediaQuery.of(context).size.width 
→ context.screenWidth
MediaQuery.of(context).size.width < 768 
→ context.isMobile
```

### DateTimeExtensions の活用
```dart
// 時間フォーマット
DateFormat('yyyy-MM-dd HH:mm').format(dateTime) 
→ dateTime.toDateTimeString

// 相対時間
複雑な計算ロジック 
→ dateTime.toRelativeTime

// チャット用時間表示
カスタムロジック 
→ dateTime.toChatTime
```

### StringExtensions の活用
```dart
// メールバリデーション
!email.contains('@') 
→ !email.isValidEmail

// 空文字チェック
text.trim().isEmpty 
→ text.isBlank

// 空でないチェック
text.trim().isNotEmpty 
→ text.isNotBlank
```

---

## 🎯 進行方法

1. チェックリストの上から順に1ファイルずつ処理
2. 各ファイルで以下を実施:
   - 該当箇所の特定
   - Before/After コードの確認
   - リファクタリング実行
   - 動作確認

3. 完了したファイルに ✅ マーク

---

## 📝 注意事項

- **インポートの追加を忘れない**
  ```dart
  import '../../extensions/context_extensions.dart';
  import '../../extensions/datetime_extensions.dart';
  import '../../extensions/string_extensions.dart';
  ```

- **既存の動作を変更しない**
  - 同等の機能を提供する拡張メソッドを使用
  - ロジックの変更は最小限に

- **可読性を優先**
  - 拡張メソッドで読みやすくなる場合のみ適用
  - 過度な置き換えは避ける

---

## 📈 進捗状況

- **総ファイル数**: 17
- **完了**: 0
- **残り**: 17
- **進捗率**: 0%

---

準備完了！ファイル #1 から始めましょう 🚀