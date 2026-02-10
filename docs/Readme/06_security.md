# 🛡️ 06 — セキュリティ

## 実装済みセキュリティ対策

| 対策 | 詳細 |
|---|---|
| パスワードハッシュ化 | PBKDF2（10,000回イテレーション） |
| タイミング攻撃対策 | 定数時間比較アルゴリズム |
| 論理削除 | `deletedAt` フィールドで管理 |
| ブロック機能 | ブロックユーザーとはルーム参加不可 |
| 管理者認証 | Firestoreの `administrator` コレクションで権限確認 |
| 入力バリデーション | フォーム入力の徹底的な検証 |
| カスタム例外 | `ValidationException` / `NetworkException` / `DatabaseException` |

---

## Firestore Securityルール（例）

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read:  if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    match /rooms/{roomId} {
      allow read:   if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (resource.data.id1 == request.auth.token.email ||
         resource.data.id2 == request.auth.token.email);
    }

    match /friendRequests/{requestId} {
      allow read: if request.auth != null &&
        (resource.data.senderId   == request.auth.token.email ||
         resource.data.receiverId == request.auth.token.email);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
         resource.data.receiverId == request.auth.token.email;
    }

    match /invitations/{invitationId} {
      allow read: if request.auth != null &&
        (resource.data.inviterId == request.auth.token.email ||
         resource.data.inviteeId == request.auth.token.email);
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
         resource.data.inviteeId == request.auth.token.email;
    }
  }
}
```

---

## プライバシーとデータ保護

- **論理削除**: `deletedAt` フィールドで削除管理（物理削除なし）
- **個人情報の最小化**: 必要最小限の情報のみ収集
- **通信の暗号化**: FirestoreはすべてSSL/TLSで暗号化
- **GDPR準拠**: ユーザーが自身のデータを削除可能