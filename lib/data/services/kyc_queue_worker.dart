import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constant/liquid_constants.dart';
import 'be/be_api_config.dart';
import 'kyc_retry_queue.dart';
import 'liquid_http_client.dart';

typedef QueueRetryCallback = void Function(String endpoint, bool success, String? error);

class KycQueueWorker {
  static Timer? _timer;
  static bool _isProcessing = false;
  static QueueRetryCallback? _onRetryComplete;
  static http.Client? _client;

  static const Duration _checkInterval = Duration(minutes: 5);

  /// Timeout sama dengan request BE biasa.
  static const Duration _requestTimeout = Duration(seconds: 60);

  static void initialize({
    QueueRetryCallback? onRetryComplete,
    http.Client? client,
  }) {
    _onRetryComplete = onRetryComplete;
    _client = client ?? LiquidHttpClient();
    _log('QueueWorker initialized');
  }
  
  static void start() {
    if (_timer != null && _timer!.isActive) {
      _log('QueueWorker already running');
      return;
    }
    
    _log('QueueWorker started - checking every ${_checkInterval.inMinutes} minutes');
    _timer = Timer.periodic(_checkInterval, (_) => processQueue());
    
    processQueue();
  }
  
  static void stop() {
    _timer?.cancel();
    _timer = null;
    _log('QueueWorker stopped');
  }
  
  static Future<void> processQueue() async {
    if (_isProcessing) {
      _log('Already processing queue, skipping...');
      return;
    }
    
    _isProcessing = true;
    
    try {
      await KycRetryQueue.removeExpired();
      
      final pendingRequests = await KycRetryQueue.getPendingRequests();
      
      if (pendingRequests.isEmpty) {
        _log('No pending requests in queue');
        return;
      }
      
      _log('Processing ${pendingRequests.length} queued requests');
      
      for (final request in pendingRequests) {
        if (request.nextRetryAt != null && DateTime.now().isBefore(request.nextRetryAt!)) {
          _log('Skipping ${request.endpoint} - not time for retry yet');
          continue;
        }
        
        final success = await _retryRequest(request);
        
        _onRetryComplete?.call(
          request.endpoint,
          success,
          success ? null : 'Retry failed after ${request.retryCount + 1} attempts',
        );
      }
    } catch (e) {
      _log('Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  static Future<bool> _retryRequest(KycQueuedRequest request) async {
    _log('Retrying ${request.description} (attempt ${request.retryCount + 1})');
    
    try {
      http.Response response;
      final url = _buildUrl(request);
      final headers = {
        'Content-Type': 'application/json',
        'X-Ekyc-Api-key': LiquidConfig.connectorApiKey,
      };

      if (request.method.toUpperCase() == 'GET') {
        response = await _client!
            .get(Uri.parse(url), headers: headers)
            .timeout(_requestTimeout);
      } else {
        response = await _client!
            .post(
              Uri.parse(url),
              headers: headers,
              body: request.body != null ? _encodeBody(request.body!) : null,
            )
            .timeout(_requestTimeout);
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('Retry SUCCESS for ${request.description}');
        await KycRetryQueue.dequeue(request.applicantId, request.endpoint);
        return true;
      }
      
      _log('Retry failed with status ${response.statusCode}: ${response.body}');
      await _incrementRetryCount(request);
      return false;
    } catch (e) {
      _log('Retry error for ${request.description}: $e');
      await _incrementRetryCount(request);
      return false;
    }
  }
  
  /// Endpoint di queue disimpan sebagai path relatif (tanpa host),
  /// jadi harus digabung dengan base URL BE sebelum dipanggil.
  static String _buildUrl(KycQueuedRequest request) {
    if (request.endpoint.startsWith('http')) {
      return request.endpoint;
    }
    return '$beBaseUrl${request.endpoint}';
  }

  /// BE expect JSON, bukan form-urlencoded.
  static String _encodeBody(Map<String, dynamic> body) {
    return jsonEncode(body);
  }
  
  static Future<void> _incrementRetryCount(KycQueuedRequest request) async {
    final updatedRequest = request.copyWith(
      retryCount: request.retryCount + 1,
      nextRetryAt: DateTime.now().add(
        Duration(minutes: 5 * (request.retryCount + 1)),
      ),
    );
    
    await KycRetryQueue.enqueue(updatedRequest);
  }
  
  static Future<int> getPendingCount() async {
    return KycRetryQueue.getPendingCount();
  }
  
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[KycQueueWorker] $message');
    }
  }
  
  static void dispose() {
    stop();
    _client?.close();
    _client = null;
  }
}