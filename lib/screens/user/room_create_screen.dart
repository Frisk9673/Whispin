import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
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
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

/// ルーム作成画面（統一ウィジェット適用版）
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
    return Scaffold(
      appBar: CommonHeader(
        title: '部屋を作成',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: AppColors.cardBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 64,
                  color: AppColors.textWhite,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '部屋を作成',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                '新しいチャットルームを作成します',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // 入力フォーム
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: AppConstants.cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ルーム名入力
                        TextField(
                          controller: _roomNameController,
                          maxLength: AppConstants.roomNameMaxLength,
                          decoration: InputDecoration(
                            labelText: 'ルーム名',
                            hintText: 'チャットのテーマを入力',
                            prefixIcon: const Icon(Icons.title),
                            counterText:
                                '${_roomNameController.text.length}/${AppConstants.roomNameMaxLength}',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 24),

                        // Private/Public切り替え
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isPrivate
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius),
                            border: Border.all(
                              color: _isPrivate
                                  ? AppColors.primary
                                  : AppColors.divider,
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
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isPrivate ? 'プライベートルーム' : 'パブリックルーム',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: _isPrivate
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
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
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isPrivate
                                    ? '招待したフレンドのみ参加可能です'
                                    : '誰でも検索して参加できます',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 作成ボタン（統一ウィジェット使用）
                        GradientButton(
                          label: 'ルームを作成',
                          onPressed: _createRoom,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 情報カード（統一ウィジェット使用）
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: InfoCard(
                  icon: Icons.info_outline,
                  title: 'ルーム情報',
                  iconColor: AppColors.info,
                  children: [
                    InfoItem(
                      text: _isPrivate
                          ? '作成後、フレンドを招待できます'
                          : '作成後、チャット画面で相手の参加を待ちます',
                      color: AppColors.info,
                    ),
                    InfoItem(
                      text: _isPrivate
                          ? 'ルーム検索には表示されません'
                          : 'ルーム名で検索して参加してもらえます',
                      color: AppColors.info,
                    ),
                    InfoItem(
                      text: '最大2人まで参加可能',
                      color: AppColors.info,
                    ),
                    InfoItem(
                      text: '2人目が参加すると${AppConstants.defaultChatDurationMinutes}分間のチャット開始',
                      color: AppColors.info,
                    ),
                    InfoItem(
                      text: '残り${AppConstants.extensionRequestThresholdMinutes}分以下で延長リクエスト可能',
                      color: AppColors.info,
                    ),
                    InfoItem(
                      text: '両者退出で自動削除',
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}