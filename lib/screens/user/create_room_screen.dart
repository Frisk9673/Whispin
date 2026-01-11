import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../routes/navigation_helper.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class CreateRoomScreen extends StatefulWidget {
  final AuthService authService;
  final ChatService chatService;
  final StorageService storageService;

  const CreateRoomScreen({
    super.key,
    required this.authService,
    required this.chatService,
    required this.storageService,
  });

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _topicController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  static const String _logName = 'CreateRoomScreen';

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    final topic = _topicController.text.trim();

    // バリデーション
    if (topic.isEmpty) {
      setState(() {
        _errorMessage = 'ルーム名を入力してください';
      });
      return;
    }

    if (topic.length > AppConstants.roomNameMaxLength) {
      setState(() {
        _errorMessage = 'ルーム名は${AppConstants.roomNameMaxLength}文字以内で入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.section('ルーム作成処理開始', name: _logName);
      logger.info('ルーム名: $topic', name: _logName);

      final currentUserId = widget.authService.currentUser?.id ?? '';
      
      if (currentUserId.isEmpty) {
        logger.error('ユーザーIDが取得できません', name: _logName);
        throw Exception('ログインしてください');
      }

      logger.info('作成者: $currentUserId', name: _logName);

      final room = await widget.chatService.createRoom(topic, currentUserId);

      logger.success('ルーム作成成功: ${room.id}', name: _logName);

      if (!mounted) return;

      // ✅ NavigationHelper使用 - チャット画面へ遷移
      await NavigationHelper.toChat(
        context,
        roomId: room.id,
        authService: widget.authService,
        chatService: widget.chatService,
        storageService: widget.storageService,
      );

      logger.section('ルーム作成処理完了', name: _logName);

    } catch (e, stack) {
      logger.error('ルーム作成エラー: $e', name: _logName, error: e, stackTrace: stack);
      
      setState(() {
        _errorMessage = 'ルーム作成に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 拡張メソッド使用
    final isMobile = context.isMobile;
    final isSmallScreen = context.isSmallScreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ルーム作成'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // ✅ 拡張メソッド
        ),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                // ✅ レスポンシブ対応
                isSmallScreen 
                    ? AppConstants.defaultPadding / 2 
                    : AppConstants.defaultPadding
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 500,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
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
                        size: 80,
                        color: AppColors.textWhite,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      '新しいルームを作成',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 入力フォームカード
                    Card(
                      elevation: AppConstants.cardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ルーム名入力
                            TextField(
                              controller: _topicController,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                labelText: 'ルーム名',
                                hintText: 'チャットのテーマを入力',
                                prefixIcon: Icon(Icons.title, color: AppColors.primary),
                                counterText: '${_topicController.text.length}/${AppConstants.roomNameMaxLength}',
                                errorText: _errorMessage,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultBorderRadius,
                                  ),
                                ),
                              ),
                              maxLength: AppConstants.roomNameMaxLength,
                              onChanged: (value) {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              style: AppTextStyles.bodyLarge,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // 作成ボタン
                            SizedBox(
                              height: AppConstants.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleCreateRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.defaultBorderRadius,
                                    ),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: _isLoading 
                                        ? null 
                                        : AppColors.primaryGradient,
                                    color: _isLoading ? AppColors.divider : null,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.defaultBorderRadius,
                                    ),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
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
                    
                    const SizedBox(height: 16),
                    
                    // 情報カード
                    Card(
                      elevation: 2,
                      color: AppColors.info.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
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
                            _buildInfoItem('最大2人まで参加可能'),
                            _buildInfoItem(
                              '${AppConstants.defaultChatDurationMinutes}分間のチャット時間'
                            ),
                            _buildInfoItem(
                              '残り${AppConstants.extensionRequestThresholdMinutes}分以下で延長リクエスト可能'
                            ),
                            _buildInfoItem('両者退出で自動削除'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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