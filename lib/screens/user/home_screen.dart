import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/chat_service.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import 'auth_screen.dart';
import 'create_room_screen.dart';
import 'chat_screen.dart';
import 'profile.dart';
import '../../utils/app_logger.dart';

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
  static const String _logName = 'HomeScreen';
  
  late ChatService _chatService;
  int _pendingFriendRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.storageService);
    _updatePendingFriendRequests();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserData();
    });
  }

  Future<void> _checkAndLoadUserData() async {
    logger.section('UserProvider状態確認', name: _logName);
    
    final userProvider = context.read<UserProvider>();
    
    if (userProvider.currentUser == null && !userProvider.isLoading) {
      logger.warning('ユーザー情報が未読み込み → 読み込みを開始', name: _logName);
      
      // 🔧 修正: FirebaseAuthからメールアドレスを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      final email = currentUser?.email;
      
      if (email == null) {
        logger.error('Firebase Auth ユーザーのメールアドレスが取得できません', name: _logName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザー情報の取得に失敗しました'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      logger.info('取得したメールアドレス: $email', name: _logName);
      
      await userProvider.loadUserData(email);
      
      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ユーザー情報の読み込みに失敗しました: ${userProvider.error}'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        logger.success('ユーザー情報読み込み完了', name: _logName);
        logger.info('  名前: ${userProvider.currentUser?.fullName}', name: _logName);
        logger.info('  プレミアム: ${userProvider.currentUser?.premium}', name: _logName);
      }
    } else if (userProvider.currentUser != null) {
      logger.success('ユーザー情報は既に読み込み済み', name: _logName);
      logger.info('  名前: ${userProvider.currentUser?.fullName}', name: _logName);
      logger.info('  プレミアム: ${userProvider.currentUser?.premium}', name: _logName);
    } else {
      logger.info('ユーザー情報読み込み中...', name: _logName);
    }
    
    logger.section('状態確認完了', name: _logName);
  }

  void _updatePendingFriendRequests() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final count = widget.storageService.friendRequests
        .where((r) => r.receiverId == currentUserId && r.isPending)
        .length;

    setState(() {
      _pendingFriendRequestCount = count;
    });
    
    logger.debug('フレンドリクエスト未読数: $count', name: _logName);
  }

  Future<void> _handleLogout() async {
    logger.section('ログアウト処理開始', name: _logName);
    
    logger.start('UserProviderクリア中...', name: _logName);
    context.read<UserProvider>().clearUser();
    logger.success('UserProviderクリア完了', name: _logName);
    
    logger.start('AuthServiceログアウト中...', name: _logName);
    await widget.authService.logout();
    logger.success('AuthServiceログアウト完了', name: _logName);
    
    if (mounted) {
      logger.start('AuthScreen へ遷移', name: _logName);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            authService: widget.authService,
            storageService: widget.storageService,
          ),
        ),
      );
    }
    
    logger.section('ログアウト処理完了', name: _logName);
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
    final availableRooms = widget.storageService.rooms.where((room) {
      final hasOpenSlot =
          ((room.id1 ?? '').isEmpty && (room.id2 ?? '').isNotEmpty) ||
              ((room.id2 ?? '').isEmpty && (room.id1 ?? '').isNotEmpty);
      final notMyRoom = room.id1 != currentUserId && room.id2 != currentUserId;
      final now = DateTime.now();
      final notExpired = room.expiresAt.isAfter(now);

      return hasOpenSlot && notMyRoom && notExpired;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text('参加可能なルーム', style: AppTextStyles.titleLarge),
        content: availableRooms.isEmpty
            ? Text(AppConstants.defaultMessage, style: AppTextStyles.bodyMedium)
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = availableRooms[index];
                    final creator = (room.id1 ?? '').isNotEmpty ? room.id1 ?? '' : room.id2 ?? '';
                    return ListTile(
                      title: Text(room.topic, style: AppTextStyles.bodyLarge),
                      subtitle: Text('作成者: $creator', style: AppTextStyles.labelMedium),
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
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showFriendsList() {
    final currentUserId = widget.authService.currentUser?.id ?? '';
    final friends = widget.storageService.friendships
        .where((f) =>
            f.active &&
            (f.userId == currentUserId || f.friendId == currentUserId))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text('フレンド一覧', style: AppTextStyles.titleLarge),
        content: friends.isEmpty
            ? Text('フレンドはいません', style: AppTextStyles.bodyMedium)
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friendship = friends[index];
                    final friendId = friendship.userId == currentUserId
                        ? friendship.friendId
                        : friendship.userId;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                      ),
                      title: Text(friendId, style: AppTextStyles.bodyLarge),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        title: Text('ブロック一覧', style: AppTextStyles.titleLarge),
        content: blocks.isEmpty
            ? Text('ブロック中のユーザーはいません', style: AppTextStyles.bodyMedium)
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    return ListTile(
                      leading: Icon(Icons.block, color: AppColors.error),
                      title: Text(block.blockedId, style: AppTextStyles.bodyMedium),
                      trailing: TextButton(
                        onPressed: () async {
                          final idx =
                              widget.storageService.blocks.indexOf(block);
                          widget.storageService.blocks[idx] =
                              block.copyWith(active: false);
                          await widget.storageService.save();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ブロックを解除しました'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Text('解除'),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = widget.authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _updatePendingFriendRequests,
              ),
              if (_pendingFriendRequestCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_pendingFriendRequestCount',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          if (userProvider.isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.premiumGold,
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.diamond, size: 16, color: AppColors.textWhite),
                      const SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundSecondary,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
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
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.textWhite,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.buttonMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}