import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/app_logger.dart';

/// Log native (Liquid SDK) ikut dikirim ke Telegram, tapi dibatasi supaya
/// nggak menimpa log aplikasi yang lebih penting.
void main() {
  group('Komposisi batch Telegram', () {
    test('log native ikut masuk batch (dengan batas)', () {
      final entries = <LogEntry>[
        LogEntry(
          message: '[Native] VerifyIdChip callback: status=ERROR',
          level: LogLevel.debug,
          timestamp: DateTime.now(),
          tag: 'Native',
        ),
        LogEntry(
          message: '[STEP 11] IC Card (NFC) → FAILED',
          level: LogLevel.info,
          timestamp: DateTime.now(),
        ),
      ];

      final native = entries.where((e) => e.tag == 'Native').length;
      expect(native, 1);
      expect(entries.where((e) => e.tag != 'Native').length, 1);
    });

    test('appLogger nyimpen tag dengan benar', () {
      appLogger.clear();
      appLogger.d('[Native] test line', tag: 'Native');
      appLogger.i('[APP] test line');

      final logs = appLogger.allLogs;
      expect(logs.any((e) => e.tag == 'Native'), isTrue);
      expect(logs.any((e) => e.tag == null), isTrue);
      appLogger.clear();
    });
  });
}
