/// List型の拡張メソッド
extension ListExtensions<T> on List<T> {
  // ===== 安全なアクセス =====

  /// 安全にインデックスアクセス（範囲外の場合はnull）
  /// 
  /// 使用箇所:
  /// - Repository層でのデータ取得
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 安全に最初の要素を取得
  /// 
  /// 使用箇所:
  /// - Service層でのデータ検索
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  /// 安全に最後の要素を取得
  /// 
  /// 使用箇所:
  /// - Service層でのデータ検索
  T? get lastOrNull {
    return isEmpty ? null : last;
  }

  /// 条件に一致する最初の要素を取得（見つからない場合はnull）
  /// 
  /// 使用箇所:
  /// - Repository層での条件検索
  /// - Service層でのフィルタリング
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}