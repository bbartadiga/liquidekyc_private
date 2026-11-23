import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/data/services/be/be_call_runner.dart';

/// Retry policy BE — BeCallRunner.
void main() {
  group('BeCallRunner.runWithRetry', () {
    test('percobaan mengikuti maxAttempts default', () async {
      var calls = 0;
      final runner = BeCallRunner(spacing: Duration.zero);

      await runner.runWithRetry<int>(
        () async {
          calls++;
          return 0;
        },
        isTransient: (r) => r == 0,
      );

      expect(calls, runner.maxAttempts);
    });

    test('berhenti langsung kalau hasilnya bukan transien', () async {
      var calls = 0;
      final runner = BeCallRunner(spacing: Duration.zero);

      await runner.runWithRetry<int>(
        () async {
          calls++;
          return 1;
        },
        isTransient: (r) => r == 0,
      );

      expect(calls, 1);
    });

    test('nilai terakhir dikembalikan setelah semua percobaan gagal', () async {
      final runner = BeCallRunner(spacing: Duration.zero);

      final result = await runner.runWithRetry<int>(
        () async => 0,
        isTransient: (r) => r == 0,
      );

      expect(result, 0);
    });
  });

  group('BeCallRunner.isTransientMessage', () {
    test('CE00004 / CE00008 / CE00017 transien', () {
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00004"}'),
        isTrue,
      );
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00008"}'),
        isTrue,
      );
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00017"}'),
        isTrue,
      );
    });

    test('CE00019 (OCR nggak tersedia) & CE00003 bukan transien', () {
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00019"}'),
        isFalse,
      );
      expect(
        BeCallRunner.isTransientMessage('{"error_code":"CE00003"}'),
        isFalse,
      );
      expect(BeCallRunner.isTransientMessage(null), isFalse);
    });
  });
}
