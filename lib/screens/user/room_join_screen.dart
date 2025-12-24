import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../models/chat_room.dart';

class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();

    if (roomId.isEmpty) {
      _showError('ルームIDを入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 現在のユーザーを取得
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError('ログインしてください');
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email;
      if (currentUserEmail == null) {
        _showError('ユーザー情報が取得できません');
        setState(() => _isLoading = false);
        return;
      }

      // Firestoreのrooms/{roomId}ドキュメントを取得
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();

      if (!roomDoc.exists) {
        _showError('ルームが見つかりません');
        setState(() => _isLoading = false);
        return;
      }

      // ChatRoomモデルを使用してデータを取得
      final ChatRoom room = ChatRoom.fromMap(roomDoc.data()!);

      // statusで状態チェック
      if (room.status == 2) {
        _showError('このルームは終了しています');
        setState(() => _isLoading = false);
        return;
      }

      if (room.status == 1) {
        // status=1（会話中）の場合、有効期限をチェック
        if (DateTime.now().isAfter(room.expiresAt)) {
          _showError('このルームは期限切れです');
          setState(() => _isLoading = false);
          return;
        }
      }

      // 既に参加しているかチェック
      if (room.id1 == currentUserEmail || room.id2 == currentUserEmail) {
        _showError('既にこのルームに参加しています');
        setState(() => _isLoading = false);
        return;
      }

      // 参加可能なスロットを確認（id1が作成者、id2が参加者）
      if (room.id2 != null && room.id2!.isNotEmpty) {
        // id2が既に埋まっている = 満員
        _showError('ルームは満員です（2人まで）');
        setState(() => _isLoading = false);
        return;
      }

      // 2人目の参加 → チャット開始
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 10)); // 10分後

      // id2（参加者スロット）に参加し、チャット開始時刻と期限を設定
      await _firestore.collection('rooms').doc(roomId).update({
        'id2': currentUserEmail,
        'status': 1, // 会話中に変更
        'createdAt': Timestamp.fromDate(now), // チャット開始時刻
        'expiresAt': Timestamp.fromDate(expiresAt), // 10分後
      });

      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ルーム "${room.topic}" に参加しました\nチャットが開始されました（10分間）'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // TODO: チャット画面に遷移
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => ChatScreen(roomId: roomId),
      //   ),
      // );

      // 仮で前の画面に戻る
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isLoading = false);
      _showError('参加に失敗しました: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CommonHeader(
              onProfilePressed: () {},
              onSettingsPressed: () {},
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        size: 80,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '部屋に参加',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: _roomIdController,
                          decoration: InputDecoration(
                            labelText: 'ルームID',
                            hintText: 'ルームIDを入力',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black87,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black87,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 400,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _joinRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '参加する',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.black87,
                      width: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 40,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}