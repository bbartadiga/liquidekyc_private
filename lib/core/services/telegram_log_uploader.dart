import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'log_sanitizer.dart';

class TelegramLogUploader {
  // TODO(poc): move ke env vars (.env/secrets) sebelum production
  static const String _botToken = '9024664039:AAFccddyHQB8sJoGxNoR2OygN3_YFZ1j93Y';
  static const String _chatId = '374215625';
  static const String _apiUrl = 'https://api.telegram.org/bot$_botToken/sendMessage';
  static const Duration _httpTimeout = Duration(seconds: 5);
  static const int _maxStackLength = 400;

  static const Set<String> _uploadLevels = {'DEBUG', 'WARNING', 'ERROR', 'INFO'};

  /// Tag log dari sisi native (Liquid SDK).
  static const String _nativeTag = 'Native';

  /// Maksimal log native per batch Telegram.
  ///
  /// Log native ikut dikirim (biar diagnosa SDK ikut terkirim), tapi dibatasi
  /// supaya nggak menimpa log aplikasi yang lebih penting.
  static const int _maxNativePerBatch = 8;

  static StreamSubscription<List<LogEntry>>? _subscription;
  static bool _enabled = true;
  static DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  static final int _minIntervalMs = 500;
  static final int _maxBatchSize = 30;
  static LogLevel _minLevel = LogLevel.warning;

  /// Entry terakhir yang sudah dikirim.
  ///
  /// Stream [AppLogger] mengirim SELURUH log tiap kali ada entry baru, jadi
  /// tanpa penanda ini, entry lama bakal dikirim ulang terus (spam Telegram)
  /// tiap kali ada log baru.
  static LogEntry? _lastSentEntry;

  static bool get enabled => _enabled;
  static set enabled(bool value) {
    _enabled = value;
    appLogger.i('[TelegramLogUploader] enabled=$value');
  }

  /// Subscribe ke log stream. Panggil sekali di main.dart setelah appLogger.init().
  static void init({LogLevel minLevel = LogLevel.warning}) {
    _minLevel = minLevel;
    _subscription?.cancel();
    appLogger.init();
    _subscription = appLogger.stream.listen(_handleNewLogs);
    appLogger.i('[TelegramLogUploader] initialized, minLevel=${minLevel.label}');
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _handleNewLogs(List<LogEntry> allLogs) {
    if (!_enabled || allLogs.isEmpty) return;

    // Ambil cuma entry yang belum pernah dikirim.
    final fresh = freshEntries(allLogs);
    if (fresh.isEmpty) return;

    final newOnes = <LogEntry>[];
    final nativeOnes = <LogEntry>[];
    for (final entry in fresh) {
      if (entry.level.priority >= _minLevel.priority &&
          _uploadLevels.contains(entry.level.label)) {
        if (entry.tag == _nativeTag) {
          nativeOnes.add(entry);
        } else {
          newOnes.add(entry);
        }
      }
    }

    // Log native ikut, tapi dibatasi — jangan sampai nutup log aplikasi.
    newOnes.addAll(nativeOnes.take(_maxNativePerBatch));

    if (newOnes.isEmpty) return;

    // Throttle: batch logs dan kirim setelah delay window
    Future.delayed(Duration(milliseconds: _minIntervalMs), () {
      _sendBatch(newOnes.take(_maxBatchSize).toList());
    });
  }

  /// Entry yang belum pernah dikirim (allLogs urut terbaru di depan).
  @visibleForTesting
  static List<LogEntry> freshEntries(List<LogEntry> allLogs) {
    final last = _lastSentEntry;
    if (last == null) return allLogs;

    final index = allLogs.indexWhere((entry) => identical(entry, last));
    // Log lama udah ke-truncate dari AppLogger → kirim semua yang ada.
    if (index < 0) return allLogs;
    return allLogs.sublist(0, index);
  }

  /// Entry terakhir yang sudah dikirim (untuk testing).
  @visibleForTesting
  static set lastSentEntry(LogEntry? entry) => _lastSentEntry = entry;

  @visibleForTesting
  static LogEntry? get lastSentEntry => _lastSentEntry;

  static Future<void> _sendBatch(List<LogEntry> entries) async {
    if (entries.isEmpty) return;
    final now = DateTime.now();
    final sinceLast = now.difference(_lastSentAt).inMilliseconds;
    if (sinceLast < _minIntervalMs) {
      return;
    }
    _lastSentAt = now;

    // Tandai entry terakhir yang terkirim, biar batch berikutnya cuma nirim
    // yang baru.
    _lastSentEntry = entries.last;

    // Summary by level + tag
    final byLevel = <String, int>{};
    final byTag = <String, int>{};
    for (final e in entries) {
      byLevel[e.level.label] = (byLevel[e.level.label] ?? 0) + 1;
      final tag = e.tag ?? '-';
      byTag[tag] = (byTag[tag] ?? 0) + 1;
    }
    final levelSummary = byLevel.entries.map((e) => '${e.key}:${e.value}').join(' ');
    final tagSummary = (byTag.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '${e.key}(${e.value})')
        .join(', ');

    final buffer = StringBuffer();
    // Header: tanpa emoji (HTML <b> sudah cukup sebagai visual marker)
    buffer.writeln('<b>Liquid eKYC — ${entries.length} log(s)</b>');
    buffer.writeln('App: 1.0.0+1 | Device: ${defaultTargetPlatform.name}');
    buffer.writeln('Levels: $levelSummary');
    if (tagSummary.isNotEmpty) buffer.writeln('Top tags: $tagSummary');
    buffer.writeln('---');

    for (final entry in entries) {
      final tag = entry.tag ?? '-';
      final msg = LogSanitizer.sanitize(entry.message);
      buffer.writeln(
          '<b>[${entry.level.label}]</b> [${_escape(tag)}] ${_escape(msg)}');
      if (entry.error != null) {
        final errStr = entry.error.toString();
        final cleaned = LogSanitizer.sanitize(errStr);
        buffer.writeln(
            '• Err: <code>${_escape(cleaned.substring(0, min(cleaned.length, 250)))}</code>');
      }
      if (entry.stackTrace != null) {
        final st = entry.stackTrace.toString();
        buffer.writeln(
            '• Stack: <code>${_escape(st.substring(0, min(st.length, _maxStackLength)))}</code>');
      }
    }

    final text = buffer.toString();
    if (text.length > 3800) {
      // Truncate kalau kelebihan (Telegram limit 4096)
      await _postToTelegram('${text.substring(0, 3800)}\n\n…(truncated)');
    } else {
      await _postToTelegram(text);
    }
  }

  static Future<void> _postToTelegram(String text) async {
    if (kDebugMode) {
      debugPrint(
          '[TelegramLogUploader→TG] ${text.substring(0, min(text.length, 200))}...');
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'chat_id': _chatId,
              'text': text,
              'parse_mode': 'HTML',
              'disable_web_page_preview': true,
            }),
          )
          .timeout(_httpTimeout);

      if (response.statusCode != 200) {
        debugPrint(
            '[TelegramLogUploader] TG returned ${response.statusCode}: ${response.body.substring(0, min(response.body.length, 200))}');
      }
    } catch (e) {
      debugPrint('[TelegramLogUploader] Failed: $e');
    }
  }

  static String _escape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
