import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:whispin/firebase_options.dart';
import '../utils/app_logger.dart';
import 'environment.dart';

/// Firebase初期化と設定を管理するクラス
class FirebaseConfig {
  static const String _logName = 'FirebaseConfig';

  // インスタンス化を防ぐ
  FirebaseConfig._();

  /// Firebase初期化
  static Future<void> initialize() async {
    logger.section('🔥 Firebase初期化開始', name: _logName);

    try {
      logger.start('Firebase Core 初期化中...', name: _logName);

      // FlutterFire CLI の設定を使用
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      logger.success('Firebase Core 初期化完了', name: _logName);

      // エミュレーター利用判定
      if (Environment.shouldUseFirebaseEmulator) {
        logger.warning('⚠️ デバッグモード: Firebaseエミュレーターを使用します', name: _logName);
        await _configureEmulators();
      } else {
        logger.success('✅ 本番モード: Firebase本番環境に接続します', name: _logName);
      }

      // 環境情報を出力
      Environment.printConfiguration();

      logger.success('✨ Firebase初期化完了', name: _logName);
    } catch (e, stack) {
      logger.error('❌ Firebase初期化エラー: $e',
          name: _logName, error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// エミュレーター設定
  static Future<void> _configureEmulators() async {
    logger.start('🔧 Firebase エミュレーター設定中...', name: _logName);

    try {
      // Authエミュレーター
      FirebaseAuth.instance.useAuthEmulator(
        Environment.emulatorHost,
        Environment.authEmulatorPort,
      );
      logger.success(
        '  ✓ Auth Emulator: ${Environment.emulatorHost}:${Environment.authEmulatorPort}',
        name: _logName,
      );

      // Firestoreエミュレーター
      FirebaseFirestore.instance.useFirestoreEmulator(
        Environment.emulatorHost,
        Environment.firestoreEmulatorPort,
      );
      logger.success(
        '  ✓ Firestore Emulator: ${Environment.emulatorHost}:${Environment.firestoreEmulatorPort}',
        name: _logName,
      );

      // Storageエミュレーター
      FirebaseStorage.instance.useStorageEmulator(
        Environment.emulatorHost,
        Environment.storageEmulatorPort,
      );
      logger.success(
        '  ✓ Storage Emulator: ${Environment.emulatorHost}:${Environment.storageEmulatorPort}',
        name: _logName,
      );

      // Firestore設定
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        sslEnabled: false,
      );

      logger.success('エミュレーター設定完了', name: _logName);
    } catch (e) {
      logger.error('⚠️ エミュレーター設定エラー: $e', name: _logName, error: e);
      // エミュレーター設定エラーは致命的ではないため続行
    }
  }

  /// Firebase Auth インスタンス取得
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Firestore インスタンス取得
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// 現在のユーザー取得
  static User? get currentUser => auth.currentUser;

  /// ログイン状態確認
  static bool get isSignedIn => currentUser != null;

  /// エミュレーター接続状態確認
  static bool get isUsingEmulator => Environment.shouldUseFirebaseEmulator;
}
