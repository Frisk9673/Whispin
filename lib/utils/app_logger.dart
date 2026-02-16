import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// アプリケーション全体のログ管理クラス
///
/// コンソール出力（print + developer.log）とファイル出力の両方をサポート
///
/// 共通方針（ログレベル使い分け）:
/// - debug: 詳細な開発調査ログ。開発時の追跡用で、本番運用判断には使わない。
/// - info: 通常フローの状態変化。開始/終了/画面表示などの定常イベント。
/// - warning: 処理継続は可能だが要注意な状態。後続調査が必要な兆候。
/// - error: 失敗や例外を伴う異常。必ず error/stackTrace とセットで記録する。
/// - success: 完了通知。内部的には info レベルとして保存し、可読性向上のため
///   メソッドを分ける。
///
/// 主要呼び出し元:
/// - services: API 呼び出し、外部連携、ユースケース処理。
/// - repositories: 永続化操作（Firestore/DB/Cache）の成功・失敗。
/// - routes/navigation: 画面遷移イベント（`NavigationLogger` 経由）。
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  File? _logFile;
  bool _isInitialized = false;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  final _fileFormat = DateFormat('yyyy-MM-dd');

  /// ログシステムの初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Web環境ではファイル保存なし（printとdeveloper.logのみ）
      if (kIsWeb) {
        _isInitialized = true;
        final initMessage = '📝 AppLogger初期化完了（Web環境: ファイル出力なし）';
        print(initMessage);
        developer.log(initMessage, name: 'AppLogger');
        return;
      }

      // モバイル/デスクトップ環境
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      // ログディレクトリが存在しない場合は作成
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
        print('📁 ログディレクトリ作成: ${logDir.path}');
      }

      // 本日のログファイルを作成
      final fileName = 'whispin_${_fileFormat.format(DateTime.now())}.log';
      _logFile = File('${logDir.path}/$fileName');

      // 古いログファイルを削除（7日以上前）
      await _cleanOldLogs(logDir);

      _isInitialized = true;

      // 初期化完了メッセージ
      final initMessage = '📝 AppLogger初期化完了\n📁 ログファイル: ${_logFile!.path}';
      print(initMessage);
      developer.log(initMessage, name: 'AppLogger');

      // ファイルにも書き込み
      if (_logFile != null) {
        await _logFile!.writeAsString(
          '${_dateFormat.format(DateTime.now())} [INFO] [AppLogger] $initMessage\n',
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (e, stack) {
      final errorMsg = 'AppLogger初期化エラー: $e';
      print('❌ $errorMsg');
      developer.log(errorMsg, name: 'AppLogger', error: e, stackTrace: stack);

      // エラーでも初期化状態にする（print/developer.logは使える）
      _isInitialized = true;
    }
  }

  /// 古いログファイルを削除
  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final now = DateTime.now();
      final files = logDir.listSync();

      for (var file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > 7) {
            await file.delete();
            print('🗑️ 古いログファイルを削除: ${file.path}');
            developer.log('古いログファイルを削除: ${file.path}', name: 'AppLogger');
          }
        }
      }
    } catch (e) {
      print('⚠️ ログクリーンアップエラー: $e');
      developer.log('ログクリーンアップエラー: $e', name: 'AppLogger', error: e);
    }
  }

  /// ログレベルを表す列挙型
  static const String levelDebug = 'DEBUG';
  static const String levelInfo = 'INFO';
  static const String levelWarning = 'WARNING';
  static const String levelError = 'ERROR';

  /// メインのログ出力メソッド
  ///
  /// [emoji] ログの絵文字（視認性向上）
  /// [message] ログメッセージ
  /// [name] ログの発信元（通常はクラス名）
  /// [level] ログレベル
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  void log(
    String emoji,
    String message, {
    String name = 'App',
    String level = levelInfo,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = _dateFormat.format(DateTime.now());
    final logLine = '$timestamp [$level] [$name] $emoji $message';

    // ===== 1. print出力（コンソール） =====
    print(logLine);
    if (error != null) {
      print('  Error: $error');
    }
    if (stackTrace != null) {
      print('  StackTrace: $stackTrace');
    }

    // ===== 2. developer.log出力（Dart DevTools用） =====
    developer.log(
      '$emoji $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );

    // ===== 3. ファイル出力 =====
    _writeToFile(logLine, error, stackTrace);
  }

  /// ログレベルを数値に変換
  int _getLevelValue(String level) {
    switch (level) {
      case levelDebug:
        return 500;
      case levelInfo:
        return 800;
      case levelWarning:
        return 900;
      case levelError:
        return 1000;
      default:
        return 800;
    }
  }

  /// ファイルにログを書き込み
  void _writeToFile(String logLine, Object? error, StackTrace? stackTrace) {
    // Web環境またはログファイルが未設定の場合はスキップ
    if (kIsWeb || _logFile == null) {
      return;
    }

    // 初期化前の場合もスキップ（printは既に実行済み）
    if (!_isInitialized) {
      return;
    }

    try {
      final buffer = StringBuffer(logLine);
      buffer.writeln();

      if (error != null) {
        buffer.writeln('  Error: $error');
      }

      if (stackTrace != null) {
        buffer.writeln('  StackTrace: $stackTrace');
      }

      // 同期書き込み（確実に保存）
      _logFile!.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      print('❌ ログファイル書き込みエラー: $e');
      developer.log('ログファイル書き込みエラー: $e', name: 'AppLogger', error: e);
    }
  }

  // === 便利メソッド ===

  /// デバッグログ
  void debug(String message, {String name = 'App'}) {
    log('🐛', message, name: name, level: levelDebug);
  }

  /// 情報ログ
  void info(String message, {String name = 'App'}) {
    log('ℹ️', message, name: name, level: levelInfo);
  }

  /// 警告ログ
  void warning(String message, {String name = 'App'}) {
    log('⚠️', message, name: name, level: levelWarning);
  }

  /// エラーログ
  void error(
    String message, {
    String name = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    log('❌', message,
        name: name, level: levelError, error: error, stackTrace: stackTrace);
  }

  /// 成功ログ
  void success(String message, {String name = 'App'}) {
    log('✅', message, name: name, level: levelInfo);
  }

  /// 開始ログ
  void start(String message, {String name = 'App'}) {
    log('▶️', message, name: name, level: levelInfo);
  }

  /// 終了ログ
  void end(String message, {String name = 'App'}) {
    log('⏹️', message, name: name, level: levelInfo);
  }

  /// セクション区切り
  void section(String title, {String name = 'App'}) {
    final separator = '=' * 50;
    log('📋', '\n$separator\n$title\n$separator', name: name);
  }

  /// ページ遷移ログ
  void navigation(String from, String to, {String name = 'Navigation'}) {
    log('📱', '$from → $to', name: name);
  }

  /// API呼び出しログ
  void apiCall(String endpoint, {String name = 'API'}) {
    log('🌐', 'API呼び出し: $endpoint', name: name);
  }

  /// データベースログ
  void database(String operation, {String name = 'Database'}) {
    log('💾', 'DB操作: $operation', name: name);
  }

  /// ログファイルのパスを取得（デバッグ用）
  String? getLogFilePath() {
    return _logFile?.path;
  }

  /// 初期化状態を確認
  bool get isInitialized => _isInitialized;
}

final logger = AppLogger();
