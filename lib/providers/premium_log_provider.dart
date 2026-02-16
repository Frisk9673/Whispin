import 'package:flutter/material.dart';
import '../models/admin/premium_log_model.dart';
import '../services/user/premium_log_service.dart';
import '../utils/app_logger.dart';

class PremiumLogProvider extends ChangeNotifier {
  final PremiumLogService _service = PremiumLogService();
  static const String _logName = 'PremiumLogProvider';

  // ===== 管理対象state一覧 =====
  // logs: 画面表示対象のプレミアム契約ログ一覧。
  // isLoading: ログ取得・絞り込み中のローディング状態。
  List<PremiumLog> logs = [];
  bool isLoading = false;

  /// 初期ロード / 全件ロード
  /// state変更:
  /// - 開始時: isLoading=true
  /// - 成功時: logs 更新
  /// - 終了時: isLoading=false
  Future<void> loadAllLogs() async {
    logger.section('loadAllLogs() 開始', name: _logName);

    isLoading = true;
    logger.debug('isLoading = true -> notifyListeners()', name: _logName);
    // ローディング表示を開始するため再描画する。
    notifyListeners();

    // Service境界: ログ取得はServiceへ委譲する。
    logs = await _service.fetchLogs();
    logger.info('取得件数: ${logs.length} 件', name: _logName);

    isLoading = false;
    logger.debug('isLoading = false -> notifyListeners()', name: _logName);
    // 取得結果とローディング解除を画面へ反映する。
    notifyListeners();

    logger.section('loadAllLogs() 完了', name: _logName);
  }

  /// メールアドレスでフィルタ（空欄なら全件）
  /// state変更:
  /// - 開始時: isLoading=true
  /// - 成功時: logs 更新
  /// - 終了時: isLoading=false
  Future<void> filterByEmail(String? email) async {
    logger.section('filterByEmail() 開始', name: _logName);
    logger.info('入力された email: "$email"', name: _logName);

    isLoading = true;
    logger.debug('isLoading = true -> notifyListeners()', name: _logName);
    // フィルタ処理開始を画面へ反映する。
    notifyListeners();

    if (email == null || email.isEmpty) {
      logger.info('メール未入力なので全件取得します', name: _logName);
      // Service境界: 全件取得はServiceへ委譲する。
      logs = await _service.fetchLogs();
    } else {
      logger.info('メール "$email" のログを取得します', name: _logName);
      // Service境界: 条件付き取得はServiceへ委譲する。
      logs = await _service.fetchLogsByEmail(email);
    }

    logger.info('取得件数: ${logs.length} 件', name: _logName);

    isLoading = false;
    logger.debug('isLoading = false -> notifyListeners()', name: _logName);
    // フィルタ結果とローディング解除を画面へ反映する。
    notifyListeners();

    logger.section('filterByEmail() 完了', name: _logName);
  }
}
