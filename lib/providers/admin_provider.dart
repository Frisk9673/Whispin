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

  // ===== 管理対象state一覧 =====
  // paidMemberCount: プレミアム会員数表示に使う集計値。
  // isLoading: 管理画面のローディング表示制御。
  // messages: 選択中チャットのメッセージ一覧。
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
  /// state変更: 監視イベント受信時に paidMemberCount/isLoading を更新。
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
          // 会員数表示とローディング表示を同期して再描画する。
          notifyListeners();
        }
      },
      onError: (e, stack) {
        logger.error('カウンター監視エラー: $e',
            name: _logName, error: e, stackTrace: stack);
        isLoading = false;
        // 監視エラー後にローディング解除をUIへ反映する。
        notifyListeners();
      },
    );

    logger.success('カウンター監視開始完了', name: _logName);
  }

  /// カウンターから有料会員数を取得
  /// state変更:
  /// - 開始時: isLoading=true
  /// - 成功時: paidMemberCount 更新
  /// - 終了時: isLoading=false
  Future<void> loadPaidMemberCount() async {
    logger.section('loadPaidMemberCount() 開始', name: _logName);

    isLoading = true;
    // ローディング開始を即時表示する。
    notifyListeners();

    try {
      // Repository境界: 会員数カウンターの取得はRepositoryへ委譲する。
      final counter = await _counterRepository.getCounter();
      paidMemberCount = counter.count;
      logger.success('有料会員数取得完了: ${counter.count} 人', name: _logName);
    } catch (e, stack) {
      logger.error('loadPaidMemberCount エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      paidMemberCount = 0;
    } finally {
      isLoading = false;
      // 取得完了後の会員数/ローディング状態を再描画する。
      notifyListeners();
    }

    logger.section('loadPaidMemberCount() 完了', name: _logName);
  }

  /// カウンターを再計算（管理者の手動補正時に使用）
  /// state変更:
  /// - 開始時: isLoading=true
  /// - 成功時: paidMemberCount 更新
  /// - 終了時: isLoading=false
  Future<void> recalculateCounter() async {
    logger.section('カウンター再計算開始', name: _logName);

    isLoading = true;
    // 再計算処理中であることをUIへ通知する。
    notifyListeners();

    try {
      // Repository境界: 再計算ロジックはRepository側で実行する。
      final counter = await _counterRepository.recalculate();
      paidMemberCount = counter.count;
      logger.success('カウンター再計算完了: ${counter.count} 人', name: _logName);
    } catch (e, stack) {
      logger.error('カウンター再計算エラー: $e',
          name: _logName, error: e, stackTrace: stack);
    } finally {
      isLoading = false;
      // 再計算後の会員数とローディング状態を反映する。
      notifyListeners();
    }

    logger.section('カウンター再計算完了', name: _logName);
  }

  /// ===== チャット機能 =====

  /// 特定チャットのメッセージストリーム監視開始
  /// state変更: 受信ごとに messages を最新化。
  void startMessageStream(String chatId) {
    // 既存の購読があればキャンセル
    _messageSubscription?.cancel();

    // Service境界: チャットの購読開始はServiceへ委譲する。
    _messageSubscription = _chatService.messageStream(chatId).listen((event) {
      messages = event;
      // 最新メッセージ一覧をチャット画面へ反映する。
      notifyListeners();
    });
  }

  /// メッセージ送信（管理者）
  /// state変更: Provider内stateは変更しない（送信処理のみ）。
  Future<void> sendMessage(String chatId, String text) async {
    // Service境界: 送信処理はServiceへ委譲する。
    await _chatService.sendMessage(chatId: chatId, text: text);
  }

  /// チャット担当者割り当て（必要に応じて）
  /// state変更: Provider内stateは変更しない（割り当て処理のみ）。
  Future<void> assignAdmin(String chatId, String adminId) async {
    // Service境界: 担当者割り当てはServiceへ委譲する。
    await _chatService.assignAdmin(chatId, adminId);
  }

  /// 未読メッセージを既読にする（任意）
  /// state変更: Provider内stateは変更しない（既読更新処理のみ）。
  Future<void> markMessagesAsRead(String chatId) async {
    // Service境界: 既読更新はServiceへ委譲する。
    await _chatService.markMessagesAsRead(chatId);
  }

  /// チャットを「対応済」にする
  /// state変更: Provider内stateは変更しない（状態遷移処理のみ）。
  Future<void> markAsResolved(String chatId) async {
    logger.section('markAsResolved() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      // Service境界: チャット状態更新はServiceへ委譲する。
      await _chatService.markAsResolved(chatId);
      logger.success('チャットを「対応済」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsResolved() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// チャットを「対応中」にする
  /// state変更: Provider内stateは変更しない（状態遷移処理のみ）。
  Future<void> markAsInProgress(String chatId) async {
    logger.section('markAsInProgress() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      // Service境界: チャット状態更新はServiceへ委譲する。
      await _chatService.markAsInProgress(chatId);
      logger.success('チャットを「対応中」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsInProgress() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// チャットを「未対応」に戻す
  /// state変更: Provider内stateは変更しない（状態遷移処理のみ）。
  Future<void> markAsPending(String chatId) async {
    logger.section('markAsPending() 開始', name: _logName);
    logger.info('chatId: $chatId', name: _logName);

    try {
      // Service境界: チャット状態更新はServiceへ委譲する。
      await _chatService.markAsPending(chatId);
      logger.success('チャットを「未対応」に変更しました', name: _logName);
    } catch (e, stack) {
      logger.error('markAsPending() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 購読解除（画面破棄時に呼ぶ）
  /// state変更: _messageSubscription を破棄し、購読中stateを解除。
  void disposeMessageStream() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  /// 外部から明示的に再読み込みするための別名
  /// state変更: loadPaidMemberCount() と同じ state を更新。
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
