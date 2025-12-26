import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../models/chat_room.dart';

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();

    if (roomName.isEmpty) {
      _showError('ルーム名を入力してください');
      return;
    }

    if (roomName.length > 30) {
      _showError('ルーム名は30文字以内で入力してください');
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

      // ルームIDを生成（タイムスタンプを使用）
      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // ChatRoomオブジェクトを作成
      // 作成時点では参加者が1人なので、createdAtとexpiresAtは仮の値
      // 2人目が参加した時点で正式に設定される
      final newRoom = ChatRoom(
        id: roomId,
        topic: roomName,
        status: 0, // 0=待機中（参加者待ち）
        id1: currentUserEmail, // 作成者
        id2: null, // 参加者は未定
        comment1: null,
        comment2: null,
        extensionCount: 0,
        extension: 2, // 延長上限2回
        startedAt: now, // 仮の作成日時（2人揃った時に更新）
        expiresAt: now.add(const Duration(hours: 24)), // 仮の期限（2人揃った時に10分後に更新）
      );

      // Firestoreに保存
      await _firestore.collection('rooms').doc(roomId).set(newRoom.toMap());

      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ルーム "$roomName" を作成しました\nルームID: $roomId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // TODO: チャット画面に遷移（作成者として）
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
      _showError('ルーム作成に失敗しました: $e');
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
                        Icons.add_circle_outline,
                        size: 80,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '部屋を作成',
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
                          controller: _roomNameController,
                          maxLength: 30,
                          decoration: InputDecoration(
                            labelText: 'ルーム名',
                            hintText: 'ルーム名を入力（最大30文字）',
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
                            counterText: '${_roomNameController.text.length}/30',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 400,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createRoom,
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
                                  '作成する',
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