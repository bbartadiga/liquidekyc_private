import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/services/http_logger.dart';

/// HTTP client untuk semua request ke Liquid Connector API.
///
/// - Badge sertifikat self-signed (proxy BNI pakai sertifikat internal)
/// - Request + response otomatis masuk ke [HttpLogger] (debug mode & release mode)
/// - Body response hanya ditangkap 64KB pertama supaya endpoint foto (base64)
///   tidak habisin memory
class LiquidHttpClient extends http.BaseClient {
  final HttpClient _ioClient;
  final HttpLogger _logger = HttpLogger();

  LiquidHttpClient({bool allowSelfSignedCertificate = true})
      : _ioClient = HttpClient() {
    if (allowSelfSignedCertificate) {
      _ioClient.badCertificateCallback = (cert, host, port) => true;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final url = request.url.toString();
    final method = request.method;

    final headers = <String, String>{};
    request.headers.forEach((key, value) => headers[key] = value);

    _logger.logRequest(method, url, headers,
        body: request is http.Request && request.bodyBytes.isNotEmpty
            ? utf8.decode(request.bodyBytes, allowMalformed: true)
            : null);

    try {
      final ioRequest = await _ioClient.openUrl(request.method, request.url);
      request.headers.forEach((key, value) {
        ioRequest.headers.set(key, value);
      });
      if (request is http.Request && request.bodyBytes.isNotEmpty) {
        ioRequest.add(request.bodyBytes);
      }
      final ioResponse = await ioRequest.close();
      final responseHeaders = <String, String>{};
      ioResponse.headers.forEach((key, values) {
        responseHeaders[key] = values.join(',');
      });

      // Tangkap sebagian body tanpa menghabiskan stream (body foto bisa besar)
      final captured = <int>[];
      final stream = ioResponse.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            if (captured.length < HttpLogger.maxCapturedBytes) {
              captured.addAll(
                  data.take(HttpLogger.maxCapturedBytes - captured.length));
            }
            sink.add(data);
          },
          handleDone: (sink) {
            _logger.logResponse(
              method,
              url,
              ioResponse.statusCode,
              utf8.decode(captured, allowMalformed: true),
              startTime,
              DateTime.now(),
            );
            sink.close();
          },
        ),
      );

      return http.StreamedResponse(
        stream,
        ioResponse.statusCode,
        headers: responseHeaders,
        reasonPhrase: ioResponse.reasonPhrase,
        request: request,
      );
    } catch (e) {
      _logger.logResponse(method, url, 0, e.toString(), startTime, DateTime.now());
      rethrow;
    }
  }

  @override
  void close() {
    _ioClient.close();
    super.close();
  }
}
