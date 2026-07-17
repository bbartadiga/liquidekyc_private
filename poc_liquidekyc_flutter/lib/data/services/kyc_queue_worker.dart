import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'kyc_retry_queue.dart';

typedef QueueRetryCallback = void Function(String endpoint, bool success, String? error);

class KycQueueWorker {
  static Timer? _timer;
  static bool _isProcessing = false;
  static QueueRetryCallback? _onRetryComplete;
  static http.Client? _client;
  
  static const Duration _checkInterval = Duration(minutes: 5);
  
  static void initialize({QueueRetryCallback? onRetryComplete}) {
    _onRetryComplete = onRetryComplete;
    _client = http.Client();
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
      
      if (request.method.toUpperCase() == 'GET') {
        response = await _client!.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      } else {
        response = await _client!.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: request.body != null ? _encodeBody(request.body!) : null,
        ).timeout(const Duration(seconds: 30));
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
  
  static String _buildUrl(KycQueuedRequest request) {
    return '${request.endpoint}';
  }
  
  static String _encodeBody(Map<String, dynamic> body) {
    return body.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value?.toString() ?? '')}').join('&');
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