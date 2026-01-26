import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invitation.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../models/friendship.dart';
import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../extensions/context_extensions.dart';
import 'storage_service.dart';
import '../utils/app_logger.dart';

/// 招待機能を管理するサービス（UI拡張版）
///
/// ユーザーがルームに他のユーザーを招待する機能を提供します。
/// 招待の送信、承認、拒否、有効期限の管理を行います。
class InvitationService {
  final StorageService _storageService;
  static const String _logName = 'InvitationService';

  InvitationService(this._storageService);

  // ===== 招待の作成 =====

  /// 招待を送信
  ///
  /// [roomId] 招待先のルームID
  /// [inviterId] 招待者のユーザーID
  /// [inviteeId] 招待されるユーザーID
  ///
  /// 戻り値: 作成された Invitation
  ///
  /// エラー:
  /// - ルームが存在しない
  /// - ルームが満員
  /// - 招待者がルームのメンバーでない
  /// - 被招待者が既にルームのメンバー
  /// - 被招待者へのペンディング招待が既に存在
  Future<Invitation> sendInvitation({
    required String roomId,
    required String inviterId,
    required String inviteeId,
  }) async {
    logger.section('sendInvitation() 開始', name: _logName);
    logger.info('roomId: $roomId', name: _logName);
    logger.info('inviter: $inviterId', name: _logName);
    logger.info('invitee: $inviteeId', name: _logName);

    // === バリデーション ===

    // 1. ルームが存在するか
    logger.start('ルーム存在チェック中...', name: _logName);
    final room = _storageService.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw Exception('ルームが見つかりません'),
    );
    logger.success('ルーム発見: ${room.topic}', name: _logName);

    // 2. ルームが満員でないか（id1とid2が両方埋まっている）
    if ((room.id1?.isNotEmpty ?? false) && (room.id2?.isNotEmpty ?? false)) {
      logger.error('ルームは満員です', name: _logName);
      logger.info('  id1: ${room.id1}', name: _logName);
      logger.info('  id2: ${room.id2}', name: _logName);
      throw Exception('ルームは満員です');
    }
    logger.success('ルームに空きあり', name: _logName);

    // 3. 招待者がルームのメンバーか
    if (room.id1 != inviterId && room.id2 != inviterId) {
      logger.error('招待者はこのルームのメンバーではありません', name: _logName);
      logger.info('  room.id1: ${room.id1}', name: _logName);
      logger.info('  room.id2: ${room.id2}', name: _logName);
      logger.info('  inviter: $inviterId', name: _logName);
      throw Exception('招待者はこのルームのメンバーではありません');
    }
    logger.success('招待者がルームメンバーであることを確認', name: _logName);

    // 4. 被招待者が既にルームのメンバーでないか
    if (room.id1 == inviteeId || room.id2 == inviteeId) {
      logger.error('このユーザーは既にルームに参加しています', name: _logName);
      throw Exception('このユーザーは既にルームに参加しています');
    }
    logger.success('被招待者は未参加を確認', name: _logName);

    // 5. 被招待者への未承認の招待が既に存在しないか
    logger.start('既存の招待をチェック中...', name: _logName);
    final existingInvitation = _storageService.invitations.firstWhere(
      (inv) =>
          inv.roomId == roomId &&
          inv.inviteeId == inviteeId &&
          inv.status == 'pending',
      orElse: () => Invitation(
        id: '',
        roomId: '',
        inviterId: '',
        inviteeId: '',
      ),
    );

    if (existingInvitation.id.isNotEmpty) {
      logger.error('このユーザーへの招待が既に存在します', name: _logName);
      logger.info('  既存招待ID: ${existingInvitation.id}', name: _logName);
      throw Exception('このユーザーへの招待が既に存在します');
    }
    logger.success('重複招待なし', name: _logName);

    // === 招待の作成 ===

    logger.start('新しい招待を作成中...', name: _logName);
    final invitation = Invitation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      inviterId: inviterId,
      inviteeId: inviteeId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _storageService.invitations.add(invitation);
    await _storageService.save();

    logger.success('招待送信完了: ${invitation.id}', name: _logName);
    logger.info('  有効期限: ${invitation.expiresAt}', name: _logName);
    logger.section('sendInvitation() 完了', name: _logName);

    return invitation;
  }

  // ===== 招待の承認 =====

  /// 招待を承認してルームに参加
  ///
  /// [invitationId] 招待ID
  ///
  /// 戻り値: 更新された ChatRoom
  ///
  /// エラー:
  /// - 招待が見つからない
  /// - 招待が既に処理済み
  /// - 招待が期限切れ
  /// - ルームが満員
  /// - ルームが存在しない
  Future<ChatRoom> acceptInvitation(String invitationId) async {
    logger.section('acceptInvitation() 開始', name: _logName);
    logger.info('invitationId: $invitationId', name: _logName);

    // === 招待の取得 ===

    logger.start('招待を検索中...', name: _logName);
    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      logger.error('招待が見つかりません', name: _logName);
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];
    logger.success('招待発見', name: _logName);
    logger.info('  招待者: ${invitation.inviterId}', name: _logName);
    logger.info('  被招待者: ${invitation.inviteeId}', name: _logName);
    logger.info('  ルームID: ${invitation.roomId}', name: _logName);
    logger.info('  ステータス: ${invitation.status}', name: _logName);

    // === バリデーション ===

    // 1. ペンディング状態か
    if (invitation.status != 'pending') {
      logger.error('この招待は既に処理されています', name: _logName);
      logger.info('  現在のステータス: ${invitation.status}', name: _logName);
      throw Exception('この招待は既に処理されています');
    }
    logger.success('ステータス確認: pending', name: _logName);

    // 2. 有効期限内か
    if (invitation.isExpired) {
      logger.error('この招待は期限切れです', name: _logName);
      logger.info('  期限: ${invitation.expiresAt}', name: _logName);
      logger.info('  現在時刻: ${DateTime.now()}', name: _logName);
      throw Exception('この招待は期限切れです');
    }
    logger.success('有効期限内', name: _logName);

    // 3. ルームが存在するか
    logger.start('ルームを検索中...', name: _logName);
    final roomIndex = _storageService.rooms.indexWhere(
      (r) => r.id == invitation.roomId,
    );

    if (roomIndex == -1) {
      logger.error('ルームが見つかりません', name: _logName);
      throw Exception('ルームが見つかりません');
    }

    final room = _storageService.rooms[roomIndex];
    logger.success('ルーム発見: ${room.topic}', name: _logName);

    // 4. ルームに空きがあるか
    ChatRoom updatedRoom;
    final now = DateTime.now();

    if (room.id1?.isEmpty ?? true) {
      logger.info('id1 スロットに参加します', name: _logName);
      updatedRoom = room.copyWith(
        id1: invitation.inviteeId,
        status: 1, // ← ★ここを追加
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 10)), // ★これ
      );
    } else if (room.id2?.isEmpty ?? true) {
      logger.info('id2 スロットに参加します', name: _logName);
      updatedRoom = room.copyWith(
        id2: invitation.inviteeId,
        status: 1, // ← ★ここを追加
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 10)), // ★これ
      );
    } else {
      logger.error('ルームは満員です', name: _logName);
      logger.info('  id1: ${room.id1}', name: _logName);
      logger.info('  id2: ${room.id2}', name: _logName);
      throw Exception('ルームは満員です');
    }

    // === 更新処理 ===

    logger.start('ルームとインビテーションを更新中...', name: _logName);

    // ルームを更新
    _storageService.rooms[roomIndex] = updatedRoom;
    logger.success('ルーム更新完了', name: _logName);

    // 招待を承認済みに更新
    _storageService.invitations[invitationIndex] = invitation.copyWith(
      status: 'accepted',
      respondedAt: DateTime.now(),
    );
    logger.success('招待ステータス更新: accepted', name: _logName);

    await _storageService.save();
    logger.success('データ保存完了', name: _logName);

    logger.section('acceptInvitation() 完了', name: _logName);

    return updatedRoom;
  }

  // ===== 招待の拒否 =====

  /// 招待を拒否
  ///
  /// [invitationId] 招待ID
  ///
  /// エラー:
  /// - 招待が見つからない
  /// - 招待が既に処理済み
  Future<void> rejectInvitation(String invitationId) async {
    logger.section('rejectInvitation() 開始', name: _logName);
    logger.info('invitationId: $invitationId', name: _logName);

    logger.start('招待を検索中...', name: _logName);
    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      logger.error('招待が見つかりません', name: _logName);
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];
    logger.success('招待発見', name: _logName);

    if (invitation.status != 'pending') {
      logger.error('この招待は既に処理されています', name: _logName);
      logger.info('  現在のステータス: ${invitation.status}', name: _logName);
      throw Exception('この招待は既に処理されています');
    }

    logger.start('招待を拒否中...', name: _logName);
    _storageService.invitations[invitationIndex] = invitation.copyWith(
      status: 'rejected',
      respondedAt: DateTime.now(),
    );

    await _storageService.save();

    logger.success('招待拒否完了: $invitationId', name: _logName);
    logger.section('rejectInvitation() 完了', name: _logName);
  }

  // ===== 招待の取得 =====

  /// 特定ユーザーが受け取った招待一覧を取得（ペンディングのみ）
  List<Invitation> getReceivedInvitations(String userId) {
    logger.debug('getReceivedInvitations() - userId: $userId', name: _logName);

    final invitations = _storageService.invitations
        .where((inv) => inv.inviteeId == userId && inv.status == 'pending')
        .where((inv) => !inv.isExpired)
        .toList();

    logger.debug('受信招待数: ${invitations.length}件', name: _logName);
    return invitations;
  }

  /// 特定ユーザーが送信した招待一覧を取得
  List<Invitation> getSentInvitations(String userId) {
    logger.debug('getSentInvitations() - userId: $userId', name: _logName);

    final invitations = _storageService.invitations
        .where((inv) => inv.inviterId == userId)
        .toList();

    logger.debug('送信招待数: ${invitations.length}件', name: _logName);
    return invitations;
  }

  /// 特定ルームへの招待一覧を取得（ペンディングのみ）
  List<Invitation> getRoomInvitations(String roomId) {
    logger.debug('getRoomInvitations() - roomId: $roomId', name: _logName);

    final invitations = _storageService.invitations
        .where((inv) => inv.roomId == roomId && inv.status == 'pending')
        .toList();

    logger.debug('ルーム招待数: ${invitations.length}件', name: _logName);
    return invitations;
  }

  // ===== 期限切れ招待のクリーンアップ =====

  /// 期限切れの招待を自動的に expired 状態に更新
  Future<void> cleanupExpiredInvitations() async {
    logger.section('cleanupExpiredInvitations() 開始', name: _logName);

    bool hasUpdates = false;
    int expiredCount = 0;

    for (int i = 0; i < _storageService.invitations.length; i++) {
      final invitation = _storageService.invitations[i];

      if (invitation.status == 'pending' && invitation.isExpired) {
        _storageService.invitations[i] = invitation.copyWith(
          status: 'expired',
          respondedAt: DateTime.now(),
        );
        hasUpdates = true;
        expiredCount++;
        logger.info('期限切れ: ${invitation.id}', name: _logName);
      }
    }

    if (hasUpdates) {
      await _storageService.save();
      logger.success('クリーンアップ完了: $expiredCount件更新', name: _logName);
    } else {
      logger.info('期限切れの招待はありません', name: _logName);
    }

    logger.section('cleanupExpiredInvitations() 完了', name: _logName);
  }

  // ===== 招待のキャンセル =====

  /// 招待をキャンセル（招待者のみ可能）
  ///
  /// [invitationId] 招待ID
  /// [inviterId] 招待者のユーザーID（確認用）
  ///
  /// エラー:
  /// - 招待が見つからない
  /// - 招待者が一致しない
  /// - 招待が既に処理済み
  Future<void> cancelInvitation(String invitationId, String inviterId) async {
    logger.section('cancelInvitation() 開始', name: _logName);
    logger.info('invitationId: $invitationId', name: _logName);
    logger.info('inviterId: $inviterId', name: _logName);

    logger.start('招待を検索中...', name: _logName);
    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      logger.error('招待が見つかりません', name: _logName);
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];
    logger.success('招待発見', name: _logName);

    if (invitation.inviterId != inviterId) {
      logger.error('この招待をキャンセルする権限がありません', name: _logName);
      logger.info('  invitation.inviterId: ${invitation.inviterId}',
          name: _logName);
      logger.info('  要求者ID: $inviterId', name: _logName);
      throw Exception('この招待をキャンセルする権限がありません');
    }

    if (invitation.status != 'pending') {
      logger.error('この招待は既に処理されています', name: _logName);
      logger.info('  現在のステータス: ${invitation.status}', name: _logName);
      throw Exception('この招待は既に処理されています');
    }

    logger.start('招待を削除中...', name: _logName);
    _storageService.invitations.removeAt(invitationIndex);
    await _storageService.save();

    logger.success('招待キャンセル完了: $invitationId', name: _logName);
    logger.section('cancelInvitation() 完了', name: _logName);
  }

  // ===== UI関連メソッド（新規追加） =====

  /// フレンド招待ダイアログを表示
  ///
  /// [context] ビルドコンテキスト
  /// [roomId] ルームID
  /// [currentUserId] 現在のユーザーID
  Future<void> showInviteFriendDialog({
    required BuildContext context,
    required String roomId,
    required String currentUserId,
  }) async {
    logger.section('フレンド招待ダイアログ表示', name: _logName);

    if (currentUserId.isEmpty) {
      context.showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    // フレンド一覧を取得
    final friendships = _storageService.friendships.where((f) {
      return f.active &&
          (f.userId == currentUserId || f.friendId == currentUserId);
    }).toList();

    if (friendships.isEmpty) {
      context.showInfoSnackBar('招待できるフレンドがいません');
      return;
    }

    // フレンドのユーザー情報を取得
    final friends = <Map<String, String>>[];
    for (var friendship in friendships) {
      final friendId = friendship.userId == currentUserId
          ? friendship.friendId
          : friendship.userId;

      final friendUser = _storageService.users.firstWhere(
        (u) => u.id == friendId,
        orElse: () => throw Exception('フレンドが見つかりません'),
      );

      friends.add({
        'id': friendId,
        'name': friendUser.displayName,
      });
    }

    logger.info('招待可能なフレンド数: ${friends.length}', name: _logName);

    // ダイアログ表示
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
                Icons.person_add,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('フレンドを招待'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      friend['name']![0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    friend['name']!,
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // ① 先にローディングを表示（contextがまだ生きている）
                      context.showLoadingDialog(message: '招待を送信中...');

                      // ② フレンド選択ダイアログを閉じる
                      Navigator.pop(dialogContext);

                      // ③ 招待処理（※ dialog は一切触らない）
                      await _sendInvitationWithUI(
                        context: context,
                        roomId: roomId,
                        currentUserId: currentUserId,
                        friendId: friend['id']!,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '招待',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 招待を送信（UI付き）
  ///
  /// [context] ビルドコンテキスト
  /// [roomId] ルームID
  /// [currentUserId] 現在のユーザーID
  /// [friendId] 招待するフレンドのID
  Future<void> _sendInvitationWithUI({
    required BuildContext context,
    required String roomId,
    required String currentUserId,
    required String friendId,
  }) async {
    logger.section('招待送信処理開始', name: _logName);
    logger.info('招待先フレンド: $friendId', name: _logName);

    try {
      await sendInvitation(
        roomId: roomId,
        inviterId: currentUserId,
        inviteeId: friendId,
      );

      if (!context.mounted) return;
      context.showSuccessSnackBar('招待を送信しました！');
      logger.success('招待送信完了', name: _logName);
    } catch (e, stack) {
      logger.error('招待送信エラー: $e', name: _logName, error: e, stackTrace: stack);

      if (!context.mounted) return;
      context.showErrorSnackBar('招待の送信に失敗しました: $e');
    } finally {
      if (context.mounted) {
        context.hideLoadingDialog(); // ← 必ず閉じる
      }
    }
  }
}
