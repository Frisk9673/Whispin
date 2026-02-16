import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// リポジトリの基底クラス。
///
/// `BaseRepository` は各 Repository 実装の共通基盤として、以下を統一する。
/// - 共通 CRUD (`create/find/update/delete`) の提供
/// - Realtime 監視 Stream (`watchById/watchAll/watchWhere`) の提供
/// - ログ出力と例外ハンドリング方針の統一
///
/// エラーハンドリング方針:
/// - 永続化処理で失敗した場合は logger に記録して `rethrow` する
/// - 参照系の一部ユーティリティ（`exists`, `count`）はフェイルセーフ値を返す
///
/// 利用方針:
/// - 個別 Repository はこの基底を継承し、アプリ固有のクエリのみを追加する
/// - 呼び出しは Service 層経由を前提とし、UI から直接呼ばない
abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _logName;

  BaseRepository(this._logName);

  /// コレクション名を取得（サブクラスで実装）
  String get collectionName;

  /// Firestoreインスタンス取得
  FirebaseFirestore get firestore => _firestore;

  /// コレクション参照を取得
  CollectionReference<Map<String, dynamic>> get collection {
    return _firestore.collection(collectionName);
  }

  /// Mapからモデルへ変換（サブクラスで実装）
  T fromMap(Map<String, dynamic> map);

  /// モデルからMapへ変換（サブクラスで実装）
  Map<String, dynamic> toMap(T model);

  // ===== CRUD Operations =====

  /// ドキュメントを作成
  Future<String> create(T model, {String? id}) async {
    logger.start('$_logName.create() 開始', name: _logName);

    try {
      final data = toMap(model);

      if (id != null) {
        // IDを指定して作成
        await collection.doc(id).set(data);
        logger.success('ドキュメント作成完了: $id', name: _logName);
        return id;
      } else {
        // 自動IDで作成
        final docRef = await collection.add(data);
        logger.success('ドキュメント作成完了: ${docRef.id}', name: _logName);
        return docRef.id;
      }
    } catch (e, stack) {
      logger.error('create() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ドキュメントを取得
  Future<T?> findById(String id) async {
    logger.debug('$_logName.findById($id)', name: _logName);

    try {
      final doc = await collection.doc(id).get();

      if (!doc.exists) {
        logger.warning('ドキュメントが見つかりません: $id', name: _logName);
        return null;
      }

      final data = doc.data();
      if (data == null) {
        logger.warning('ドキュメントデータがnull: $id', name: _logName);
        return null;
      }

      return fromMap(data);
    } catch (e, stack) {
      logger.error('findById() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 全ドキュメントを取得
  Future<List<T>> findAll() async {
    logger.start('$_logName.findAll() 開始', name: _logName);

    try {
      final snapshot = await collection.get();
      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('取得件数: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findAll() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 条件に一致するドキュメントを取得
  Future<List<T>> findWhere({
    required String field,
    required dynamic value,
    int? limit,
  }) async {
    logger.debug('$_logName.findWhere($field = $value)', name: _logName);

    try {
      Query<Map<String, dynamic>> query =
          collection.where(field, isEqualTo: value);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('検索結果: ${results.length}件', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findWhere() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ドキュメントを更新
  Future<void> update(String id, T model) async {
    logger.start('$_logName.update($id) 開始', name: _logName);

    try {
      final data = toMap(model);
      await collection.doc(id).update(data);
      logger.success('ドキュメント更新完了: $id', name: _logName);
    } catch (e, stack) {
      logger.error('update() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ドキュメントを部分更新
  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    logger.debug('$_logName.updateFields($id)', name: _logName);

    try {
      await collection.doc(id).update(fields);
      logger.success('フィールド更新完了: $id', name: _logName);
    } catch (e, stack) {
      logger.error('updateFields() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ドキュメントを削除
  Future<void> delete(String id) async {
    logger.start('$_logName.delete($id) 開始', name: _logName);

    try {
      await collection.doc(id).delete();
      logger.success('ドキュメント削除完了: $id', name: _logName);
    } catch (e, stack) {
      logger.error('delete() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ドキュメントの存在確認
  Future<bool> exists(String id) async {
    logger.debug('$_logName.exists($id)', name: _logName);

    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e, stack) {
      logger.error('exists() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// ドキュメント数を取得
  Future<int> count() async {
    logger.debug('$_logName.count()', name: _logName);

    try {
      final snapshot = await collection.get();
      return snapshot.docs.length;
    } catch (e, stack) {
      logger.error('count() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return 0;
    }
  }

  // ===== Realtime Updates =====

  /// ドキュメントの変更をリアルタイムで監視
  Stream<T?> watchById(String id) {
    logger.debug('$_logName.watchById($id) - Stream開始', name: _logName);

    return collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      return fromMap(data);
    });
  }

  /// コレクション全体の変更を監視
  Stream<List<T>> watchAll() {
    logger.debug('$_logName.watchAll() - Stream開始', name: _logName);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  /// 条件に一致するドキュメントの変更を監視
  Stream<List<T>> watchWhere({
    required String field,
    required dynamic value,
    int? limit,
  }) {
    logger.debug('$_logName.watchWhere($field = $value) - Stream開始',
        name: _logName);

    Query<Map<String, dynamic>> query =
        collection.where(field, isEqualTo: value);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }
}
