# AWS EC2 + Firebase Emulator 再起動手順書

本ドキュメントは **EC2 インスタンス再起動後** に、
**Whispin プロジェクト + Firebase Emulator Suite** を再度起動し、
Web / Android から利用可能な状態にするための手順をまとめたものです。

---

## 前提条件

- AWS Learner Lab を使用
- EC2: Amazon Linux 2023
- Firebase Emulator Suite を使用（本番DBは使用しない）
- プロジェクト: Whispin
- Firebase Emulator UI は **SSH ポートフォワード経由** でアクセス

---

## 1. EC2 インスタンスを起動

1. AWS コンソール → EC2
2. 対象インスタンスを **Start**
3. Public IPv4 address を確認

---

## 2. Windows から SSH 接続（ポートフォワード付き）

PowerShell を起動し、以下を実行：

```powershell
ssh -i Whispin-key.pem -L 4000:localhost:4000 ec2-user@<EC2のPublic IP>
```

### 注意
- SSH 接続は **切らないこと**
- このセッションが Emulator UI へのトンネルになります

---

## 3. EC2 上でプロジェクトディレクトリへ移動

```bash
cd ~/Whispin
```

存在しない場合は clone：

```bash
git clone https://github.com/Frisk9673/Whispin.git
cd Whispin
```

---

## 4. 必要ツール確認（初回のみ）

```bash
node -v
npm -v
java -version
firebase --version
```

- Node.js: v18 以上
- Java: **21 以上必須**
- firebase-tools: 最新

---

## 5. Firebase Emulator 起動

```bash
firebase emulators:start \
  --only auth,firestore \
  --import ./firebase-export-1763003772257isubkv \
  --export-on-exit ./firebase-export-1763003772257isubkv
```

### 正常時の表示例

```
✔ All emulators ready!
View Emulator UI at http://127.0.0.1:4000/
```

---

## 6. Emulator UI にアクセス（ローカルPC）

ブラウザで以下を開く：

```
http://localhost:4000
```

### 確認ポイント

- Authentication
- Firestore
- データが import されていること

---

## 7. Android / Web アプリからの接続

- Flutter / Android は Emulator 接続設定を使用
- 接続先は **EC2 ではなく Emulator**

（firebase.json に定義済み）

---

## 8. 終了手順（安全）

Emulator 停止：

```bash
Ctrl + C
```

- データは `firebase-export-*` に保存される

---

## よくあるトラブル

### Emulator UI にアクセスできない
- SSH ポートフォワードが張られているか確認
- URL は **localhost:4000**（EC2 IP ではない）

### Java エラー
- Java 21 未満は不可

```bash
sudo dnf install -y java-21-amazon-corretto
```

---

## 運用ポリシー

- 本構成は **開発・検証用途専用**
- 本番利用は禁止
- 再起動時は必ず本手順を実施

---

以上

