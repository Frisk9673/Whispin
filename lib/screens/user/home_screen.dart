import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../widgets/navigation/bottom_navigation_bar.dart';
import '../../widgets/navigation/side_navigation_bar.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../providers/user_provider.dart';
import '../../repositories/block_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/chat_room.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/navigation_items.dart';
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';
import 'room_join_screen.dart';
import 'room_create_screen.dart';
import 'friend_list_screen.dart';
import 'block_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final StorageService storageService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _logName = 'HomeScreen';
  int _currentNavIndex = 0;
  bool _isLoadingRooms = true;
  List<ChatRoom> _randomRooms = [];
  final BlockRepository _blockRepository = BlockRepository();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserData();
      _loadRandomRooms();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAndLoadUserData() async {
    logger.section('UserProvider状態確認', name: _logName);

    final userProvider = context.read<UserProvider>();

    if (userProvider.currentUser == null && !userProvider.isLoading) {
      logger.warning('ユーザー情報が未読み込み → 読み込みを開始', name: _logName);

      final currentUser = FirebaseAuth.instance.currentUser;
      final email = currentUser?.email;

      if (email == null) {
        logger.error('Firebase Auth ユーザーのメールアドレスが取得できません', name: _logName);
        if (mounted) {
          context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
        }
        return;
      }

      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);
        if (mounted) {
          context.showErrorSnackBar('ユーザー情報の読み込みに失敗しました');
        }
      } else {
        logger.success('ユーザー情報読み込み完了', name: _logName);
      }
    }
  }

  Future<void> _loadRandomRooms() async {
    logger.section('ランダムルーム読み込み開始', name: _logName);
    
    setState(() => _isLoadingRooms = true);

    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        logger.warning('ユーザー情報なし', name: _logName);
        setState(() => _isLoadingRooms = false);
        return;
      }

      final chatService = context.read<ChatService>();

      // 参加可能なルームを取得
      final rooms = await chatService.getJoinableRooms(
        currentUserId: currentUser.id,
        blockRepository: _blockRepository,
      );

      // ランダムにシャッフル
      rooms.shuffle();

      // 最大10件まで表示
      final displayRooms = rooms.take(10).toList();

      setState(() {
        _randomRooms = displayRooms;
        _isLoadingRooms = false;
      });

      logger.success('ランダムルーム読み込み完了: ${displayRooms.length}件', name: _logName);
    } catch (e, stack) {
      logger.error('ランダムルーム読み込みエラー: $e',
          name: _logName, error: e, stackTrace: stack);
      
      setState(() => _isLoadingRooms = false);
      
      if (mounted) {
        context.showErrorSnackBar('ルーム情報の読み込みに失敗しました');
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  Future<void> _joinRoom(ChatRoom room) async {
    logger.section('ルーム参加処理開始', name: _logName);
    
    try {
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        context.showErrorSnackBar('ログインしてください');
        return;
      }

      final chatService = context.read<ChatService>();
      final userRepository = context.read<UserRepository>();

      await chatService.joinRoomWithUserUpdate(
        roomId: room.id,
        currentUserId: currentUser.id,
        userRepository: userRepository,
      );

      if (!mounted) return;

      context.showSuccessSnackBar('ルーム "${room.topic}" に参加しました');

      await NavigationHelper.toChat(
        context,
        roomId: room.id,
        authService: context.read<AuthService>(),
        chatService: chatService,
        storageService: context.read<StorageService>(),
      );
    } catch (e, stack) {
      logger.error('参加エラー: $e', name: _logName, error: e, stackTrace: stack);
      
      if (mounted) {
        context.showErrorSnackBar('参加に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isDark = context.isDark;

    return Scaffold(
      appBar: CommonHeader(
        title: AppConstants.appName,
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      body: Row(
        children: [
          // Web/デスクトップ用サイドバー
          if (!isMobile)
            AppSideNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: _onNavItemTapped,
            ),

          // メインコンテンツ（PageView）
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: isMobile
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              children: [
                // 0: ホーム
                _buildHomeContent(isDark),
                
                // 1: ルーム参加
                const RoomJoinScreen(),

                // 2: ルーム作成
                const RoomCreateScreen(),
                
                // 3: フレンド一覧
                const FriendListScreen(),
                
                // 4: ブロック一覧
                const BlockListScreen(),
              ],
            ),
          ),
        ],
      ),
      // モバイル用ボトムナビゲーション
      bottomNavigationBar: isMobile
          ? AppBottomNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: _onNavItemTapped,
            )
          : null,
    );
  }

  Widget _buildHomeContent(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkSurface,
                  AppColors.darkBackground,
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundLight,
                  AppColors.backgroundSecondary,
                ],
              ),
      ),
      child: _isLoadingRooms
          ? const LoadingWidget(message: 'ルームを読み込み中...')
          : _randomRooms.isEmpty
              ? _buildEmptyState(isDark)
              : _buildRoomList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return EmptyStateWidget(
      icon: Icons.inbox,
      title: '参加可能なルームがありません',
      subtitle: 'ルームを作成して始めましょう',
      action: GradientButton(
        label: 'ルームを作成',
        icon: Icons.add_circle,
        onPressed: () {
          _onNavItemTapped(2); // ルーム作成タブに移動
        },
      ),
    );
  }

  Widget _buildRoomList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadRandomRooms,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: CustomScrollView(
        slivers: [
          // ヘッダー
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shuffle,
                        color: isDark
                            ? AppColors.primary.lighten(0.2)
                            : AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '参加可能なルーム',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.primary.lighten(0.2)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: _loadRandomRooms,
                        tooltip: '更新',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ランダムに表示されています（最大10件）',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ルームリスト
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final room = _randomRooms[index];
                  return _buildRoomCard(room, isDark);
                },
                childCount: _randomRooms.length,
              ),
            ),
          ),

          // 下部パディング
          SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.defaultPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(ChatRoom room, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: AppConstants.cardElevation,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: isDark
            ? BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _joinRoom(room),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ルーム名
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.secondary.withOpacity(0.8),
                              ],
                            )
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.topic,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ステータス
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isDark
                        ? AppColors.info.lighten(0.2)
                        : AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '参加待ち',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.info.lighten(0.2)
                          : AppColors.info,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 参加ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinRoom(room),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('参加する'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.primary.withOpacity(0.9)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
