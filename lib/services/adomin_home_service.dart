class AdminService {
  Future<int> fetchPaidMemberCount() async {
    try {
      // TODO: データベースから有料会員数を取得する処理を実装
      await Future.delayed(Duration(milliseconds: 300));
      final count = 0;
      return count;
    } catch (e) {
      print('エラー: $e');
      rethrow;
    }
  }
}