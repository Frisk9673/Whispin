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

  AdminProvider({required UserRepository userRepository})
      : _userRepository = userRepository {
    loadPaidMemberCount();
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

    _messageSubscription =
        _chatService.messageStream(chatId).listen((event) {
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
    super.dispose();
  }
}
