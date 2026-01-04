/// List型の拡張メソッド
extension ListExtensions<T> on List<T> {
  // ===== Safety =====

  /// 安全にインデックスアクセス（範囲外の場合はnull）
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 安全に最初の要素を取得
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  /// 安全に最後の要素を取得
  T? get lastOrNull {
    return isEmpty ? null : last;
  }

  /// 条件に一致する最初の要素を取得（見つからない場合はnull）
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }

  /// 条件に一致する最後の要素を取得（見つからない場合はnull）
  T? lastWhereOrNull(bool Function(T) test) {
    try {
      return lastWhere(test);
    } catch (_) {
      return null;
    }
  }

  // ===== Transformation =====

  /// 重複を除去
  List<T> get unique {
    return toSet().toList();
  }

  /// プロパティで重複を除去
  List<T> uniqueBy<K>(K Function(T) keySelector) {
    final seen = <K>{};
    return where((item) {
      final key = keySelector(item);
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// リストをシャッフル（新しいリストを返す）
  List<T> get shuffled {
    final copy = List<T>.from(this);
    copy.shuffle();
    return copy;
  }

  /// リストを反転（新しいリストを返す）
  List<T> get reversed {
    return List<T>.from(this).reversed.toList();
  }

  /// 指定サイズのチャンクに分割
  List<List<T>> chunk(int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be positive');
    if (isEmpty) return [];

    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      final end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// 条件でリストを分割
  List<List<T>> splitWhere(bool Function(T) test) {
    final result = <List<T>>[];
    var current = <T>[];

    for (var item in this) {
      if (test(item)) {
        if (current.isNotEmpty) {
          result.add(current);
          current = [];
        }
      } else {
        current.add(item);
      }
    }

    if (current.isNotEmpty) {
      result.add(current);
    }

    return result;
  }

  // ===== Aggregation =====

  /// 数値リストの合計（T が num の場合のみ）
  num get sum {
    if (isEmpty) return 0;
    if (this is! List<num>) throw UnsupportedError('List must contain numbers');
    return (this as List<num>).reduce((a, b) => a + b);
  }

  /// 数値リストの平均
  double get average {
    if (isEmpty) return 0;
    return sum / length;
  }

  /// 最大値を取得（Comparable型のみ）
  T? get maxOrNull {
    if (isEmpty) return null;
    if (this is! List<Comparable>) {
      throw UnsupportedError('List must contain Comparable elements');
    }
    return (this as List<Comparable>).reduce((a, b) => a.compareTo(b) > 0 ? a : b) as T;
  }

  /// 最小値を取得（Comparable型のみ）
  T? get minOrNull {
    if (isEmpty) return null;
    if (this is! List<Comparable>) {
      throw UnsupportedError('List must contain Comparable elements');
    }
    return (this as List<Comparable>).reduce((a, b) => a.compareTo(b) < 0 ? a : b) as T;
  }

  /// プロパティで最大値を取得
  T? maxBy<K extends Comparable>(K Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) > 0 ? a : b);
  }

  /// プロパティで最小値を取得
  T? minBy<K extends Comparable>(K Function(T) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) < 0 ? a : b);
  }

  // ===== Filtering =====

  /// null要素を除去
  List<T> get whereNotNull {
    return where((item) => item != null).toList();
  }

  /// 空文字列を除去（T が String の場合）
  List<T> get whereNotEmpty {
    if (this is! List<String>) return this;
    return where((item) => (item as String).isNotEmpty).toList();
  }

  /// インデックス付きでフィルタ
  List<T> whereIndexed(bool Function(int index, T item) test) {
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      if (test(i, this[i])) {
        result.add(this[i]);
      }
    }
    return result;
  }

  // ===== Grouping & Sorting =====

  /// プロパティでグループ化
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (var item in this) {
      final key = keySelector(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// プロパティでソート（昇順）
  List<T> sortedBy<K extends Comparable>(K Function(T) selector) {
    final copy = List<T>.from(this);
    copy.sort((a, b) => selector(a).compareTo(selector(b)));
    return copy;
  }

  /// プロパティでソート（降順）
  List<T> sortedByDescending<K extends Comparable>(K Function(T) selector) {
    final copy = List<T>.from(this);
    copy.sort((a, b) => selector(b).compareTo(selector(a)));
    return copy;
  }

  // ===== Set Operations =====

  /// 他のリストとの和集合
  List<T> union(List<T> other) {
    return {...this, ...other}.toList();
  }

  /// 他のリストとの積集合
  List<T> intersection(List<T> other) {
    return where((item) => other.contains(item)).toList();
  }

  /// 他のリストとの差集合
  List<T> difference(List<T> other) {
    return where((item) => !other.contains(item)).toList();
  }

  // ===== Utility =====

  /// ランダムな要素を取得
  T? get randomOrNull {
    if (isEmpty) return null;
    return this[(length * (DateTime.now().millisecond / 1000)).floor()];
  }

  /// 要素をカウント
  int count(bool Function(T) test) {
    return where(test).length;
  }

  /// 全ての要素が条件を満たすか
  bool all(bool Function(T) test) {
    return every(test);
  }

  /// いずれかの要素が条件を満たすか
  bool anyMatch(bool Function(T) test) {
    return any(test);
  }

  /// 条件を満たす要素が存在しないか
  bool none(bool Function(T) test) {
    return !any(test);
  }

  /// リストを文字列に変換（セパレータ付き）
  String joinWithSeparator(String separator, [String Function(T)? mapper]) {
    if (mapper != null) {
      return map(mapper).join(separator);
    }
    return join(separator);
  }

  /// インデックス付きでマップ
  List<R> mapIndexed<R>(R Function(int index, T item) mapper) {
    final result = <R>[];
    for (var i = 0; i < length; i++) {
      result.add(mapper(i, this[i]));
    }
    return result;
  }

  /// 最初のN個を取得
  List<T> takeFirst(int n) {
    if (n <= 0) return [];
    if (n >= length) return List<T>.from(this);
    return sublist(0, n);
  }

  /// 最後のN個を取得
  List<T> takeLast(int n) {
    if (n <= 0) return [];
    if (n >= length) return List<T>.from(this);
    return sublist(length - n);
  }

  /// 最初のN個をスキップ
  List<T> skipFirst(int n) {
    if (n <= 0) return List<T>.from(this);
    if (n >= length) return [];
    return sublist(n);
  }

  /// 最後のN個をスキップ
  List<T> skipLast(int n) {
    if (n <= 0) return List<T>.from(this);
    if (n >= length) return [];
    return sublist(0, length - n);
  }

  /// リストを分割（true/false）
  ({List<T> matching, List<T> notMatching}) partition(bool Function(T) test) {
    final matching = <T>[];
    final notMatching = <T>[];

    for (var item in this) {
      if (test(item)) {
        matching.add(item);
      } else {
        notMatching.add(item);
      }
    }

    return (matching: matching, notMatching: notMatching);
  }
}