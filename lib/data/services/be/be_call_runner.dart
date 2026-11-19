import 'package:flutter/foundation.dart';

import '../../../core/services/app_logger.dart';

/// Jeda minimal antar panggilan Connector API (BE).
///
/// G01 API List, catatan tiap API:
/// *"Make sure to call after a 1 second interval with several retries"*
///
///liquid memproses request di database-nya secara asinkron, jadi panggilan
/// yang menyusul request sebelumnya bisa kena error (CE00008 / CE00017)
/// kalau jaraknya terlalu dekat.
class BeCallRunner {
  BeCallRunner({
    this.spacing = const Duration(seconds: 1),
    this.maxAttempts = 3,
  });

  /// Jeda antar panggilan.
  final Duration spacing;

  /// Berapa kali percobaan kalau error-nya bersifat transien.
  final int maxAttempts;

  DateTime? _lastCallAt;

  /// Kode error BE yang artinya "data belum siap" → layak dicoba lagi.
  ///
  /// - CE00004: KYC operation belum selesai
  /// - CE00008: KYC application belum selesai
  /// - CE00017: OCR / verification belum dijalankan
  static const Set<String> transientErrorCodes = {
    'CE00004',
    'CE00008',
    'CE00017',
  };

  /// Jalankan [call] dengan jeda dari panggilan sebelumnya.
  Future<T> run<T>(Future<T> Function() call) async {
    await _waitForSpacing();
    _lastCallAt = DateTime.now();
    return call();
  }

  /// Jalankan [call], dan ulangi kalau hasilnya [isTransient].
  Future<T> runWithRetry<T>(
    Future<T> Function() call, {
    required bool Function(T result) isTransient,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final result = await run(call);

      if (!isTransient(result) || attempt == maxAttempts) {
        return result;
      }

      appLogger.w(
        '[BE] Error transien → retry ${attempt + 1}/$maxAttempts '
        'setelah ${spacing.inSeconds}s',
      );
    }

    // Loop selalu return di attempt terakhir.
    throw StateError('unreachable');
  }

  Future<void> _waitForSpacing() async {
    final last = _lastCallAt;
    if (last == null) return;

    final elapsed = DateTime.now().difference(last);
    if (elapsed >= spacing) return;

    final wait = spacing - elapsed;
    if (kDebugMode) {
      debugPrint('[BE] spacing wait ${wait.inMilliseconds}ms');
    }
    await Future.delayed(wait);
  }

  /// Ambil kode error BE (mis. "CE00019") dari pesan error yang disimpan
  /// di model response — body error BE disimpan sebagai JSON string.
  static String? extractErrorCode(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) return null;
    final match = RegExp(r'"error_code"\s*:\s*"(CE\d+)"').firstMatch(errorMessage);
    return match?.group(1);
  }

  /// true kalau [errorMessage] berisi kode error yang transien.
  static bool isTransientMessage(String? errorMessage) {
    final code = extractErrorCode(errorMessage);
    if (code == null) return false;
    return transientErrorCodes.contains(code);
  }
}
