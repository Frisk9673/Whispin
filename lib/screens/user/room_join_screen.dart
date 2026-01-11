import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/header.dart';
import '../../repositories/chat_room_repository.dart';
import '../../repositories/user_repository.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../extensions/context_extensions.dart';
import '../../utils/app_logger.dart';

class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final _roomRepository = ChatRoomRepository();
  final _userRepository = UserRepository();

  bool _isLoading = false;
  static const String _logName = 'RoomJoinScreen';

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final roomId = _roomIdController.text.trim();

    if (roomId.isEmpty) {
      // ✅ context拡張メソッド使用
      context.showErrorSnackBar('ルームIDを入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      logger.section('ルーム参加処理開始', name: _logName);
      logger.info('roomId: $roomId', name: _logName);

      // 現在のユーザー取得
      final userProvider = context.read<UserProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        // ✅ context拡張メソッド使用
        context.showErrorSnackBar('ログインしてください');
        setState(() => _isLoading = false);
        return;
      }

      final currentUserEmail = currentUser.id;
      logger.info('参加ユーザー: $currentUserEmail', name: _logName);

      // ルーム存在チェック
      logger.start('ルーム情報取得中...', name: _logName);
      final room = await _roomRepository.findById(roomId);
      if (!mounted) return;

      if (room == null) {
        logger.warning('ルームが見つかりません', name: _logName);
        // ✅ context拡張メソッド使用
        context.showErrorSnackBar('ルームが見つかりません');
        setState(() => _isLoading = false);
        return;
      }

      logger.success('ルーム発見: ${room.topic}', name: _logName);

      // ステータスチェック
      if (room.isFinished) {
        logger.warning('ルームは終了しています', name: _logName);
        // ✅ context拡張メソッド使用
        context.showErrorSnackBar('このルームは終了しています');
        setState(() => _isLoading = false);
        return;
      }

      if (room.isActive) {
        // アクティブな場合は有効期限チェック
        if (DateTime.now().isAfter(room.expiresAt)) {
          logger.warning('ルームは期限切れです', name: _logName);
          // ✅ context拡張メソッド使用
          context.showErrorSnackBar('このルームは期限切れです');
          setState(() => _isLoading = false);
          return;
        }
      }

      // 既に参加しているかチェック
      if (room.id1 == currentUserEmail || room.id2 == currentUserEmail) {
        logger.warning('既にこのルームに参加しています', name: _logName);
        // ✅ context拡張メソッド使用
        context.showErrorSnackBar('既にこのルームに参加しています');
        setState(() => _isLoading = false);
        return;
      }

      // 満員チェック
      if (room.id2 != null && room.id2!.isNotEmpty) {
        logger.warning('ルームは満員です', name: _logName);
        // ✅ context拡張メソッド使用
        context.showErrorSnackBar('ルームは満員です（2人まで）');
        setState(() => _isLoading = false);
        return;
      }

      // ルームに参加
      logger.start('ルームに参加中...', name: _logName);
      await _roomRepository.joinRoom(roomId, currentUserEmail);
      logger.success('ルーム参加成功', name: _logName);

      // ユーザーのルーム参加回数を更新
      try {
        await _userRepository.incrementRoomCount(currentUserEmail);
        logger.success('ルーム参加回数更新完了', name: _logName);
      } catch (e) {
        logger.warning('ルーム参加回数更新失敗: $e', name: _logName);
        // 失敗しても続行
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      logger.section('ルーム参加処理完了', name: _logName);

      // ✅ context拡張メソッド使用
      context.showSuccessSnackBar(
        'ルーム "${room.topic}" に参加しました\nチャットが開始されました（${AppConstants.defaultChatDurationMinutes}分間）',
      );

      // TODO: チャット画面に遷移
      // NavigationHelper.toChat(
      //   context,
      //   roomId: roomId,
      //   authService: authService,
      //   chatService: chatService,
      //   storageService: storageService,
      // );

      // 仮で前の画面に戻る
      // ✅ context拡張メソッド使用
      context.pop();
    } catch (e, stack) {
      logger.error(
        'ルーム参加エラー: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );

      setState(() => _isLoading = false);
      // ✅ context拡張メソッド使用
      context.showErrorSnackBar('参加に失敗しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 統一ヘッダーを使用
      appBar: CommonHeader(
        title: '部屋に参加',
        showNotifications: true,
        showProfile: true,
        showPremiumBadge: true,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.meeting_room,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '部屋に参加',
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 40),

              // ルームID入力
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _roomIdController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'ルームID',
                    hintText: 'ルームIDを入力',
                    prefixIcon: Icon(Icons.vpn_key, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      borderSide: BorderSide(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),

              // 参加ボタン
              SizedBox(
                width: 400,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '参加する',
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // 情報カード
              Card(
                elevation: AppConstants.cardElevation,
                color: AppColors.backgroundLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.defaultPadding - 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '参加について',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem('ルームIDは作成者から共有されます'),
                      _buildInfoItem(
                          '参加すると${AppConstants.defaultChatDurationMinutes}分間のチャットが開始されます'),
                      _buildInfoItem(
                          '延長は残り${AppConstants.extensionRequestThresholdMinutes}分以下で可能'),
                      _buildInfoItem(
                          '最大${AppConstants.defaultExtensionLimit}回まで延長可能（通常会員）'),
                    ],
                  ),
                ),
              ),
            ],
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
            Icons.check_circle,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
