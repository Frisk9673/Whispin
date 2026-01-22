import 'package:firebase_auth/firebase_auth.dart' as fba;
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/password_hasher.dart';
import '../utils/app_logger.dart';

class UserRegisterService {
  final _auth = fba.FirebaseAuth.instance;
  static const String _logName = 'UserRegisterService';

  /// ユーザー登録処理（StorageService統合版）
  ///
  /// [user] 登録するユーザー情報（パスワードフィールドは空でOK）
  /// [password] 生パスワード（ハッシュ化されます）
  /// [storageService] データ永続化サービス（必須）
  Future<bool> register({
    required User user,
    required String password,
    required StorageService storageService,
  }) async {
    logger.section('register() 開始', name: _logName);

    try {
      // ===== 1. パスワードをハッシュ化 =====
      logger.start('パスワードをハッシュ化中...', name: _logName);

      final salt = PasswordHasher.generateSalt();
      final passwordHash = PasswordHasher.hashPassword(password, salt);

      logger.success('パスワードハッシュ化完了', name: _logName);
      logger.debug('  Salt: ${salt.substring(0, 8)}...', name: _logName);
      logger.debug('  Hash: ${passwordHash.substring(0, 8)}...',
          name: _logName);

      // ===== 2. Firebase Auth にユーザー作成 =====
      logger.start('FirebaseAuth にユーザー作成リクエスト送信中...', name: _logName);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.id,
        password: password,
      );

      logger.success('Auth 登録成功!', name: _logName);
      logger.info('  UID: ${credential.user?.uid}', name: _logName);

      // ===== 3. パスワードハッシュを含むUserオブジェクト作成 =====
      logger.start('ハッシュ化パスワードを含むUserオブジェクト作成中...', name: _logName);

      final userWithPassword = User(
        id: user.id,
        password: passwordHash, // ✅ ハッシュ化されたパスワード
        firstName: user.firstName,
        lastName: user.lastName,
        nickname: user.nickname,
        phoneNumber: user.phoneNumber,
        rate: user.rate,
        premium: user.premium,
        roomCount: user.roomCount,
        createdAt: user.createdAt,
        lastUpdatedPremium: user.lastUpdatedPremium,
        deletedAt: user.deletedAt,
      );

      logger.success('Userオブジェクト作成完了', name: _logName);

      // ===== 4. StorageService にユーザー追加 =====
      logger.section('StorageService 経由でユーザー保存開始', name: _logName);

      // 既存ユーザーチェック
      final existingUser = storageService.users.firstWhere(
        (u) => u.id == user.id,
        orElse: () => User(id: ''),
      );

      if (existingUser.id.isNotEmpty) {
        logger.warning('既に存在するユーザー: ${user.id}', name: _logName);
        throw Exception('このメールアドレスは既に登録されています');
      }

      // StorageService に追加（パスワードハッシュ付き）
      logger.start('StorageService.users にユーザー追加中...', name: _logName);
      storageService.users.add(userWithPassword);
      logger.success('users リストに追加完了', name: _logName);

      // StorageService 保存（Firestore への保存も自動実行される）
      logger.start('StorageService.save() 実行中...', name: _logName);
      await storageService.save();
      logger.success('StorageService.save() 完了 → Firestore にも保存されました',
          name: _logName);

      // ===== 5. 保存検証 =====
      logger.section('保存検証開始', name: _logName);

      // StorageService 内のユーザー確認
      final savedUser = storageService.users.firstWhere(
        (u) => u.id == user.id,
        orElse: () => User(id: ''),
      );

      if (savedUser.id.isEmpty) {
        logger.error('StorageService にユーザーが見つかりません', name: _logName);
        throw Exception('ユーザー保存に失敗しました');
      }

      logger.success('StorageService 保存検証: OK', name: _logName);
      logger.info('  ID: ${savedUser.id}', name: _logName);
      logger.info('  名前: ${savedUser.fullName}', name: _logName);
      logger.info('  ニックネーム: ${savedUser.nickname}', name: _logName);
      logger.info('  プレミアム: ${savedUser.premium}', name: _logName);
      logger.info(
          '  パスワードハッシュ: ${savedUser.password.isNotEmpty ? "保存済み" : "未保存"}',
          name: _logName);

      logger.section('register() 正常終了', name: _logName);
      return true;
    } on fba.FirebaseAuthException catch (e) {
      logger.error(
        'FirebaseAuthException 発生: ${e.code}',
        name: _logName,
        error: e,
      );

      // ユーザーフレンドリーなエラーメッセージに変換
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'このメールアドレスは既に使用されています';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        case 'weak-password':
          errorMessage = 'パスワードが脆弱です。より強固なパスワードを設定してください';
          break;
        case 'operation-not-allowed':
          errorMessage = 'この操作は許可されていません';
          break;
        default:
          errorMessage = 'Auth エラー: ${e.code}';
      }

      logger.section('register() 異常終了（Auth エラー）', name: _logName);
      throw Exception(errorMessage);
    } catch (e, stack) {
      logger.error(
        'その他のエラー発生: $e',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      logger.section('register() 異常終了', name: _logName);
      throw Exception('登録エラー: $e');
    }
  }

  /// ユーザー登録のロールバック（エラー時）
  ///
  /// Auth 登録は成功したが、Firestore 保存に失敗した場合などに使用
  Future<void> rollbackRegistration(String email) async {
    logger.warning('rollbackRegistration() 開始 - email: $email', name: _logName);

    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.email == email) {
        logger.start('Firebase Auth ユーザー削除中...', name: _logName);
        await currentUser.delete();
        logger.success('ロールバック完了', name: _logName);
      } else {
        logger.warning('ロールバック対象ユーザーが見つかりません', name: _logName);
      }
    } catch (e) {
      logger.error('ロールバックエラー: $e', name: _logName, error: e);
      // ロールバックエラーは警告のみ（元のエラーを優先）
    }
  }
}
