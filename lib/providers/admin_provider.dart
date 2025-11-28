import 'package:flutter/material.dart';
import '../../services/admin_home_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  int paidMemberCount = 0;
  bool isLoading = false;

  AdminProvider() {
    loadPaidMemberCount();
  }

  /// 有料会員数を取得して状態を更新
  Future<void> loadPaidMemberCount() async {
    isLoading = true;
    notifyListeners();

    try {
      final count = await _service.fetchPaidMemberCount();
      paidMemberCount = count;
    } catch (e) {
      // 必要ならエラーログやエラー状態を管理してください
      debugPrint('AdminProvider loadPaidMemberCount error: $e');
      paidMemberCount = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 外部から明示的に再読み込みするための別名
  Future<void> refresh() async => await loadPaidMemberCount();
}