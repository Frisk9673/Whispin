import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../models/friendship.dart';
import '../../models/user.dart' as app_user;

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
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

      // Friendshipコレクションから自分が関わっているフレンド関係を取得
      // userId == currentUserEmail または friendId == currentUserEmail
      final friendshipsSnapshot1 = await _firestore
          .collection('friendships')
          .where('userId', isEqualTo: currentUserEmail)
          .where('active', isEqualTo: true)
          .get();

      final friendshipsSnapshot2 = await _firestore
          .collection('friendships')
          .where('friendId', isEqualTo: currentUserEmail)
          .where('active', isEqualTo: true)
          .get();

      // 両方のクエリ結果を結合
      final allFriendships = [
        ...friendshipsSnapshot1.docs,
        ...friendshipsSnapshot2.docs,
      ];

      // フレンドのユーザー情報を取得
      final List<Map<String, dynamic>> friendsList = [];
      
      for (var doc in allFriendships) {
        final friendship = Friendship.fromMap(doc.data());
        
        // 相手のIDを特定
        final friendId = friendship.userId == currentUserEmail
            ? friendship.friendId
            : friendship.userId;

        // Userコレクションからフレンドの情報を取得
        try {
          final userDoc = await _firestore.collection('User').doc(friendId).get();
          
          if (userDoc.exists) {
            final userData = app_user.User.fromMap(userDoc.data()!);
            friendsList.add({
              'id': friendId,
              'name': userData.displayName,
              'friendshipId': friendship.id,
            });
          } else {
            // Userドキュメントが存在しない場合はIDのみ表示
            friendsList.add({
              'id': friendId,
              'name': friendId,
              'friendshipId': friendship.id,
            });
          }
        } catch (e) {
          print('フレンド情報取得エラー: $e');
          // エラーの場合はIDのみ表示
          friendsList.add({
            'id': friendId,
            'name': friendId,
            'friendshipId': friendship.id,
          });
        }
      }

      setState(() {
        _friends = friendsList;
        _isLoading = false;
      });

    } catch (e) {
      print('フレンド一覧取得エラー: $e');
      setState(() => _isLoading = false);
      _showError('フレンド一覧の取得に失敗しました: $e');
    }
  }

  Future<void> _removeFriend(int index) async {
    final friend = _friends[index];
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('フレンド削除'),
        content: Text('${friend['name']} をフレンドから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      // Friendshipのactiveをfalseに更新（ソフトデリート）
      await _firestore
          .collection('friendships')
          .doc(friend['friendshipId'])
          .update({'active': false});

      setState(() {
        _friends.removeAt(index);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フレンドを削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('削除に失敗しました: $e');
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
                    Icons.people,
                    size: 32,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'フレンド一覧',
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
                        color: Colors.black87,
                      ),
                    )
                  : _friends.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'フレンドがいません',
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
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.black87,
                                  child: Text(
                                    friend['name']![0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  friend['name']!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  friend['id']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.person_remove,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeFriend(index),
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