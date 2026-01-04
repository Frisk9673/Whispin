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

  /// メールアドレスでユーザーを検索
  Future<User?> findByEmail(String email) async {
    logger.debug('findByEmail($email)', name: _logName);

    try {
      final results = await findWhere(field: 'id', value: email, limit: 1);
      
      if (results.isEmpty) {
        // 'EmailAddress'フィールドでも試す（後方互換性）
        final altResults = await findWhere(
          field: 'EmailAddress',
          value: email,
          limit: 1,
        );
        
        if (altResults.isEmpty) {
          logger.warning('ユーザーが見つかりません: $email', name: _logName);
          return null;
        }
        
        return altResults.first;
      }

      return results.first;
    } catch (e, stack) {
      logger.error('findByEmail() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 電話番号でユーザーを検索
  Future<User?> findByPhoneNumber(String phoneNumber) async {
    logger.debug('findByPhoneNumber($phoneNumber)', name: _logName);

    try {
      final results = await findWhere(
        field: 'phoneNumber',
        value: phoneNumber,
        limit: 1,
      );

      if (results.isEmpty) {
        logger.warning('ユーザーが見つかりません: $phoneNumber', name: _logName);
        return null;
      }

      return results.first;
    } catch (e, stack) {
      logger.error('findByPhoneNumber() エラー: $e', name: _logName, error: e, stackTrace: stack);
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

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('プレミアム会員数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findPremiumUsers() エラー: $e', name: _logName, error: e, stackTrace: stack);
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
      logger.error('countPremiumUsers() エラー: $e', name: _logName, error: e, stackTrace: stack);
      return 0;
    }
  }

  /// プレミアムステータスを更新
  Future<void> updatePremiumStatus(String userId, bool isPremium) async {
    logger.start('updatePremiumStatus($userId, $isPremium) 開始', name: _logName);

    try {
      await updateFields(userId, {
        'premium': isPremium,
        'Premium': isPremium, // 後方互換性
        'lastUpdatedPremium': DateTime.now().toIso8601String(),
        'LastUpdated_Premium': DateTime.now().toIso8601String(), // 後方互換性
      });

      logger.success('プレミアムステータス更新完了', name: _logName);
    } catch (e, stack) {
      logger.error('updatePremiumStatus() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザーを論理削除
  Future<void> softDelete(String userId) async {
    logger.start('softDelete($userId) 開始', name: _logName);

    try {
      await updateFields(userId, {
        'deletedAt': DateTime.now().toIso8601String(),
        'DeletedAt': DateTime.now().toIso8601String(), // 後方互換性
      });

      logger.success('ユーザー論理削除完了: $userId', name: _logName);
    } catch (e, stack) {
      logger.error('softDelete() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// 削除済みユーザーを取得
  Future<List<User>> findDeletedUsers() async {
    logger.debug('findDeletedUsers()', name: _logName);

    try {
      final snapshot = await collection
          .where('deletedAt', isNull: false)
          .get();

      final results = snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();

      logger.success('削除済みユーザー数: ${results.length}人', name: _logName);
      return results;
    } catch (e, stack) {
      logger.error('findDeletedUsers() エラー: $e', name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// ユーザー評価スコアを更新
  Future<void> updateRate(String userId, double rate) async {
    logger.debug('updateRate($userId, $rate)', name: _logName);

    try {
      await updateFields(userId, {
        'rate': rate,
        'Rate': rate, // 後方互換性
      });

      logger.success('評価スコア更新完了', name: _logName);
    } catch (e, stack) {
      logger.error('updateRate() エラー: $e', name: _logName, error: e, stackTrace: stack);
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
        'RoomCount': newCount, // 後方互換性
      });

      logger.success('ルーム参加回数更新: $newCount', name: _logName);
    } catch (e, stack) {
      logger.error('incrementRoomCount() エラー: $e', name: _logName, error: e, stackTrace: stack);
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
      logger.error('isActiveUser() エラー: $e', name: _logName, error: e, stackTrace: stack);
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
      return snapshot.docs
          .map((doc) => fromMap(doc.data()))
          .toList();
    });
  }
}