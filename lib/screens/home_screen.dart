import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import '../models/chat_room.dart';
import '../models/friendship.dart';
import '../models/block.dart';
import 'auth_screen.dart';
import 'create_room_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const HomeScreen({
    Key? key,
    required this.authService,
    required this.storageService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ChatService _chatService;
  int _pendingFriendRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.storageService);
    _updatePendingFriendRequests();
  }

  void _updatePendingFriendRequests() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final count = widget.storageService.friendships
        .where((f) => f.receiverId == currentUserId && f.status == 'pending')
        .length;
    setState(() {
      _pendingFriendRequestCount = count;
    });
  }

  Future<void> _handleLogout() async {
    await widget.authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
        ),
      );
    }
  }

  void _navigateToCreateRoom() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(
          authService: widget.authService,
          chatService: _chatService,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _showAvailableRooms() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final availableRooms = widget.storageService.rooms
        .where((room) {
          final hasOpenSlot = (room.id1.isEmpty && room.id2.isNotEmpty) ||
              (room.id2.isEmpty && room.id1.isNotEmpty);
          final notMyRoom = room.id1 != currentUserId && room.id2 != currentUserId;
          final now = DateTime.now();
          final notExpired = room.expiresAt.isAfter(now);
          
          return hasOpenSlot && notMyRoom && notExpired;
        })
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('参加可能なルーム'),
        content: availableRooms.isEmpty
            ? Text('参加可能なルームはありません')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = availableRooms[index];
                    final creator = room.id1.isNotEmpty ? room.id1 : room.id2;
                    return ListTile(
                      title: Text(room.topic),
                      subtitle: Text('作成者: $creator'),
                      onTap: () async {
                        await _chatService.joinRoom(room.id, currentUserId);
                        await widget.storageService.save();
                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                roomId: room.id,
                                authService: widget.authService,
                                chatService: _chatService,
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showFriendsList() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final friends = widget.storageService.friendships
        .where((f) =>
            f.status == 'accepted' &&
            (f.senderId == currentUserId || f.receiverId == currentUserId))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('フレンド一覧'),
        content: friends.isEmpty
            ? Text('フレンドはいません')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friendship = friends[index];
                    final friendId = friendship.senderId == currentUserId
                        ? friendship.receiverId
                        : friendship.senderId;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(friendId),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showBlockList() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final blocks = widget.storageService.blocks
        .where((b) => b.blockerId == currentUserId && b.active)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ブロック一覧'),
        content: blocks.isEmpty
            ? Text('ブロック中のユーザーはいません')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    return ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text(block.blockedId),
                      trailing: TextButton(
                        onPressed: () async {
                          final idx = widget.storageService.blocks.indexOf(block);
                          widget.storageService.blocks[idx] =
                              block.copyWith(active: false);
                          await widget.storageService.save();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ブロックを解除しました')),
                          );
                        },
                        child: Text('解除'),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Whispin'),
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: _updatePendingFriendRequests,
              ),
              if (_pendingFriendRequestCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingFriendRequestCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('プロフィール'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('名前: ${currentUser?.fullName ?? ''}'),
                      SizedBox(height: 8),
                      Text('ニックネーム: ${currentUser?.displayName ?? ''}'),
                      SizedBox(height: 8),
                      Text('メール: ${currentUser?.id ?? ''}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: _handleLogout,
                      child: Text('ログアウト', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667EEA).withOpacity(0.1),
              Color(0xFF764BA2).withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMenuButton(
                icon: Icons.meeting_room,
                label: '部屋に参加',
                onTap: _showAvailableRooms,
              ),
              _buildMenuButton(
                icon: Icons.block,
                label: 'ブロック一覧',
                onTap: _showBlockList,
              ),
              _buildMenuButton(
                icon: Icons.add_circle,
                label: '部屋を作成',
                onTap: _navigateToCreateRoom,
              ),
              _buildMenuButton(
                icon: Icons.people,
                label: 'フレンド一覧',
                onTap: _showFriendsList,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
