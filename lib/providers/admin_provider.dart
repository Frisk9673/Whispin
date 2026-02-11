import 'dart:async';

import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../repositories/premium_counter_repository.dart';
import '../models/admin/premium_counter.dart';
import '../utils/app_logger.dart';
import '../models/admin_user/question_message.dart';
import '../services/admin/admin_question_chat_service.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final PremiumCounterRepository _counterRepository = PremiumCounterRepository();
  static const String _logName = 'AdminProvider';

  int paidMemberCount = 0;
  bool isLoading = false;

  // チャット関連
  final AdminQuestionChatService _chatService = AdminQuestionChatService();
  StreamSubscription<List<Message>>? _messageSubscription;
  List<Message> messages = [];

  // プレミアム会員数の監視用
  StreamSubscription<PremiumCounter>? _counterSubscription;

  AdminProvider({required UserRepository userRepository})
      : _userRepository = userRepository {
    _initializeProvider();
  }

  /// Providerの初期化処理
  Future<void> _initializeProvider() async {
    logger.section('AdminProvider初期化開始', name: _logName);

    // 初回ロード
    await loadPaidMemberCount();

    // リアルタイム監視開始
    _startCounterWatch();

    logger.section('AdminProvider初期化完了', name: _logName);
  }

  /// カウンターのリアルタイム監視を開始
  void _startCounterWatch() {
    logger.section('カウンター監視開始', name: _logName);

    _counterSubscription = _counterRepository.watchCounter().listen(
      (counter) {
        final newCount = counter.count;

        if (paidMemberCount != newCount) {
          logger.info('プレミアム会員数変更: $paidMemberCount → $newCount',
              name: _logName);
          paidMemberCount = newCount;
          isLoading = false;
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

  /// カウンターから有料会員数を取得
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

  /// カウンターを再計算（管理者の手動補正時に使用）
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

  /// チャットを「対応済」にする
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

  /// チャットを「対応中」にする
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

  /// チャットを「未対応」に戻す
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
    _counterSubscription?.cancel();
    super.dispose();
  }
}
