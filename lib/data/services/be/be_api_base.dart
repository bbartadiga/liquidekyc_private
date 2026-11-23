import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constant/liquid_constants.dart';
import '../../../core/services/app_logger.dart';
import '../kyc_retry_queue.dart';
import '../liquid_http_client.dart';
import 'be_api_config.dart';
import 'be_call_runner.dart';

typedef ProgressCallback = void Function(String step, bool isLoading);

/// Parser body response 2xx jadi model domain.
typedef BeResponseParser<T> = T Function(Map<String, dynamic> data);

/// Penulis model error dari status code + body response.
typedef BeErrorFactory<T> = T Function(int statusCode, String message);

/// Penentu hasil sukses untuk endpoint yang response body-nya opsional.
typedef BeSuccessHandler<T> = T Function(http.Response response);

/// Plumbing bersama semua endpoint Liquid Connector API (BE).
///
/// Tiap subclass cuma memegang endpoint domain-nya; base ini yang pegang
/// config host, header auth, retry/backoff, dan antrean retry offline.
abstract class BeApiBase {
  ProgressCallback? onProgress;

  final http.Client _client;
  final Random _random = Random();

  BeApiBase({http.Client? client}) : _client = client ?? LiquidHttpClient();

  // Host + API key mengikuti LiquidConfig (staging / production switch)
  String get baseUrl => beBaseUrl;

  String applicantUrl(String applicantId, String subPath) =>
      '$baseUrl$bePathApplicants/$applicantId/$subPath';

  /// Path relatif untuk disimpan di retry queue (tanpa host).
  String relativeApplicantPath(String applicantId, String subPath) =>
      '$bePathApplicants/$applicantId/$subPath';

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'X-Ekyc-Api-key': LiquidConfig.connectorApiKey,
      };

  /// True kalau kegagalan ini layak dicoba lagi.
  ///
  /// - 5xx → server-side, retry
  /// - 409 + kode transien (CE00004 / CE00008 / CE00017) → BE belum selesai
  /// - selain itu (403 / 404 / 409 dengan kode lain) → permanen, retry
  ///   cuma buang-buang request
  bool _isRetryable(int statusCode, String body) {
    if (statusCode >= 500) return true;
    if (statusCode == 409) return BeCallRunner.isTransientMessage(body);
    return false;
  }

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[KycBeApi] $message');
    }
  }

  Future<http.Response> sendGet(String url) => _client
      .get(Uri.parse(url), headers: headers)
      .timeout(beRequestTimeout);

  Future<http.Response> sendPost(String url, Map<String, dynamic> body) => _client
      .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
      .timeout(beRequestTimeout);

  /// Simpan request gagal ke retry queue supaya dikirim ulang nanti.
  Future<void> enqueueFailedRequest({
    required String applicantId,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = KycQueuedRequest(
        applicantId: applicantId,
        endpoint: endpoint,
        method: method,
        body: body,
      );

      await KycRetryQueue.enqueue(request);
      log('Enqueued failed request: $method $endpoint');
    } catch (e) {
      log('Failed to enqueue request: $e');
    }
  }

  /// GET sub-resource applicant dengan retry exponential backoff + jitter.
  ///
  /// Kalau seluruh percobaan gagal, request diantrekan ke [KycRetryQueue]
  /// lalu fungsi mengembalikan model error (bukan exception).
  Future<T> getWithRetry<T>({
    required String applicantId,
    required String url,
    required String endpoint,
    required String progressLabel,
    required BeResponseParser<T> parse,
    required BeErrorFactory<T> errorFactory,
    String Function(Map<String, dynamic> data)? successLog,
  }) async {
    var attempt = 0;
    var delayMs = beBaseRetryDelayMs;

    while (attempt <= beMaxRetries) {
      try {
        onProgress?.call('$progressLabel (attempt ${attempt + 1})', true);

        final response = await sendGet(url);

        log('Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          // JSON selalu UTF-8 (RFC 8259) → decode dari bodyBytes, bukan
          // `response.body` yang ikut charset header. Kalau BE nggak kirim
          // charset, nilai Jepang-nya jadi mojibake.
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final message = successLog?.call(data);
          if (message != null) log(message);
          onProgress?.call(progressLabel, false);
          return parse(data);
        }

        log('ERROR: ${response.statusCode} - ${response.body}');

        if (attempt < beMaxRetries && _isRetryable(response.statusCode, response.body)) {
          await _waitBeforeRetry(delayMs);
          delayMs *= 2;
          attempt++;
          continue;
        }

        await enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'GET',
        );

        onProgress?.call(progressLabel, false);
        return errorFactory(response.statusCode, response.body);
      } catch (e) {
        log('ERROR (attempt ${attempt + 1}): $e');

        if (attempt < beMaxRetries) {
          await _waitBeforeRetry(delayMs);
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call(progressLabel, false);

          await enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'GET',
          );

          return errorFactory(0, e.toString());
        }
      }
    }

    onProgress?.call(progressLabel, false);
    return errorFactory(0, 'Failed after retries');
  }

  /// POST dengan retry exponential backoff + jitter.
  ///
  /// Sama seperti [getWithRetry]: request gagal total diantrekan ke
  /// [KycRetryQueue] dan fungsi mengembalikan model error. Body response
  /// belum tentu berisi JSON, jadi parsing diserahkan ke [onSuccess].
  Future<T> postWithRetry<T>({
    required String applicantId,
    required String url,
    required String endpoint,
    required String progressLabel,
    required Map<String, dynamic> body,
    required BeSuccessHandler<T> onSuccess,
    required BeErrorFactory<T> errorFactory,
    String Function(http.Response response)? successLog,
    int? maxRetries,
  }) async {
    var attempt = 0;
    var delayMs = beBaseRetryDelayMs;
    final retryLimit = maxRetries ?? beMaxRetries;

    while (attempt <= retryLimit) {
      try {
        onProgress?.call('$progressLabel (attempt ${attempt + 1})', true);

        final response = await sendPost(url, body);

        log('Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final message = successLog?.call(response);
          if (message != null) log(message);
          onProgress?.call(progressLabel, false);
          return onSuccess(response);
        }

        log('ERROR: ${response.statusCode} - ${response.body}');

        if (attempt < retryLimit && _isRetryable(response.statusCode, response.body)) {
          await _waitBeforeRetry(delayMs);
          delayMs *= 2;
          attempt++;
          continue;
        }

        await enqueueFailedRequest(
          applicantId: applicantId,
          endpoint: endpoint,
          method: 'POST',
          body: body,
        );

        onProgress?.call(progressLabel, false);
        return errorFactory(response.statusCode, response.body);
      } catch (e) {
        // PENTING: masukkan ke appLogger — kalau cuma debugPrint, error ini
        // nggak kelihatan di halaman debug / export / Telegram.
        appLogger.e(
          '[BE] Error (attempt ${attempt + 1}) $endpoint: $e',
          error: e,
        );
        log('ERROR (attempt ${attempt + 1}): $e');

        if (attempt < retryLimit) {
          await _waitBeforeRetry(delayMs);
          delayMs *= 2;
          attempt++;
        } else {
          onProgress?.call(progressLabel, false);

          await enqueueFailedRequest(
            applicantId: applicantId,
            endpoint: endpoint,
            method: 'POST',
            body: body,
          );

          return errorFactory(0, e.toString());
        }
      }
    }

    onProgress?.call(progressLabel, false);
    return errorFactory(0, 'Failed after retries');
  }

  /// Parse body response jadi Map — null kalau body-nya kosong / bukan JSON.
  ///
  /// Body 2xx dari BE kadang kosong atau bentuknya beda dari spec. Kalau
  /// parsing-nya lempar exception, request yang udah sukses malah dianggap
  /// gagal lalu di-retry → BE balas 409 dan datanya jadi dobel.
  Map<String, dynamic>? parseJsonBody(http.Response response) {
    try {
      if (response.bodyBytes.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      appLogger.w(
        '[BE] Body response bukan JSON object (HTTP ${response.statusCode}) '
        '— tetap dianggap sukses',
        tag: 'BE',
      );
      return null;
    } catch (e) {
      appLogger.w(
        '[BE] Body response gagal di-parse (HTTP ${response.statusCode}): $e '
        '— tetap dianggap sukses',
        tag: 'BE',
      );
      return null;
    }
  }

  /// Tunggu backoff + jitter acak supaya retry tidak menumpuk bareng.
  Future<void> _waitBeforeRetry(int delayMs) async {
    log('Retrying in ${delayMs}ms...');
    await Future.delayed(Duration(milliseconds: delayMs + _random.nextInt(500)));
  }
}
