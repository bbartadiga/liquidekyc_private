import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/chip_attempt_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaman percobaan baca chip.
///
/// Counter ada di IC chip kartu, jadi restart app nggak bisa reset — makanya
/// counter-nya disimpan di perangkat.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ChipAttemptGuard.init();
    await ChipAttemptGuard.reset();
  });

  test('awal: boleh mencoba, 0 kegagalan', () {
    expect(ChipAttemptGuard.failedAttempts, 0);
    expect(ChipAttemptGuard.canAttempt, isTrue);
    expect(ChipAttemptGuard.attemptsLeft, ChipAttemptGuard.maxAttempts);
  });

  test('kegagalan dicatat & counter naik', () async {
    await ChipAttemptGuard.recordFailure('SE20005');

    expect(ChipAttemptGuard.failedAttempts, 1);
    expect(ChipAttemptGuard.lastErrorCode, 'SE20005');
    expect(ChipAttemptGuard.canAttempt, isTrue);
    expect(ChipAttemptGuard.attemptsLeft, ChipAttemptGuard.maxAttempts - 1);
  });

  test('counter bertahan setelah init ulang (tidak reset oleh restart app)', () async {
    await ChipAttemptGuard.recordFailure('SE20005');
    await ChipAttemptGuard.recordFailure('SE20015');

    // Simulasikan restart app: prefs baru, tapi nilai tersimpan tetap ada
    SharedPreferences.setMockInitialValues({});
    await ChipAttemptGuard.init();

    expect(ChipAttemptGuard.failedAttempts, 2);
  });

  test('setelah max attempts → diblokir', () async {
    for (var i = 0; i < ChipAttemptGuard.maxAttempts; i++) {
      await ChipAttemptGuard.recordFailure('SE20005');
    }

    expect(ChipAttemptGuard.failedAttempts, ChipAttemptGuard.maxAttempts);
    expect(ChipAttemptGuard.canAttempt, isFalse);
    expect(ChipAttemptGuard.attemptsLeft, 0);
  });

  test('pesan blokir menyebut risiko kunci kartu', () async {
    await ChipAttemptGuard.recordFailure('SE20005');
    final msg = ChipAttemptGuard.blockedMessage;

    expect(msg, contains('terkunci'));
    expect(msg, contains('kantor kecamatan'));
  });

  test('reset setelah baca berhasil → boleh mencoba lagi', () async {
    await ChipAttemptGuard.recordFailure('SE20005');
    await ChipAttemptGuard.reset();

    expect(ChipAttemptGuard.failedAttempts, 0);
    expect(ChipAttemptGuard.canAttempt, isTrue);
    expect(ChipAttemptGuard.lastErrorCode, isNull);
  });
}
