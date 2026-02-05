import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/header.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../providers/user_provider.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserData();
    });
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

      logger.info('取得したメールアドレス: $email', name: _logName);

      await userProvider.loadUserData(email);

      if (userProvider.error != null) {
        logger.error('ユーザー情報読み込みエラー: ${userProvider.error}', name: _logName);

        if (mounted) {
          context.showErrorSnackBar('ユーザー情報の読み込みに失敗しました: ${userProvider.error}');
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

  void _navigateToCreateRoom() {
    logger.info('ルーム作成画面へ遷移', name: _logName);
    NavigationHelper.toRoomCreate(context);
  }

  void _navigateToFriendList() {
    NavigationHelper.toFriendList(context);
  }

  void _navigateToBlockList() {
    NavigationHelper.toBlockList(context);
  }

  void _navigateToJoinRoom() {
    logger.info('ルーム参加画面へ遷移', name: _logName);
    NavigationHelper.toRoomJoin(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: CommonHeader(
        title: AppConstants.appName,
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      body: Container(
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
                onTap: _navigateToJoinRoom,
                isDark: isDark,
              ),
              _buildMenuButton(
                icon: Icons.block,
                label: 'ブロック一覧',
                onTap: _navigateToBlockList,
                isDark: isDark,
              ),
              _buildMenuButton(
                icon: Icons.add_circle,
                label: '部屋を作成',
                onTap: _navigateToCreateRoom,
                isDark: isDark,
              ),
              _buildMenuButton(
                icon: Icons.people,
                label: 'フレンド一覧',
                onTap: _navigateToFriendList,
                isDark: isDark,
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
    required bool isDark,
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
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.8),
                      AppColors.secondary.withOpacity(0.8),
                    ],
                  )
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
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
                style: AppTextStyles.buttonMedium.copyWith(
                  shadows: isDark
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
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