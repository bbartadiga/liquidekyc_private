import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_logger.dart';

class TelegramLogUploader {
  // TODO(poc): move ke env vars (.env/secrets) sebelum production
  static const String _botToken = '9024664039:AAFccddyHQB8sJoGxNoR2OygN3_YFZ1j93Y';
  static const String _chatId = '374215625';
  static const String _apiUrl = 'https://api.telegram.org/bot$_botToken/sendMessage';
  static const Duration _httpTimeout = Duration(seconds: 5);
  static const int _maxStackLength = 400;

  static const Set<String> _sensitiveKeys = {
    'name', 'name_kana', 'nameKana',
    'full_name', 'fullName',
    'previous_name', 'previousName', 'former_name', 'formerName',
    'birthday', 'dateOfBirth', 'date_of_birth',
    'address', 'full_address', 'fullAddress',
    'address_pref', 'addressPref', 'addressPrefecture',
    'address_city', 'addressCity',
    'address_other', 'addressOther',
    'zipCode', 'zip_code',
    'id_number', 'idNumber', 'id_document_number',
    'nationality',
    'my_number', 'myNumber',
    'serialNumber', 'municipalityName',
    'resident_status', 'residentStatus',
    'stay_period', 'stayPeriod',
    'phoneNumber', 'phone_number',
    'email', 'mailAddress',
    'idFacePhoto', 'id_face_photo', 'face_photo',
    'documentImage', 'document_image',
    // Auth credentials
    'token', 'access_token', 'refresh_token',
    'x-api-key', 'x_ekyc_api_key', 'X-Ekyc-Api-key',
    'api_key', 'apikey', 'apiKey',
    'authorization', 'Authorization',
    'password', 'secret',
  };

  static const Set<String> _uploadLevels = {'DEBUG', 'WARNING', 'ERROR', 'INFO'};

  static StreamSubscription<List<LogEntry>>? _subscription;
  static int _lastSeenIndex = 0;
  static bool _enabled = true;
  static DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  static int _minIntervalMs = 500;
  static int _maxBatchSize = 30;
  static LogLevel _minLevel = LogLevel.warning;

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

    // Stream emit all logs reversed (newest first)
    final newOnes = <LogEntry>[];
    for (final entry in allLogs) {
      if (entry.level.priority >= _minLevel.priority &&
          _uploadLevels.contains(entry.level.label)) {
        newOnes.add(entry);
      }
    }

    if (newOnes.isEmpty) return;

    // Throttle: batch logs dan kirim setelah delay window
    Future.delayed(Duration(milliseconds: _minIntervalMs), () {
      _sendBatch(newOnes.take(_maxBatchSize).toList());
    });
    _lastSeenIndex = allLogs.length;
  }

  static Future<void> _sendBatch(List<LogEntry> entries) async {
    if (entries.isEmpty) return;
    final now = DateTime.now();
    final sinceLast = now.difference(_lastSentAt).inMilliseconds;
    if (sinceLast < _minIntervalMs) {
      return;
    }
    _lastSentAt = now;

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
      final msg = _sanitize(entry.message);
      buffer.writeln(
          '<b>[${entry.level.label}]</b> [${_escape(tag)}] ${_escape(msg)}');
      if (entry.error != null) {
        final errStr = entry.error.toString();
        final cleaned = _sanitize(errStr);
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
      await _postToTelegram(text.substring(0, 3800) + '\n\n…(truncated)');
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

  /// Mask sensitive data dari text sebelum dikirim.
  static String _sanitize(String text) {
    if (text.isEmpty) return text;
    String out = text;

    // Email
    out = out.replaceAllMapped(
      RegExp(r'[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}'),
      (m) => '***@***',
    );

    // Panjang digit sequence (cards, MyNumber)
    out = out.replaceAllMapped(
      RegExp(r'\b\d{12,}\b'),
      (m) => '****',
    );

    // Sensitive key=value patterns
    for (final key in _sensitiveKeys) {
      out = out.replaceAllMapped(
        RegExp('"$key"\\s*:\\s*"[^"]*"', caseSensitive: false),
        (m) => '"$key":"***"',
      );
      out = out.replaceAllMapped(
        RegExp('$key\\s*[:=]\\s*([^,\\s}]+)', caseSensitive: false),
        (m) => '$key=***',
      );
    }

    return out;
  }

  static String _escape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
