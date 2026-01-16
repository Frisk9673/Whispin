import 'dart:developer' as developer;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// アプリケーション全体のログ管理クラス
/// 
/// コンソール出力とファイル出力の両方をサポート
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
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final fileName = 'whispin_${_fileFormat.format(DateTime.now())}.log';
      _logFile = File('${logDir.path}/$fileName');

      // 古いログファイルを削除（7日以上前）
      await _cleanOldLogs(logDir);

      _isInitialized = true;
      
      log('📝', 'AppLogger初期化完了', name: 'AppLogger');
      log('📁', 'ログファイル: ${_logFile!.path}', name: 'AppLogger');
    } catch (e) {
      developer.log(
        'AppLogger初期化エラー: $e',
        name: 'AppLogger',
        error: e,
      );
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
            developer.log('古いログファイルを削除: ${file.path}', name: 'AppLogger');
          }
        }
      }
    } catch (e) {
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

    // コンソール出力（developer.log使用）
    developer.log(
      '$emoji $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );

    // ファイル出力
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
    if (!_isInitialized || _logFile == null) return;

    try {
      final buffer = StringBuffer(logLine);
      buffer.writeln();

      if (error != null) {
        buffer.writeln('  Error: $error');
      }

      if (stackTrace != null) {
        buffer.writeln('  StackTrace: $stackTrace');
      }

      _logFile!.writeAsStringSync(
        buffer.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
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
}

final logger = AppLogger();