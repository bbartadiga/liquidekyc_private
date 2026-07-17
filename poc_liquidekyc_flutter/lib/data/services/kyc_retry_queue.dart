import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycRetryQueue {
  static const String _queueKey = 'kyc_retry_queue';
  static const String _pendingCountKey = 'kyc_pending_count';
  
  static const int maxRetries = 3;
  static const Duration maxQueueAge = Duration(hours: 24);
  static const Duration retryInterval = Duration(minutes: 5);
  
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _preferences {
    if (_prefs == null) {
      throw Exception('KycRetryQueue not initialized. Call init() first.');
    }
    return _prefs!;
  }

  static Future<void> enqueue(KycQueuedRequest request) async {
    final queue = await _getQueue();
    
    final existingIndex = queue.indexWhere(
      (r) => r.applicantId == request.applicantId && r.endpoint == request.endpoint,
    );
    
    if (existingIndex >= 0) {
      queue[existingIndex] = request;
    } else {
      queue.add(request);
    }
    
    await _saveQueue(queue);
    _log('Enqueued: ${request.endpoint} for ${request.applicantId}');
  }

  static Future<void> dequeue(String applicantId, String endpoint) async {
    final queue = await _getQueue();
    queue.removeWhere(
      (r) => r.applicantId == applicantId && r.endpoint == endpoint,
    );
    await _saveQueue(queue);
    _log('Dequeued: $endpoint for $applicantId');
  }

  static Future<List<KycQueuedRequest>> getPendingRequests() async {
    final queue = await _getQueue();
    final now = DateTime.now();
    
    final validRequests = queue.where((r) {
      final age = now.difference(r.queuedAt);
      return age < maxQueueAge && r.retryCount < maxRetries;
    }).toList();
    
    if (validRequests.length != queue.length) {
      await _saveQueue(validRequests);
    }
    
    return validRequests;
  }

  static Future<int> getPendingCount() async {
    final requests = await getPendingRequests();
    return requests.length;
  }

  static Future<void> clearQueue() async {
    await _preferences.remove(_queueKey);
    await _preferences.remove(_pendingCountKey);
    _log('Queue cleared');
  }

  static Future<void> removeExpired() async {
    final queue = await _getQueue();
    final now = DateTime.now();
    
    queue.removeWhere((r) {
      final age = now.difference(r.queuedAt);
      return age >= maxQueueAge || r.retryCount >= maxRetries;
    });
    
    await _saveQueue(queue);
    _log('Removed expired requests. Remaining: ${queue.length}');
  }

  static Future<List<KycQueuedRequest>> _getQueue() async {
    final jsonString = _preferences.getString(_queueKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => KycQueuedRequest.fromJson(json)).toList();
    } catch (e) {
      _log('Error parsing queue: $e');
      return [];
    }
  }

  static Future<void> _saveQueue(List<KycQueuedRequest> queue) async {
    final jsonString = jsonEncode(queue.map((r) => r.toJson()).toList());
    await _preferences.setString(_queueKey, jsonString);
    await _preferences.setInt(_pendingCountKey, queue.length);
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[KycRetryQueue] $message');
    }
  }
}

class KycQueuedRequest {
  final String applicantId;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final int retryCount;
  final DateTime queuedAt;
  final DateTime? nextRetryAt;

  KycQueuedRequest({
    required this.applicantId,
    required this.endpoint,
    required this.method,
    this.body,
    this.retryCount = 0,
    DateTime? queuedAt,
    this.nextRetryAt,
  }) : queuedAt = queuedAt ?? DateTime.now();

  KycQueuedRequest copyWith({
    String? applicantId,
    String? endpoint,
    String? method,
    Map<String, dynamic>? body,
    int? retryCount,
    DateTime? queuedAt,
    DateTime? nextRetryAt,
  }) {
    return KycQueuedRequest(
      applicantId: applicantId ?? this.applicantId,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      body: body ?? this.body,
      retryCount: retryCount ?? this.retryCount,
      queuedAt: queuedAt ?? this.queuedAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicantId': applicantId,
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'retryCount': retryCount,
      'queuedAt': queuedAt.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
    };
  }

  factory KycQueuedRequest.fromJson(Map<String, dynamic> json) {
    return KycQueuedRequest(
      applicantId: json['applicantId'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      body: json['body'] as Map<String, dynamic>?,
      retryCount: json['retryCount'] as int? ?? 0,
      queuedAt: json['queuedAt'] != null 
          ? DateTime.parse(json['queuedAt'] as String) 
          : DateTime.now(),
      nextRetryAt: json['nextRetryAt'] != null 
          ? DateTime.parse(json['nextRetryAt'] as String) 
          : null,
    );
  }

  String get description => '$method $endpoint ($applicantId)';
}