# 🔥 04 — Firebase構成

## 使用サービス

| サービス | 用途 |
|---|---|
| Firebase Authentication | ユーザー認証 |
| Cloud Firestore | NoSQLデータベース |
| Firebase Cloud Messaging | プッシュ通知 |
| Firebase Storage | プロフィール画像 |
| Firebase Emulator | ローカル開発環境 |

---

## 各サービスのルール適用ファイル

- **Realtime Database**: `database.rules.json`（`firebase.json` の `database.rules` で参照）
- **Firebase Storage**: `storage.rules`（`firebase.json` の `storage.rules` で参照）
- **Cloud Firestore**: `firebase.json` 上にルールファイル参照の記載なし

> 補足: Realtime Database の `database.rules.json` は現状 `".read": true` / `".write": true` の全許可設定のため、開発用途限定です。本番環境では利用しないでください。

---

## Firestoreコレクション一覧

### users — ユーザー
```
{userId}/
  id                 : string     (Email = Primary Key)
  password           : string     (ハッシュ済み)
  firstName          : string
  lastName           : string
  nickname           : string
  phoneNumber        : string?
  rate               : number     (評価スコア)
  premium            : boolean
  roomCount          : number
  createdAt          : timestamp
  lastUpdatedPremium : timestamp?
  deletedAt          : timestamp? (論理削除フラグ)
  fcmToken           : string?
  fcmTokenUpdatedAt  : timestamp?
  profileImageUrl    : string?
```

### rooms — チャットルーム
```
{roomId}/
  id             : string
  topic          : string
  status         : number  (0: 待機, 1: 会話中, 2: 終了)
  id1            : string  (作成者)
  id2            : string? (参加者)
  comment1       : string?
  comment2       : string?
  extensionCount : number
  extension      : number  (延長上限)
  startedAt      : timestamp
  expiresAt      : timestamp
  private        : boolean
```

### friendships — フレンドシップ
```
{friendshipId}/
  id        : string
  userId    : string
  friendId  : string
  active    : boolean
  createdAt : timestamp
```

### friendRequests — フレンドリクエスト
```
{requestId}/
  id          : string
  senderId    : string
  receiverId  : string
  status      : string  (pending / accepted / rejected)
  createdAt   : timestamp
  respondedAt : timestamp?
```

### blocks — ブロック
```
{blockId}/
  id        : string
  blockerId : string
  blockedId : string
  active    : boolean
  createdAt : timestamp
```

### invitations — ルーム招待
```
{invitationId}/
  id          : string
  roomId      : string
  inviterId   : string
  inviteeId   : string
  status      : string  (pending / accepted / rejected / expired)
  createdAt   : timestamp
  respondedAt : timestamp?
  expiresAt   : timestamp
```

### evaluations — ユーザー評価
```
{evaluationId}/
  id          : string
  evaluatorId : string
  evaluatedId : string
  rating      : string  (thumbs_up / thumbs_down)
  createdAt   : timestamp
```

### extensionRequests — 延長リクエスト
```
{requestId}/
  id          : string
  roomId      : string
  requesterId : string
  status      : string  (pending / approved / rejected)
  createdAt   : timestamp
```

### administrator — 管理者
```
{email}/
  Password  : string
  Role      : string
  LastLogin : timestamp?
```

### QuestionChat — お問い合わせ
```
{chatId}/
  UserID      : string
  AdminID     : string?
  LastMessage : string
  UpdatedAt   : timestamp
  Status      : string  (pending / in_progress / resolved)

  Messages/   ← サブコレクション
    {messageId}/
      ID        : string
      IsAdmin   : boolean
      Text      : string
      CreatedAt : timestamp
      Read      : boolean
```

### Log_Premium — プレミアムログ
```
{logId}/
  ID        : string    (Email)
  Timestamp : timestamp
  Detail    : string    (契約 / 解約)
```

### PremiumCounter — プレミアム会員数カウンター
```
counter/
  count       : number
  lastUpdated : timestamp
```
