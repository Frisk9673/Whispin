import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum BackendType {
  firebase,
  aws,
}

enum FirebaseMode {
  emulator,
  production,
}

/// 環境変数と設定を管理するクラス
class Environment {
  Environment._();

  // ビルドモード判定

  /// リリースビルドかどうか
  static bool get isReleaseBuild => kReleaseMode;

  /// デバッグビルドかどうか
  static bool get isDebugBuild => kDebugMode;

  /// プロファイルビルドかどうか
  static bool get isProfileBuild => kProfileMode;

  /// Webプラットフォームかどうか
  static bool get isWeb => kIsWeb;

  // 環境種別
  static late final String _environment;

  /// 開発環境かどうか
  static bool get isDevelopment => _environment == 'development';
  /// 本番環境かどうか
  static bool get isProduction => _environment == 'production';
  /// ステージング環境かどうか
  static bool get isStaging => _environment == 'staging';

  // バックエンド種別
  static late final BackendType backend;
  /// Firebase を使用しているか
  static bool get isFirebase => backend == BackendType.firebase;
  /// AWS を使用しているか
  static bool get isAws => backend == BackendType.aws;

  // Firebase 接続モード
  static late final FirebaseMode firebaseMode;

  /// Firebaseエミュレーターを使用すべきか
  ///
  /// **重要:** リリースビルド時は常に false を返し、本番環境に接続する
  static bool get shouldUseFirebaseEmulator {
    if (isReleaseBuild) {
      return false;
    }

    return firebaseMode == FirebaseMode.emulator;
  }

  // Database設定
  static late final int databaseEmulatorPort;

  // Debug設定
  static late final bool isDebugMode;

  // Emulator設定
  static late final String emulatorHost;
  static late final int authEmulatorPort;
  static late final int firestoreEmulatorPort;

  /// .env から環境変数を読み込む
  ///
  /// defaultValue の挙動は String.fromEnvironment と同等
  static void loadFromEnv() {
    // 環境種別
    _environment = dotenv.env['ENVIRONMENT'] ?? 'development';

    // Firebaseモード
    final firebaseModeStr = dotenv.env['FIREBASE_MODE'] ?? 'emulator';
    firebaseMode = firebaseModeStr == 'production'
        ? FirebaseMode.production
        : FirebaseMode.emulator;

    // バックエンド
    final backendStr = dotenv.env['BACKEND'] ?? 'firebase';
    backend = backendStr == 'aws' ? BackendType.aws : BackendType.firebase;

    // デバッグ
    isDebugMode =
        (dotenv.env['DEBUG_MODE'] ?? kDebugMode.toString()).toLowerCase() ==
            'true';

    // エミュレーター
    emulatorHost = dotenv.env['EMULATOR_HOST'] ?? 'localhost';

    authEmulatorPort =
        int.tryParse(dotenv.env['AUTH_EMULATOR_PORT'] ?? '') ?? 9099;

    firestoreEmulatorPort =
        int.tryParse(dotenv.env['FIRESTORE_EMULATOR_PORT'] ?? '') ?? 8080;

    databaseEmulatorPort =
        int.tryParse(dotenv.env['DATABASE_EMULATOR_PORT'] ?? '') ?? 9000;
  }

  /// 環境設定をコンソールに表示
  static void printConfiguration() {
    debugPrint('===== Environment Configuration =====');
    debugPrint(
        'Build Mode: ${isReleaseBuild ? "RELEASE" : (isDebugBuild ? "DEBUG" : "PROFILE")}');
    debugPrint('Platform: ${isWeb ? "Web" : "Native"}');
    debugPrint(
        'Firebase Emulator: ${shouldUseFirebaseEmulator ? "ENABLED ⚠️" : "DISABLED ✅"}');
    debugPrint('Environment: $_environment');
    debugPrint('Backend: $backend');
    debugPrint('Debug Mode: $isDebugMode');
    if (shouldUseFirebaseEmulator) {
      debugPrint('Emulator Host: $emulatorHost');
      debugPrint('Auth Emulator Port: $authEmulatorPort');
      debugPrint('Firestore Emulator Port: $firestoreEmulatorPort');
    }
    debugPrint('====================================');
  }
}
