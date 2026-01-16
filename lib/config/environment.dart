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

  // ===== Environment Type =====
  static late final String _environment;

  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';

  // ===== Backend =====
  static late final BackendType backend;
  static bool get isFirebase => backend == BackendType.firebase;
  static bool get isAws => backend == BackendType.aws;

  // ===== Firebase Mode =====
  static late final FirebaseMode firebaseMode;
  static bool get isFirebaseEmulator => firebaseMode == FirebaseMode.emulator;
  static bool get isFirebaseProduction =>
      firebaseMode == FirebaseMode.production;

  // ===== Database =====
  static late final int databaseEmulatorPort;

  // ===== Debug =====
  static late final bool isDebugMode;

  // ===== Emulator =====
  static late final String emulatorHost;
  static late final int authEmulatorPort;
  static late final int firestoreEmulatorPort;

  /// .env から環境変数を読み込む
  ///
  /// defaultValue の挙動は String.fromEnvironment と同等
  static void loadFromEnv() {
    // Environment
    _environment = dotenv.env['ENVIRONMENT'] ?? 'development';

    // Firebase Mode
    final firebaseModeStr = dotenv.env['FIREBASE_MODE'] ?? 'emulator';
    firebaseMode = firebaseModeStr == 'production'
        ? FirebaseMode.production
        : FirebaseMode.emulator;

    // Backend
    final backendStr = dotenv.env['BACKEND'] ?? 'firebase';
    backend = backendStr == 'aws' ? BackendType.aws : BackendType.firebase;

    // Debug
    isDebugMode =
        (dotenv.env['DEBUG_MODE'] ?? kDebugMode.toString()).toLowerCase() ==
            'true';

    // Emulator
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
    debugPrint('Environment: $_environment');
    debugPrint('Backend: $backend');
    debugPrint('Debug Mode: $isDebugMode');
    debugPrint('Emulator Host: $emulatorHost');
    debugPrint('Auth Emulator Port: $authEmulatorPort');
    debugPrint('Firestore Emulator Port: $firestoreEmulatorPort');
    debugPrint('====================================');
  }
}
