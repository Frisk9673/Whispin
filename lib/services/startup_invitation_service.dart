import 'package:flutter/material.dart';
import '../models/invitation.dart';
import '../services/invitation_service.dart';
import '../services/fcm_service.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/app_logger.dart';

/// アプリ起動時の招待チェックと確認ダイアログ表示
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
  
  /// アプリ起動時に招待をチェックして処理
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
  
  /// FCMから受信した招待を処理
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
  
  /// 招待確認ダイアログを表示
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
  
  /// 招待を承認してルームに参加
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
  
  /// 招待を拒否
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