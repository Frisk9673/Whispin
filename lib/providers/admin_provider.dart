import 'dart:async';

import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../repositories/premium_counter_repository.dart'; // ✅ 追加
import '../models/premium_counter.dart'; // ✅ 追加
import '../utils/app_logger.dart';
import '../models/question_message.dart';
import '../services/admin_question_chat_service.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final PremiumCounterRepository _counterRepository =
      PremiumCounterRepository(); // ✅ 追加
  static const String _logName = 'AdminProvider';

  int paidMemberCount = 0;
  bool isLoading = false;

  // ===== チャット用 =====
  final AdminQuestionChatService _chatService = AdminQuestionChatService();
  StreamSubscription<List<Message>>? _messageSubscription;
  List<Message> messages = [];

  // ✅ 修正: カウンター監視用
  StreamSubscription<PremiumCounter>? _counterSubscription;

  AdminProvider({required UserRepository userRepository})
      : _userRepository = userRepository {
    _initializeProvider();
  }

  /// ✅ 追加: Provider初期化処理
  Future<void> _initializeProvider() async {
    logger.section('AdminProvider初期化開始', name: _logName);

    // 有料会員数ロード
    await loadPaidMemberCount();

    // リアルタイム監視開始
    _startCounterWatch();

    logger.section('AdminProvider初期化完了', name: _logName);
  }

  /// ✅ 修正: カウンターのリアルタイム監視を開始
  void _startCounterWatch() {
    logger.section('カウンター監視開始', name: _logName);

    _counterSubscription = _counterRepository.watchCounter().listen(
      (counter) {
        final newCount = counter.count;

        if (paidMemberCount != newCount) {
          logger.info('プレミアム会員数変更: $paidMemberCount → $newCount',
              name: _logName);
          paidMemberCount = newCount;
          isLoading = false; // ✅ ロード完了
          notifyListeners();
        }
      },
      onError: (e, stack) {
        logger.error('カウンター監視エラー: $e',
            name: _logName, error: e, stackTrace: stack);
        isLoading = false;
        notifyListeners();
      },
    );

    logger.success('カウンター監視開始完了', name: _logName);
  }

  /// ✅ 修正: カウンターから有料会員数を取得
  Future<void> loadPaidMemberCount() async {
    logger.section('loadPaidMemberCount() 開始', name: _logName);

    isLoading = true;
    notifyListeners();

    try {
      final counter = await _counterRepository.getCounter();
      paidMemberCount = counter.count;
      logger.success('有料会員数取得完了: ${counter.count} 人', name: _logName);
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

  /// ✅ 追加: カウンターを再計算（管理者が手動で修正する場合）
  Future<void> recalculateCounter() async {
    logger.section('カウンター再計算開始', name: _logName);

    isLoading = true;
    notifyListeners();

    try {
      final counter = await _counterRepository.recalculate();
      paidMemberCount = counter.count;
      logger.success('カウンター再計算完了: ${counter.count} 人', name: _logName);
    } catch (e, stack) {
      logger.error('カウンター再計算エラー: $e',
          name: _logName, error: e, stackTrace: stack);
    } finally {
      isLoading = false;
      notifyListeners();
    }

    logger.section('カウンター再計算完了', name: _logName);
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
    _counterSubscription?.cancel(); // ✅ 修正
    super.dispose();
  }
}
