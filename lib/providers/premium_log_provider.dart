import 'package:flutter/material.dart';
import '../models/premium_log_model.dart';
import '../services/premium_log_service.dart';

class PremiumLogProvider extends ChangeNotifier {
  final PremiumLogService _service = PremiumLogService();

  List<PremiumLog> logs = [];
  bool isLoading = false;

  /// 初期ロード / 全件ロード
  Future<void> loadAllLogs() async {
    print('\n================ PREMIUM LOG PROVIDER =================');
    print('>>> [loadAllLogs] Start 読み込み開始');

    isLoading = true;
    print('>>> [loadAllLogs] isLoading = true -> notifyListeners()');
    notifyListeners();

    logs = await _service.fetchLogs();
    print('>>> [loadAllLogs] 取得件数 : ${logs.length} 件');

    isLoading = false;
    print('>>> [loadAllLogs] isLoading = false -> notifyListeners()');
    notifyListeners();

    print('>>> [loadAllLogs] End 読み込み完了');
    print('=======================================================\n');
  }

  /// 電話番号でフィルタ（空欄なら全件）
  Future<void> filterByTel(String? tel) async {
    print('\n================ PREMIUM LOG PROVIDER =================');
    print('>>> [filterByTel] Start フィルタ処理開始');
    print('>>> 入力された電話番号: "$tel"');

    isLoading = true;
    print('>>> [filterByTel] isLoading = true -> notifyListeners()');
    notifyListeners();

    if (tel == null || tel.isEmpty) {
      print('>>> [filterByTel] 電話番号未入力なので全件取得します');
      logs = await _service.fetchLogs();
    } else {
      print('>>> [filterByTel] 電話番号 "$tel" のログを取得します');
      logs = await _service.fetchLogsByTel(tel);
    }

    print('>>> [filterByTel] 取得件数 : ${logs.length} 件');

    isLoading = false;
    print('>>> [filterByTel] isLoading = false -> notifyListeners()');
    notifyListeners();

    print('>>> [filterByTel] End フィルタ処理完了');
    print('=======================================================\n');
  }
}
