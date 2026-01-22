import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
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

/// ルーム作成画面（Private対応版）
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
  bool _isPrivate = false; // ✅ 追加: Privateフラグ
  static const String _logName = 'RoomCreateScreen';

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  /// ルーム作成処理
  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim();

    // バリデーション
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
      logger.info('プライベート: $_isPrivate', name: _logName); // ✅ ログ追加

      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      final farFuture = DateTime.now().add(const Duration(days: 365));

      // ✅ Private設定を含むChatRoomオブジェクトを作成
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
        private: _isPrivate, // ✅ Private設定を反映
      );

      // Repository経由でFirestoreに保存
      await _roomRepository.create(newRoom, id: roomId);

      logger.success('ルーム作成完了: $roomId', name: _logName);
      logger.info('ルーム情報: $newRoom', name: _logName);

      if (!mounted) return;

      logger.start('チャット画面へ自動遷移します', name: _logName);
      
      setState(() => _isLoading = false);
      
      // NavigationHelperを使用してチャット画面へ遷移
      await NavigationHelper.toChat(
        context,
        roomId: roomId,
        authService: context.read<AuthService>(),
        chatService: context.read<ChatService>(),
        storageService: context.read<StorageService>(),
      );

      logger.success('チャット画面遷移完了', name: _logName);
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

              // タイトル
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

                        // ✅ Private/Public切り替え
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
                                      _isPrivate
                                          ? 'プライベートルーム'
                                          : 'パブリックルーム',
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

                        // 作成ボタン
                        SizedBox(
                          height: AppConstants.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? null
                                    : AppColors.primaryGradient,
                                color: _isLoading ? AppColors.divider : null,
                                borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.textWhite,
                                        ),
                                      )
                                    : Text(
                                        'ルームを作成',
                                        style: AppTextStyles.buttonMedium,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 情報カード
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 2,
                  color: AppColors.info.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ルーム情報',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          _isPrivate
                              ? '作成後、フレンドを招待できます'
                              : '作成後、チャット画面で相手の参加を待ちます',
                        ),
                        _buildInfoItem(
                          _isPrivate
                              ? 'ルーム検索には表示されません'
                              : 'ルーム名で検索して参加してもらえます',
                        ),
                        _buildInfoItem('最大2人まで参加可能'),
                        _buildInfoItem(
                            '2人目が参加すると${AppConstants.defaultChatDurationMinutes}分間のチャット開始'),
                        _buildInfoItem(
                            '残り${AppConstants.extensionRequestThresholdMinutes}分以下で延長リクエスト可能'),
                        _buildInfoItem('両者退出で自動削除'),
                      ],
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

  /// 情報アイテムを構築
  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}