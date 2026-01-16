import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import 'base_repository.dart';
import '../utils/app_logger.dart';

/// ユーザーデータのリポジトリ
class UserRepository extends BaseRepository<User> {
  static const String _logName = 'UserRepository';

  UserRepository() : super(_logName);

  @override
  String get collectionName => AppConstants.usersCollection;

  @override
  User fromMap(Map<String, dynamic> map) => User.fromMap(map);

  @override
  Map<String, dynamic> toMap(User model) => model.toMap();

  // ===== User Specific Methods =====

  /// メールアドレスでユーザーを検索（強化版）
  Future<User?> findByEmail(String email) async {
    logger.section('findByEmail($email) 開始', name: _logName);

    try {
      // ===== 方法1: 'id' フィールドで検索 =====
      logger.start('方法1: id フィールドで検索中...', name: _logName);
      
      final snapshot1 = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot1.docs.isNotEmpty) {
        print('方法1で発見: ${snapshot1.docs.first.id}');
        
        final data = snapshot1.docs.first.data();
        logger.info('取得データ:', name: _logName);
        data.forEach((key, value) {
          logger.info('  $key: $value', name: _logName);
        });
        
        final user = fromMap(data);
        logger.section('findByEmail() 完了', name: _logName);
        return user;
      }

      logger.warning('方法1: 見つかりませんでした', name: _logName);

      // ===== 全ての方法で見つからない場合 =====
      print('全ての方法でユーザーが見つかりませんでした');
      print('検索したメールアドレス: $email');
      print('検索したコレクション: $collectionName');
      
      // デバッグ用: コレクション内の全ドキュメントID表示
      logger.start('デバッグ: コレクション内の全ドキュメントIDを表示', name: _logName);
      final allDocs = await firestore
          .collection(collectionName)
          .limit(10)
          .get();
      
      if (allDocs.docs.isEmpty) {
        logger.warning('コレクションが空です！', name: _logName);
      } else {
        logger.info('コレクション内の最初の10件:', name: _logName);
        for (var doc in allDocs.docs) {
          logger.info('  - ${doc.id}', name: _logName);
        }
      }

      logger.section('findByEmail() 完了（null）', name: _logName);
      return null;

    } catch (e, stack) {
      logger.error('findByEmail() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// プレミアム会員を全件取得
  Future<List<User>> findPremiumUsers() async {
    logger.start('findPremiumUsers() 開始', name: _logName);

    try {
      final snapshot = await collection
          .where('premium', isEqualTo: true)
          .where('deletedAt', isNull: true)
          .get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('プレミアム会員数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findPremiumUsers() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// プレミアム会員数を取得
  Future<int> countPremiumUsers() async {
    logger.debug('countPremiumUsers()', name: _logName);

    try {
      final snapshot = await collection
          .where('premium', isEqualTo: true)
          .where('deletedAt', isNull: true)
          .get();

      final count = snapshot.docs.length;
      logger.success('プレミアム会員数: $count人', name: _logName);
      return count;
    } catch (e, stack) {
      logger.error('countPremiumUsers() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return 0;
    }
  }

  /// プレミアムステータスを更新
  Future<void> updatePremiumStatus(String userId, bool isPremium) async {
    logger.start('updatePremiumStatus($userId, $isPremium) 開始', name: _logName);

    try {
      // ユーザー検索して実際のドキュメントIDを取得
      logger.start('ユーザー検索中...', name: _logName);
      
      // メールアドレスで検索
      final userSnapshot = await firestore
          .collection(collectionName)
          .where('id', isEqualTo: userId)
          .limit(1)
          .get();

      // 旧形式のEmailAddressでも検索
      if (userSnapshot.docs.isEmpty) {
        final altSnapshot = await firestore
            .collection(collectionName)
            .where('EmailAddress', isEqualTo: userId)
            .limit(1)
            .get();
        
        if (altSnapshot.docs.isEmpty) {
          logger.error('ユーザーが見つかりません: $userId', name: _logName);
          throw Exception('ユーザー情報が見つかりません');
        }
        
        final docId = altSnapshot.docs.first.id;
        logger.success('ドキュメントID取得: $docId', name: _logName);
        
        await _updatePremiumFields(docId, isPremium);
      } else {
        final docId = userSnapshot.docs.first.id;
        logger.success('ドキュメントID取得: $docId', name: _logName);
        
        await _updatePremiumFields(docId, isPremium);
      }

      logger.section('updatePremiumStatus() 完了', name: _logName);
    } catch (e, stack) {
      logger.error('updatePremiumStatus() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// プレミアムフィールドを更新する内部メソッド
  Future<void> _updatePremiumFields(String docId, bool isPremium) async {
    logger.start('Firestore更新中... (docId: $docId)', name: _logName);
    
    await firestore.collection(collectionName).doc(docId).update({
      'premium': isPremium,
      'Premium': isPremium,
      'lastUpdatedPremium': FieldValue.serverTimestamp(),
      'LastUpdated_Premium': FieldValue.serverTimestamp(),
    });
    
    logger.success('Firestore更新完了', name: _logName);
  }

  /// ユーザーを論理削除
  Future<void> softDelete(String userId) async {
    logger.start('softDelete($userId) 開始', name: _logName);

    try {
      await updateFields(userId, {
        'deletedAt': DateTime.now().toIso8601String(),
        'DeletedAt': DateTime.now().toIso8601String(),
      });

      logger.success('ユーザー論理削除完了: $userId', name: _logName);
    } catch (e, stack) {
      logger.error('softDelete() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 削除済みユーザーを取得
  Future<List<User>> findDeletedUsers() async {
    logger.debug('findDeletedUsers()', name: _logName);

    try {
      final snapshot = await collection.where('deletedAt', isNull: false).get();

      final results = snapshot.docs.map((doc) => fromMap(doc.data())).toList();

      logger.success('削除済みユーザー数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findDeletedUsers() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザー評価スコアを更新
  Future<void> updateRate(String userId, double rate) async {
    logger.debug('updateRate($userId, $rate)', name: _logName);

    try {
      await updateFields(userId, {
        'rate': rate,
        'Rate': rate,
      });

      logger.success('評価スコア更新完了', name: _logName);
    } catch (e, stack) {
      logger.error('updateRate() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ルーム参加回数を更新
  Future<void> incrementRoomCount(String userId) async {
    logger.debug('incrementRoomCount($userId)', name: _logName);

    try {
      final user = await findById(userId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません: $userId');
      }

      final newCount = user.roomCount + 1;
      await updateFields(userId, {
        'roomCount': newCount,
        'RoomCount': newCount,
      });

      logger.success('ルーム参加回数更新: $newCount', name: _logName);
    } catch (e, stack) {
      logger.error('incrementRoomCount() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーが存在し、削除されていないか確認
  Future<bool> isActiveUser(String userId) async {
    logger.debug('isActiveUser($userId)', name: _logName);

    try {
      final user = await findById(userId);

      if (user == null) {
        logger.warning('ユーザーが存在しません: $userId', name: _logName);
        return false;
      }

      if (user.isDeleted) {
        logger.warning('削除済みユーザー: $userId', name: _logName);
        return false;
      }

      return true;
    } catch (e, stack) {
      logger.error('isActiveUser() エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      return false;
    }
  }

  /// プレミアム会員の変更を監視
  Stream<List<User>> watchPremiumUsers() {
    logger.debug('watchPremiumUsers() - Stream開始', name: _logName);

    return collection
        .where('premium', isEqualTo: true)
        .where('deletedAt', isNull: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  /// プレミアム契約・解約ログ作成
  Future<void> createPremiumLog({
    required String phoneNumber,
    required bool isPremium,
  }) async {
    try {
      final detail = isPremium ? '契約' : '解約';

      await firestore.collection('Log_Premium').add({
        'ID': phoneNumber,
        'Timestamp': FieldValue.serverTimestamp(),
        'Detail': detail,
      });

      logger.success(
        'Log_Premium 作成完了: $phoneNumber / $detail',
        name: _logName,
      );
    } catch (e, stack) {
      logger.error(
        'Log_Premium 作成失敗: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}