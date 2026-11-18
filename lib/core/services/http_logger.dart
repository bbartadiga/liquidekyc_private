import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

class HttpLogger {
  static final HttpLogger _instance = HttpLogger._internal();
  factory HttpLogger() => _instance;
  HttpLogger._internal();

  final List<HttpLogEntry> logs = [];
  static const int maxLogs = 500;
  static const int _bodyPreviewLength = 220;
  static const int maxCapturedBytes = 64 * 1024;

  static const Set<String> _sensitiveHeaders = {
    'x-ekyc-api-key',
    'x-api-key',
    'authorization',
  };

  void logRequest(
    String method,
    String url,
    Map<String, String>? headers, {
    String? body,
  }) {
    if (kDebugMode) {
      debugPrint('[HTTP] $method $url');
      if (headers != null) {
        debugPrint('[HTTP Headers] ${jsonEncode(_maskHeaders(headers))}');
      }
      if (body != null && body.isNotEmpty) {
        debugPrint('[HTTP Request Body] $body');
      }
    }

    final maskedHeaders = _maskHeaders(headers);
    final headerLine = maskedHeaders.isEmpty
        ? ''
        : ' headers=${jsonEncode(maskedHeaders)}';
    final bodyLine = (body != null && body.isNotEmpty) ? ' body=$body' : '';

    appLogger.i('[HTTP] $method $url$headerLine$bodyLine', tag: 'HTTP-REQ');
  }

  void logResponse(
    String method,
    String url,
    int statusCode,
    String? body,
    DateTime startTime,
    DateTime endTime,
  ) {
    final duration = endTime.difference(startTime).inMilliseconds;
    final isError = statusCode >= 400;

    if (kDebugMode) {
      debugPrint('[HTTP Response] $statusCode (${duration}ms) - $url');
      if (body != null && body.isNotEmpty) {
        final limit = body.length > 500 ? 500 : body.length;
        debugPrint('[HTTP Body] ${body.substring(0, limit)}${body.length > 500 ? '...' : ''}');
      }
    }

    // Body preview hanya dikirim ke Telegram untuk error response (4xx/5xx/0).
    // Success response cukup disimpan di log entry supaya bisa dilihat di app.
    String bodyLine = '';
    if (body != null && body.isNotEmpty && isError) {
      final preview = body.length > _bodyPreviewLength
          ? '${body.substring(0, _bodyPreviewLength)}…(${body.length}b)'
          : body;
      bodyLine = '\nBody: $preview';
    }

    final fullMessage = '[$method] $url → $statusCode (${duration}ms)$bodyLine';

    if (isError) {
      appLogger.e(fullMessage, tag: 'HTTP-RESP');
    } else {
      appLogger.i(fullMessage, tag: 'HTTP-RESP');
    }

    logs.insert(0, HttpLogEntry(
      method: method,
      url: url,
      statusCode: statusCode,
      responseBody: _preview(body),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
    ));

    if (logs.length > maxLogs) {
      logs.removeLast();
    }
  }

  void clear() {
    logs.clear();
  }

  List<HttpLogEntry> getAll() => List.unmodifiable(logs);

  Map<String, String> _maskHeaders(Map<String, String>? headers) {
    if (headers == null) return const {};
    final masked = <String, String>{};
    headers.forEach((key, value) {
      masked[key] = _sensitiveHeaders.contains(key.toLowerCase())
          ? '***'
          : value;
    });
    return masked;
  }

  String? _preview(String? body) {
    if (body == null || body.isEmpty) return null;
    if (body.length <= _bodyPreviewLength) return body;
    return '${body.substring(0, _bodyPreviewLength)}…(${body.length}b)';
  }
}

class HttpLogEntry {
  final String method;
  final String url;
  final int statusCode;
  final String? responseBody;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;

  HttpLogEntry({
    required this.method,
    required this.url,
    required this.statusCode,
    this.responseBody,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => statusCode >= 400;
}
