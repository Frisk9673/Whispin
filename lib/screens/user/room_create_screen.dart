import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/unified_widgets.dart';
import '../../models/chat_room.dart';
import '../../repositories/chat_room_repository.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../constants/responsive.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

/// レスポンシブ対応のルーム作成画面（ダークモード対応版）
class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final TextEditingController _roomNameController = TextEditingController();
  final ChatRoomRepository _roomRepository = ChatRoomRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPrivate = false;
  static const String _logName = 'RoomCreateScreen';

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();

    if (roomName.isEmpty) {
      context.showErrorSnackBar('ルーム名を入力してください');
      return;
    }

    if (roomName.length > AppConstants.roomNameMaxLength) {
      context.showErrorSnackBar(
          'ルーム名は${AppConstants.roomNameMaxLength}文字以内で入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      logger.section('ルーム作成開始', name: _logName);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        context.showErrorSnackBar('ログインしてください');
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.email;
      if (currentUserEmail == null) {
        context.showErrorSnackBar('ユーザー情報が取得できません');
        setState(() => _isLoading = false);
        return;
      }

      logger.info('作成者: $currentUserEmail', name: _logName);
      logger.info('ルーム名: $roomName', name: _logName);
      logger.info('プライベート: $_isPrivate', name: _logName);

      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      final farFuture = DateTime.now().add(const Duration(days: 365));

      final newRoom = ChatRoom(
        id: roomId,
        topic: roomName,
        status: AppConstants.roomStatusWaiting,
        id1: currentUserEmail,
        id2: null,
        startedAt: farFuture,
        expiresAt: farFuture,
        extensionCount: 0,
        extension: AppConstants.defaultExtensionLimit,
        comment1: '',
        comment2: '',
        private: _isPrivate,
      );

      await _roomRepository.create(newRoom, id: roomId);

      logger.success('ルーム作成完了: $roomId', name: _logName);

      if (!mounted) return;

      setState(() => _isLoading = false);

      await NavigationHelper.toChat(
        context,
        roomId: roomId,
        authService: context.read<AuthService>(),
        chatService: context.read<ChatService>(),
        storageService: context.read<StorageService>(),
      );

      logger.section('ルーム作成処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('ルーム作成エラー: $e', name: _logName, error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      context.showErrorSnackBar('ルーム作成に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.cardBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン
                _buildHeaderIcon(isMobile, isDark),
                SizedBox(height: isMobile ? 16 : 24),

                // タイトル
                Text(
                  '部屋を作成',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: context.responsiveFontSize(28),
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 4 : 8),

                // サブタイトル
                Text(
                  '新しいチャットルームを作成します',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                    fontSize: context.responsiveFontSize(15),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 24 : 40),

                // 入力フォーム
                _buildFormCard(context, isMobile, isDark),
                SizedBox(height: isMobile ? 16 : 24),

                // 情報カード
                _buildInfoCard(context, isMobile, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダーアイコンを構築
  Widget _buildHeaderIcon(bool isMobile, bool isDark) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isDark
            ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.secondary.withOpacity(0.8),
                ],
              )
            : AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        Icons.add_circle_outline,
        size: isMobile ? 48 : 64,
        color: AppColors.textWhite,
      ),
    );
  }

  /// フォームカードを構築
  Widget _buildFormCard(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.maxFormWidth,
      ),
      child: Card(
        elevation: AppConstants.cardElevation,
        color: context.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ルーム名入力
              TextField(
                controller: _roomNameController,
                maxLength: AppConstants.roomNameMaxLength,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'ルーム名',
                  labelStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  hintText: 'チャットのテーマを入力',
                  hintStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.title,
                    color: context.colorScheme.primary,
                  ),
                  counterText:
                      '${_roomNameController.text.length}/${AppConstants.roomNameMaxLength}',
                  counterStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Private/Public切り替え
              _buildPrivacyToggle(isMobile, isDark),
              SizedBox(height: isMobile ? 16 : 24),

              // 作成ボタン
              GradientButton(
                label: 'ルームを作成',
                onPressed: _createRoom,
                isLoading: _isLoading,
                height: isMobile ? 48 : AppConstants.buttonHeight,
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.9),
                          AppColors.secondary.withOpacity(0.9),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// プライバシー切り替えを構築
  Widget _buildPrivacyToggle(bool isMobile, bool isDark) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: _isPrivate
            ? (isDark 
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.1))
            : (isDark ? AppColors.darkInput : AppColors.inputBackground),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: _isPrivate 
              ? (isDark 
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.primary)
              : (isDark ? AppColors.darkBorder : AppColors.divider),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isPrivate ? Icons.lock : Icons.public,
                color: _isPrivate
                    ? (isDark 
                        ? AppColors.primary.lighten(0.2)
                        : AppColors.primary)
                    : (isDark ? Colors.grey[400] : AppColors.textSecondary),
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  _isPrivate ? 'プライベートルーム' : 'パブリックルーム',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: _isPrivate
                        ? (isDark 
                            ? AppColors.primary.lighten(0.2)
                            : AppColors.primary)
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    fontSize: context.responsiveFontSize(16),
                  ),
                ),
              ),
              Switch(
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                activeColor: isDark 
                    ? AppColors.primary.lighten(0.2)
                    : AppColors.primary,
                activeTrackColor: isDark
                    ? AppColors.primary.withOpacity(0.3)
                    : null,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            _isPrivate
                ? '招待したフレンドのみ参加可能です'
                : '誰でも検索して参加できます',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey[500] : AppColors.textSecondary,
              fontSize: context.responsiveFontSize(13),
            ),
          ),
        ],
      ),
    );
  }

  /// 情報カードを構築
  Widget _buildInfoCard(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.maxFormWidth,
      ),
      child: InfoCard(
        icon: Icons.info_outline,
        title: 'ルーム情報',
        iconColor: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
        backgroundColor: isDark
            ? AppColors.info.withOpacity(0.15)
            : AppColors.info.withOpacity(0.1),
        padding: EdgeInsets.all(isMobile ? 12 : AppConstants.defaultPadding),
        children: [
          InfoItem(
            text: _isPrivate
                ? '作成後、フレンドを招待できます'
                : '作成後、チャット画面で相手の参加を待ちます',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
          InfoItem(
            text: _isPrivate
                ? 'ルーム検索には表示されません'
                : 'ルーム名で検索して参加してもらえます',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
          InfoItem(
            text: '最大2人まで参加可能',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
          InfoItem(
            text: '2人目が参加すると${AppConstants.defaultChatDurationMinutes}分間のチャット開始',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
          InfoItem(
            text: '残り${AppConstants.extensionRequestThresholdMinutes}分以下で延長リクエスト可能',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
          InfoItem(
            text: '両者退出で自動削除',
            color: isDark ? AppColors.info.lighten(0.2) : AppColors.info,
          ),
        ],
      ),
    );
  }
}
