import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HttpLogger {
  static final HttpLogger _instance = HttpLogger._internal();
  factory HttpLogger() => _instance;
  HttpLogger._internal();

  final List<HttpLogEntry> logs = [];
  static const int maxLogs = 500;

  void _logRequest(String method, String url, Map<String, String>? headers) {
    if (!kDebugMode) return;
    debugPrint('[HTTP] $method $url');
    if (headers != null) {
      debugPrint('[HTTP Headers] ${jsonEncode(headers)}');
    }
  }

  void _logResponse(String method, String url, int statusCode, String? body, DateTime startTime, DateTime endTime) {
    if (!kDebugMode) return;
    final duration = endTime.difference(startTime).inMilliseconds;
    debugPrint('[HTTP Response] $statusCode (${duration}ms) - $url');
    if (body != null) {
      if (body.length > 500) {
        debugPrint('[HTTP Body] ${body.substring(0, 500)}...');
      } else {
        debugPrint('[HTTP Body] $body');
      }
    }
    
    logs.insert(0, HttpLogEntry(
      method: method,
      url: url,
      statusCode: statusCode,
      responseBody: body,
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

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final HttpLogger _logger = HttpLogger();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final url = request.url.toString();
    final method = request.method;
    
    _logger._logRequest(method, url, request.headers);

    try {
      final streamedResponse = await _inner.send(request);
      final endTime = DateTime.now();
      
      final body = await streamedResponse.stream.bytesToString();
      
      _logger._logResponse(method, url, streamedResponse.statusCode, body, startTime, endTime);

      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        streamedResponse.statusCode,
        headers: streamedResponse.headers,
        reasonPhrase: streamedResponse.reasonPhrase,
        request: request,
      );
    } catch (e) {
      final endTime = DateTime.now();
      _logger._logResponse(method, url, 0, e.toString(), startTime, endTime);
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}