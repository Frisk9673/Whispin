import 'dart:async';

import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../utils/app_logger.dart';
import '../models/question_message.dart';
import '../services/admin_question_chat_service.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  static const String _logName = 'AdminProvider';

  int paidMemberCount = 0;
  bool isLoading = false;

  // ===== チャット用 =====
  final AdminQuestionChatService _chatService = AdminQuestionChatService();
  StreamSubscription<List<Message>>? _messageSubscription;
  List<Message> messages = [];

  // ✅ 追加: プレミアム会員監視用
  StreamSubscription? _premiumUsersSubscription;

  AdminProvider({required UserRepository userRepository})
      : _userRepository = userRepository {
    loadPaidMemberCount();
    _startPremiumUsersWatch(); // ✅ 追加
  }

  /// ✅ 追加: プレミアム会員数のリアルタイム監視を開始
  void _startPremiumUsersWatch() {
    logger.section('プレミアム会員監視開始', name: _logName);

    _premiumUsersSubscription = _userRepository.watchPremiumUsers().listen(
      (users) {
        final newCount = users.length;

        if (paidMemberCount != newCount) {
          logger.info('プレミアム会員数変更: $paidMemberCount → $newCount',
              name: _logName);
          paidMemberCount = newCount;
          notifyListeners();
        }
      },
      onError: (e, stack) {
        logger.error('プレミアム会員監視エラー: $e',
            name: _logName, error: e, stackTrace: stack);
      },
    );

    logger.success('プレミアム会員監視開始完了', name: _logName);
  }

  /// 有料会員数を取得して状態を更新
  Future<void> loadPaidMemberCount() async {
    logger.section('loadPaidMemberCount() 開始', name: _logName);

    isLoading = true;
    notifyListeners();

    try {
      final count = await _userRepository.countPremiumUsers();
      paidMemberCount = count;
      logger.success('有料会員数取得完了: $count 人', name: _logName);
    } catch (e, stack) {
      logger.error('loadPaidMemberCount エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      paidMemberCount = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }

    logger.section('loadPaidMemberCount() 完了', name: _logName);
  }

  /// ===== チャット機能 =====

  /// 特定チャットのメッセージストリーム監視開始
  void startMessageStream(String chatId) {
    // 既存の購読があればキャンセル
    _messageSubscription?.cancel();

    _messageSubscription = _chatService.messageStream(chatId).listen((event) {
      messages = event;
      notifyListeners();
    });
  }

  /// メッセージ送信（管理者）
  Future<void> sendMessage(String chatId, String text) async {
    await _chatService.sendMessage(chatId: chatId, text: text);
  }

  /// チャット担当者割り当て（必要に応じて）
  Future<void> assignAdmin(String chatId, String adminId) async {
    await _chatService.assignAdmin(chatId, adminId);
  }

  /// 未読メッセージを既読にする（任意）
  Future<void> markMessagesAsRead(String chatId) async {
    await _chatService.markMessagesAsRead(chatId);
  }

  /// ✅ 新規追加: チャットを「対応済」にする
  Future<void> markAsResolved(String chatId) async {
    logger.section('markAsResolved() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      await _chatService.markAsResolved(chatId);
      logger.success('チャットを「対応済」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsResolved() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ✅ 新規追加: チャットを「対応中」にする
  Future<void> markAsInProgress(String chatId) async {
    logger.section('markAsInProgress() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      await _chatService.markAsInProgress(chatId);
      logger.success('チャットを「対応中」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsInProgress() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ✅ 新規追加: チャットを「未対応」に戻す
  Future<void> markAsPending(String chatId) async {
    logger.section('markAsPending() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      await _chatService.markAsPending(chatId);
      logger.success('チャットを「未対応」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsPending() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 購読解除（画面破棄時に呼ぶ）
  void disposeMessageStream() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  /// 外部から明示的に再読み込みするための別名
  Future<void> refresh() async {
    logger.info('refresh() - 再読み込みを開始', name: _logName);
    await loadPaidMemberCount();
  }

  @override
  void dispose() {
    disposeMessageStream();
    _premiumUsersSubscription?.cancel(); // ✅ 追加
    super.dispose();
  }
}
