# 1. Firebaseエミュレータを起動
firebase emulators:start

# 2. 別ターミナルでFlutterアプリを起動
flutter run -d chrome

# 3. 2つ目のユーザー用に別のブラウザプロファイルで起動
# Chromeの場合:
# - シークレットウィンドウを使用
# - または別のブラウザ（Firefox、Edgeなど）を使用

# デバッグモードで確認すべきコンソールログ:
# - "📦 Initializing FirestoreStorageService..."
# - "🚪 [ChatService] joinRoom 開始"
# - "✅ [ChatService] 2人目が参加 → チャット開始"
# - "💬 [ChatService] sendComment 開始"