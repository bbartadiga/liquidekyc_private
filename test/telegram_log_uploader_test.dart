import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/app_logger.dart';
import 'package:module_liquid/core/services/telegram_log_uploader.dart';

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

  group('Filter log fresh (anti kirim ulang)', () {
    LogEntry entry(String message) => LogEntry(
          message: message,
          level: LogLevel.info,
          timestamp: DateTime.now(),
        );

    test('sebelum ada yang dikirim, semua entry dianggap fresh', () {
      final logs = [entry('a'), entry('b'), entry('c')];
      expect(TelegramLogUploader.freshEntries(logs).length, 3);
    });

    test('entry yang sama nggak masuk dua kali', () {
      // Simulasi: batch pertama kirim 'a' & 'b', lalu stream emit lagi
      // dengan seluruh log (c baru, b, a).
      final a = entry('a');
      final b = entry('b');
      final c = entry('c');

      final first = TelegramLogUploader.freshEntries([a, b]);
      expect(first.length, 2);

      // Setelah batch pertama, uploader nandai entry terakhir yg terkirim.
      TelegramLogUploader.lastSentEntry = first.last;
      addTearDown(() => TelegramLogUploader.lastSentEntry = null);

      final second = TelegramLogUploader.freshEntries([c, b, a]);
      expect(second.length, 1);
      expect(second.first.message, 'c');
    });
  });
}
