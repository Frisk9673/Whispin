import 'dart:async';
import '../models/invitation.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import 'storage_service.dart';

/// 招待機能を管理するサービス
/// 
/// ユーザーがルームに他のユーザーを招待する機能を提供します。
/// 招待の送信、承認、拒否、有効期限の管理を行います。
class InvitationService {
  final StorageService _storageService;

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
    print('📨 [InvitationService] 招待送信開始');
    print('   roomId: $roomId');
    print('   inviter: $inviterId');
    print('   invitee: $inviteeId');

    // === バリデーション ===

    // 1. ルームが存在するか
    final room = _storageService.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw Exception('ルームが見つかりません'),
    );

    // 2. ルームが満員でないか（id1とid2が両方埋まっている）
    if ((room.id1?.isNotEmpty ?? false) && (room.id2?.isNotEmpty ?? false)) {
      throw Exception('ルームは満員です');
    }

    // 3. 招待者がルームのメンバーか
    if (room.id1 != inviterId && room.id2 != inviterId) {
      throw Exception('招待者はこのルームのメンバーではありません');
    }

    // 4. 被招待者が既にルームのメンバーでないか
    if (room.id1 == inviteeId || room.id2 == inviteeId) {
      throw Exception('このユーザーは既にルームに参加しています');
    }

    // 5. 被招待者への未承認の招待が既に存在しないか
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
      throw Exception('このユーザーへの招待が既に存在します');
    }

    // === 招待の作成 ===

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

    print('✅ [InvitationService] 招待送信完了: ${invitation.id}');

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
    print('✅ [InvitationService] 招待承認開始: $invitationId');

    // === 招待の取得 ===

    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];

    // === バリデーション ===

    // 1. ペンディング状態か
    if (invitation.status != 'pending') {
      throw Exception('この招待は既に処理されています');
    }

    // 2. 有効期限内か
    if (invitation.isExpired) {
      throw Exception('この招待は期限切れです');
    }

    // 3. ルームが存在するか
    final roomIndex = _storageService.rooms.indexWhere(
      (r) => r.id == invitation.roomId,
    );

    if (roomIndex == -1) {
      throw Exception('ルームが見つかりません');
    }

    final room = _storageService.rooms[roomIndex];

    // 4. ルームに空きがあるか
    ChatRoom updatedRoom;

    if (room.id1?.isEmpty ?? true) {
      updatedRoom = room.copyWith(id1: invitation.inviteeId);
    } else if (room.id2?.isEmpty ?? true) {
      updatedRoom = room.copyWith(id2: invitation.inviteeId);
    } else {
      throw Exception('ルームは満員です');
    }

    // === 更新処理 ===

    // ルームを更新
    _storageService.rooms[roomIndex] = updatedRoom;

    // 招待を承認済みに更新
    _storageService.invitations[invitationIndex] = invitation.copyWith(
      status: 'accepted',
      respondedAt: DateTime.now(),
    );

    await _storageService.save();

    print('✅ [InvitationService] 招待承認完了: ${updatedRoom.id}');

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
    print('❌ [InvitationService] 招待拒否開始: $invitationId');

    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];

    if (invitation.status != 'pending') {
      throw Exception('この招待は既に処理されています');
    }

    _storageService.invitations[invitationIndex] = invitation.copyWith(
      status: 'rejected',
      respondedAt: DateTime.now(),
    );

    await _storageService.save();

    print('✅ [InvitationService] 招待拒否完了: $invitationId');
  }

  // ===== 招待の取得 =====

  /// 特定ユーザーが受け取った招待一覧を取得（ペンディングのみ）
  List<Invitation> getReceivedInvitations(String userId) {
    return _storageService.invitations
        .where((inv) => inv.inviteeId == userId && inv.status == 'pending')
        .where((inv) => !inv.isExpired) // 期限切れを除外
        .toList();
  }

  /// 特定ユーザーが送信した招待一覧を取得
  List<Invitation> getSentInvitations(String userId) {
    return _storageService.invitations
        .where((inv) => inv.inviterId == userId)
        .toList();
  }

  /// 特定ルームへの招待一覧を取得（ペンディングのみ）
  List<Invitation> getRoomInvitations(String roomId) {
    return _storageService.invitations
        .where((inv) => inv.roomId == roomId && inv.status == 'pending')
        .toList();
  }

  // ===== 期限切れ招待のクリーンアップ =====

  /// 期限切れの招待を自動的に expired 状態に更新
  Future<void> cleanupExpiredInvitations() async {
    print('🧹 [InvitationService] 期限切れ招待のクリーンアップ開始');

    bool hasUpdates = false;

    for (int i = 0; i < _storageService.invitations.length; i++) {
      final invitation = _storageService.invitations[i];

      if (invitation.status == 'pending' && invitation.isExpired) {
        _storageService.invitations[i] = invitation.copyWith(
          status: 'expired',
          respondedAt: DateTime.now(),
        );
        hasUpdates = true;
        print('   期限切れ: ${invitation.id}');
      }
    }

    if (hasUpdates) {
      await _storageService.save();
      print('✅ [InvitationService] クリーンアップ完了');
    } else {
      print('   期限切れの招待はありません');
    }
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
    print('🚫 [InvitationService] 招待キャンセル開始: $invitationId');

    final invitationIndex = _storageService.invitations.indexWhere(
      (inv) => inv.id == invitationId,
    );

    if (invitationIndex == -1) {
      throw Exception('招待が見つかりません');
    }

    final invitation = _storageService.invitations[invitationIndex];

    if (invitation.inviterId != inviterId) {
      throw Exception('この招待をキャンセルする権限がありません');
    }

    if (invitation.status != 'pending') {
      throw Exception('この招待は既に処理されています');
    }

    // 招待を削除（または expired 状態に更新）
    _storageService.invitations.removeAt(invitationIndex);
    await _storageService.save();

    print('✅ [InvitationService] 招待キャンセル完了: $invitationId');
  }
}