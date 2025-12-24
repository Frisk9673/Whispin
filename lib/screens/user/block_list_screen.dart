import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../models/block.dart';
import '../../models/user.dart' as app_user;

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email;
      if (currentUserEmail == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Blockコレクションから自分がブロックしたユーザーを取得
      final blocksSnapshot = await _firestore
          .collection('blocks')
          .where('blockerId', isEqualTo: currentUserEmail)
          .where('active', isEqualTo: true) // activeなブロックのみ
          .get();

      // ブロックユーザーの情報を取得
      final List<Map<String, dynamic>> blockedList = [];
      
      for (var doc in blocksSnapshot.docs) {
        final block = Block.fromMap(doc.data());
        
        // Userコレクションからブロックユーザーの情報を取得
        try {
          final userDoc = await _firestore
              .collection('User')
              .doc(block.blockedId)
              .get();
          
          if (userDoc.exists) {
            final userData = app_user.User.fromMap(userDoc.data()!);
            blockedList.add({
              'id': block.blockedId,
              'name': userData.displayName,
              'blockId': block.id,
            });
          } else {
            // Userドキュメントが存在しない場合はIDのみ表示
            blockedList.add({
              'id': block.blockedId,
              'name': block.blockedId,
              'blockId': block.id,
            });
          }
        } catch (e) {
          print('ブロックユーザー情報取得エラー: $e');
          // エラーの場合はIDのみ表示
          blockedList.add({
            'id': block.blockedId,
            'name': block.blockedId,
            'blockId': block.id,
          });
        }
      }

      setState(() {
        _blockedUsers = blockedList;
        _isLoading = false;
      });

    } catch (e) {
      print('ブロック一覧取得エラー: $e');
      setState(() => _isLoading = false);
      _showError('ブロック一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _unblockUser(int index) async {
    final user = _blockedUsers[index];
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ブロック解除'),
        content: Text('${user['name']} のブロックを解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              '解除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      // Blockのactiveをfalseに更新（ソフトデリート）
      await _firestore
          .collection('blocks')
          .doc(user['blockId'])
          .update({'active': false});

      setState(() {
        _blockedUsers.removeAt(index);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ブロックを解除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('ブロック解除に失敗しました: $e');
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: const [
                  Icon(
                    Icons.block,
                    size: 32,
                    color: Colors.red,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'ブロック一覧',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                      ),
                    )
                  : _blockedUsers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ブロック中のユーザーはいません',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _blockedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _blockedUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.block,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  user['name']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  user['id']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _unblockUser(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '解除',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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