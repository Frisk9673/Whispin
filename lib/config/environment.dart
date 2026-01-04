import 'package:flutter/foundation.dart';

/// 環境変数と設定を管理するクラス
class Environment {
  // プライベートコンストラクタ
  Environment._();

  // ===== Environment Type =====
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';

  // ===== Firebase Configuration =====
  
  /// Firebase API Key
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'dummy',
  );

  /// Firebase Auth Domain
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'dummy.firebaseapp.com',
  );

  /// Firebase Project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'kazutxt-firebase-overvie-8d3e4',
  );

  /// Firebase Storage Bucket
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'dummy.appspot.com',
  );

  /// Firebase Messaging Sender ID
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: 'dummy',
  );

  /// Firebase App ID
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: 'dummy',
  );

  // ===== Emulator Configuration =====
  
  /// Emulator Host
  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// Auth Emulator Port
  static const int authEmulatorPort = int.fromEnvironment(
    'AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );

  /// Firestore Emulator Port
  static const int firestoreEmulatorPort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );

  /// Database Emulator Port
  static const int databaseEmulatorPort = int.fromEnvironment(
    'DATABASE_EMULATOR_PORT',
    defaultValue: 9000,
  );

  /// Emulator UI Port
  static const int emulatorUIPort = int.fromEnvironment(
    'EMULATOR_UI_PORT',
    defaultValue: 4000,
  );

  // ===== App Configuration =====
  
  /// Debug Mode
  static bool get isDebugMode => kDebugMode;

  /// Release Mode
  static bool get isReleaseMode => kReleaseMode;

  /// API Timeout (seconds)
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );

  /// Max Retry Count
  static const int maxRetryCount = int.fromEnvironment(
    'MAX_RETRY_COUNT',
    defaultValue: 3,
  );

  // ===== Logging Configuration =====
  
  /// Enable Logging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );

  /// Log Level (0: none, 1: error, 2: warning, 3: info, 4: debug)
  static const int logLevel = int.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 4,
  );

  // ===== Feature Flags =====
  
  /// Enable Analytics
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  /// Enable Crashlytics
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );

  // ===== Helper Methods =====

  /// 環境情報を出力
  static void printEnvironmentInfo() {
    if (!enableLogging) return;

    print('╔════════════════════════════════════════════════════════╗');
    print('║              Environment Configuration                ║');
    print('╠════════════════════════════════════════════════════════╣');
    print('║ Environment:        $_environment');
    print('║ Debug Mode:         $isDebugMode');
    print('║ Firebase Project:   $firebaseProjectId');
    if (isDevelopment) {
      print('║ Emulator Host:      $emulatorHost');
      print('║ Auth Port:          $authEmulatorPort');
      print('║ Firestore Port:     $firestoreEmulatorPort');
    }
    print('╚════════════════════════════════════════════════════════╝');
  }
}