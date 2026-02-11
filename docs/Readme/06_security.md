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

> **ラベル: サンプル（現在適用中ルールではありません）**
>
> 以下は設計意図を共有するためのサンプルです。`firebase.json` では Firestore のルールファイル参照は定義されていないため、実際の適用状態は Firebase コンソールまたはデプロイ手順側で別途確認してください。

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

## Firebaseルールファイルの実適用状況（`firebase.json`）

- **Realtime Database**: `database.rules.json`
- **Storage**: `storage.rules`
- **Firestore**: `firebase.json` 上の参照定義なし（このドキュメントのFirestoreルールはサンプル）

### `database.rules.json` に関する注意

現在の `database.rules.json` は次の通り、`".read": true` / `".write": true` の**全許可設定**です。

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

> ⚠️ **開発用途限定**: この設定はローカル検証や初期開発向けです。本番環境では必ず認証・認可を伴うルールへ変更してください（本番利用不可）。

---

## プライバシーとデータ保護

- **論理削除**: `deletedAt` フィールドで削除管理（物理削除なし）
- **個人情報の最小化**: 必要最小限の情報のみ収集
- **通信の暗号化**: FirestoreはすべてSSL/TLSで暗号化
- **GDPR準拠**: ユーザーが自身のデータを削除可能
