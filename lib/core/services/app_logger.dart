import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug('DEBUG', 0),
  info('INFO', 1),
  warning('WARNING', 2),
  error('ERROR', 3);

  final String label;
  final int priority;
  const LogLevel(this.label, this.priority);
}

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get preview {
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }
    return message;
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const int maxLogs = 1000;
  static const int maxErrors = 100;

  final List<LogEntry> _logs = [];
  final List<LogEntry> _errors = [];
  final _controller = StreamController<List<LogEntry>>.broadcast();
  
  bool _isInitialized = false;
  
  Stream<List<LogEntry>> get stream => _controller.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<LogEntry> get errors => List.unmodifiable(_errors);
  List<LogEntry> get allLogs => [..._logs.reversed.toList()];

  int get errorCount => _errors.length;
  int get totalCount => _logs.length;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    if (kDebugMode) {
      _setupErrorHandling();
      Future.microtask(() => d('AppLogger initialized'));
    }
  }

  void _setupErrorHandling() {
    PlatformDispatcher.instance.onError = (error, stack) {
      e('Unhandled Error: $error', error: error, stackTrace: stack);
      return false;
    };

    FlutterError.onError = (details) {
      e('FlutterError: ${details.exception}', error: details.exception, stackTrace: details.stack);
    };
  }

  void d(String message, {String? tag}) {
    _addLog(message, LogLevel.debug, tag: tag);
  }

  void i(String message, {String? tag}) {
    _addLog(message, LogLevel.info, tag: tag);
  }

  void w(String message, {String? tag}) {
    _addLog(message, LogLevel.warning, tag: tag);
  }

  void e(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _addLog(message, LogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
    if (error != null) {
      _addError(message, error, stackTrace, tag);
    }
  }

  void _addLog(String message, LogLevel level, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    _controller.add(allLogs);
  }

  void _addError(String message, Object error, StackTrace? stack, String? tag) {
    final entry = LogEntry(
      message: message,
      level: LogLevel.error,
      timestamp: DateTime.now(),
      tag: tag,
      error: error,
      stackTrace: stack,
    );

    _errors.add(entry);
    if (_errors.length > maxErrors) {
      _errors.removeAt(0);
    }
  }

  void clear() {
    _logs.clear();
    _errors.clear();
    _controller.add(allLogs);
  }

  void clearErrors() {
    _errors.clear();
  }

  void export() {
    final buffer = StringBuffer();
    buffer.writeln('=== App Logs Export ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total: ${_logs.length} logs, ${_errors.length} errors');
    buffer.writeln('');

    for (final log in _logs) {
      buffer.writeln('[${log.formattedTime}] ${log.level.label} ${log.tag != null ? '[${log.tag}] ' : ''}${log.message}');
      if (log.error != null) {
        buffer.writeln('  Error: $log.error');
      }
      if (log.stackTrace != null) {
        buffer.writeln('  Stack: $log.stackTrace');
      }
    }

    debugPrint(buffer.toString());
  }

  void logHttp(String method, String url, {int? statusCode, String? response}) {
    final level = (statusCode != null && statusCode >= 400) ? LogLevel.error : LogLevel.info;
    final msg = '$method $url${statusCode != null ? ' → $statusCode' : ''}';
    _addLog(msg, level, tag: 'HTTP');
  }
}

final appLogger = AppLogger();

void d(String message, {String? tag}) => appLogger.d(message, tag: tag);
void i(String message, {String? tag}) => appLogger.i(message, tag: tag);
void w(String message, {String? tag}) => appLogger.w(message, tag: tag);
void e(String message, {Object? error, StackTrace? stackTrace, String? tag}) => appLogger.e(message, error: error, stackTrace: stackTrace, tag: tag);