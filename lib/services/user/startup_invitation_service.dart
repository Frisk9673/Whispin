import 'package:flutter/material.dart';
import '../../models/user/invitation.dart';
import 'invitation_service.dart';
import 'fcm_service.dart';
import 'storage_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../utils/app_logger.dart';

/// 【担当ユースケース】
/// - アプリ起動直後に招待を検出し、ユーザーへ承認/拒否UIを提示する。
/// - 受信経路（FCM初期メッセージ / ローカル保留招待）を時系列で統合処理する。
///
/// 【依存するRepository/Service】
/// - [StorageService]: 招待実体の検索。
/// - [InvitationService]: 招待承認/拒否のドメイン処理。
/// - [FCMService]: 起動時に開封された通知 payload の取得。
///
/// 【主な副作用（DB更新/通知送信）】
/// - 承認/拒否時に InvitationService 経由で招待/ルーム状態を更新・永続化する。
class StartupInvitationService {
  static const String _logName = 'StartupInvitationService';
  
  final StorageService _storageService;
  final InvitationService _invitationService;
  final FCMService _fcmService;
  
  StartupInvitationService({
    required StorageService storageService,
    required InvitationService invitationService,
    required FCMService fcmService,
  })  : _storageService = storageService,
        _invitationService = invitationService,
        _fcmService = fcmService;
  
  /// 入力: [context], [currentUserId]。
  /// 前提条件: ログイン済みユーザーIDが確定していること。
  /// 成功時結果: 起動時フローに沿って招待を検出し、必要なら確認ダイアログを表示する。
  /// 失敗時挙動: 例外は捕捉してログ出力し、起動フローは継続する。
  ///
  /// 起動時時系列:
  /// 1) FCM初期メッセージを確認
  /// 2) 該当なしならローカル保留招待を確認
  /// 3) 最新招待の確認ダイアログを表示
  Future<void> checkAndHandleInvitations(
    BuildContext context,
    String currentUserId,
  ) async {
    logger.section('アプリ起動時の招待チェック開始', name: _logName);
    logger.info('currentUserId: $currentUserId', name: _logName);
    
    try {
      // 1. FCMからの初期メッセージをチェック
      final fcmData = await _fcmService.checkInitialMessage();
      
      if (fcmData != null && fcmData['type'] == 'room_invitation') {
        logger.success('FCM招待メッセージを検出', name: _logName);
        await _handleFCMInvitation(context, fcmData, currentUserId);
        return;
      }
      
      // 2. 保留中の招待をチェック
      logger.start('保留中の招待を検索中...', name: _logName);
      final pendingInvitations = _invitationService.getReceivedInvitations(currentUserId);
      
      if (pendingInvitations.isEmpty) {
        logger.info('保留中の招待はありません', name: _logName);
        return;
      }
      
      logger.success('保留中の招待: ${pendingInvitations.length}件', name: _logName);
      
      // 最新の招待を取得
      final latestInvitation = pendingInvitations.first;
      
      // 3. 招待確認ダイアログを表示
      await _showInvitationDialog(context, latestInvitation, currentUserId);
      
      logger.section('招待チェック処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('招待チェックエラー: $e',
          name: _logName, error: e, stackTrace: stack);
    }
  }
  
  /// 入力: [context], [data], [currentUserId]。
  /// 前提条件: `data['type'] == 'room_invitation'` を満たす通知payloadであること。
  /// 成功時結果: payload から招待IDを解決し、確認ダイアログ表示へ接続する。
  /// 失敗時挙動: 必須データ不足/招待未存在時はログ出力して中断する。
  ///
  /// 受信時時系列:
  /// 1) payload検証
  /// 2) Storage上の招待を検索
  /// 3) 確認ダイアログ表示
  Future<void> _handleFCMInvitation(
    BuildContext context,
    Map<String, dynamic> data,
    String currentUserId,
  ) async {
    logger.section('FCM招待処理開始', name: _logName);
    
    try {
      final invitationId = data['invitationId'] as String?;
      final roomId = data['roomId'] as String?;
      final inviterName = data['inviterName'] as String?;
      
      if (invitationId == null || roomId == null) {
        logger.error('必須データが不足しています', name: _logName);
        return;
      }
      
      logger.info('invitationId: $invitationId', name: _logName);
      logger.info('roomId: $roomId', name: _logName);
      logger.info('inviterName: $inviterName', name: _logName);
      
      // 招待を取得
      final invitation = _storageService.invitations.firstWhere(
        (inv) => inv.id == invitationId,
        orElse: () => Invitation(
          id: '',
          roomId: '',
          inviterId: '',
          inviteeId: '',
        ),
      );
      
      if (invitation.id.isEmpty) {
        logger.error('招待が見つかりません: $invitationId', name: _logName);
        return;
      }
      
      // ダイアログを表示
      await _showInvitationDialog(context, invitation, currentUserId);
      
      logger.section('FCM招待処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('FCM招待処理エラー: $e',
          name: _logName, error: e, stackTrace: stack);
    }
  }
  
  /// 入力: [context], [invitation], [currentUserId]。
  /// 前提条件: invitation が有効で、招待者/ルーム情報を取得可能なこと。
  /// 成功時結果: ユーザー選択に応じて承認/拒否ハンドラへ遷移する。
  /// 失敗時挙動: データ不整合時はエラーログを残して終了する。
  Future<void> _showInvitationDialog(
    BuildContext context,
    Invitation invitation,
    String currentUserId,
  ) async {
    logger.section('招待ダイアログ表示', name: _logName);
    logger.info('invitationId: ${invitation.id}', name: _logName);
    logger.info('roomId: ${invitation.roomId}', name: _logName);
    
    // ルーム情報を取得
    final room = _storageService.rooms.firstWhere(
      (r) => r.id == invitation.roomId,
      orElse: () => throw Exception('ルームが見つかりません'),
    );
    
    // 招待者情報を取得
    final inviter = _storageService.users.firstWhere(
      (u) => u.id == invitation.inviterId,
      orElse: () => throw Exception('招待者が見つかりません'),
    );
    
    logger.info('roomName: ${room.topic}', name: _logName);
    logger.info('inviterName: ${inviter.displayName}', name: _logName);
    
    // ダイアログを表示
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ルーム招待'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 招待者情報
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        inviter.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inviter.displayName,
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'があなたを招待しました',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ルーム情報
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ルーム名',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            room.topic,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 説明文
              Text(
                'このルームに参加しますか？',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            // 拒否ボタン
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('拒否'),
            ),
            
            // 参加ボタン
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
              ),
              child: const Text(
                '参加する',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    
    logger.info('ユーザー選択: ${result == true ? "参加" : "拒否"}', name: _logName);
    
    if (result == true) {
      await _acceptInvitation(context, invitation);
    } else {
      await _rejectInvitation(invitation);
    }
  }
  
  /// 入力: [context], [invitation]。
  /// 前提条件: context が有効で invitation.id が存在すること。
  /// 成功時結果: ローディング表示中に承認処理を完了し、画面遷移準備状態にする。
  /// 失敗時挙動: 例外時はローディングを閉じてエラーダイアログ表示。
  Future<void> _acceptInvitation(
    BuildContext context,
    Invitation invitation,
  ) async {
    logger.section('招待承認処理開始', name: _logName);
    
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
      
      // 招待を承認
      await _invitationService.acceptInvitation(invitation.id);
      
      logger.success('招待承認完了', name: _logName);
      
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // チャット画面へ遷移
      // TODO: NavigationHelperを使用してチャット画面へ遷移
      // await NavigationHelper.toChat(context, roomId: invitation.roomId, ...);
      
      logger.section('招待承認処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('招待承認エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      
      // エラーダイアログを表示
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングを閉じる
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('エラー'),
            content: Text('招待の承認に失敗しました\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  /// 入力: [invitation]。
  /// 前提条件: 招待が pending であること。
  /// 成功時結果: 招待を拒否状態に更新する。
  /// 失敗時挙動: 例外はログ出力のみで上位には投げない。
  Future<void> _rejectInvitation(Invitation invitation) async {
    logger.section('招待拒否処理開始', name: _logName);
    
    try {
      await _invitationService.rejectInvitation(invitation.id);
      logger.success('招待拒否完了', name: _logName);
      logger.section('招待拒否処理完了', name: _logName);
    } catch (e, stack) {
      logger.error('招待拒否エラー: $e',
          name: _logName, error: e, stackTrace: stack);
    }
  }
}