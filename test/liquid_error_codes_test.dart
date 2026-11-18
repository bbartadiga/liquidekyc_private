import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/models/chip_verification.dart';

/// Mapping error code Liquid SDK 1.47.0 + perilaku peringatan kunci kartu.
///
/// Mapping diambil dari bytecode SDK:
/// `ResultHandler` → `ChipVerificationResultStatus` → kode `SExxxxx`.
void main() {
  group('LiquidErrorCode mapping (SDK 1.47.0)', () {
    test('SE22051 / SE22052 → IC_CHIP_READ_ERROR', () {
      expect(
        LiquidErrorCode.fromCode('SE22051'),
        LiquidErrorCode.icChipReadError,
      );
      expect(
        LiquidErrorCode.fromCode('SE22052'),
        LiquidErrorCode.icChipReadError,
      );
    });

    test('SE21001 → IC_CHIP_SPECIAL, bukan read error', () {
      expect(LiquidErrorCode.fromCode('SE21001'), LiquidErrorCode.icChipSpecial);
    });

    test('SE20005 → IC_CHIP_PIN_FAILURE (kunci kartu)', () {
      final code = LiquidErrorCode.fromCode('SE20005');
      expect(code, LiquidErrorCode.pinErrorExceeded);
      expect(code.canLockCard, isTrue);
    });

    test('SE20015 → IC_CHIP_PIN_INVALID (kunci kartu)', () {
      final code = LiquidErrorCode.fromCode('SE20015');
      expect(code, LiquidErrorCode.incorrectPin);
      expect(code.canLockCard, isTrue);
    });

    test('SE20001 → IC_CHIP_LOCKED (kunci kartu)', () {
      final code = LiquidErrorCode.fromCode('SE20001');
      expect(code, LiquidErrorCode.icChipLocked);
      expect(code.canLockCard, isTrue);
    });

    test('error biasa nggak ditandai bisa kunci kartu', () {
      expect(LiquidErrorCode.fromCode('SE80001').canLockCard, isFalse);
      expect(LiquidErrorCode.fromCode('SE22001').canLockCard, isFalse);
      expect(LiquidErrorCode.fromCode('SE90000').canLockCard, isFalse);
    });

    test('kode nggak dikenal → unknown', () {
      expect(LiquidErrorCode.fromCode('SE99999').code, isNotEmpty);
      expect(LiquidErrorCode.fromCode(null), LiquidErrorCode.unknown);
    });
  });

  group('ChipVerificationResult - peringatan kunci kartu', () {
    test('attemptsRemainingUntilChipLocked diparse dari chipErrorData', () {
      final result = ChipVerificationResult.fromMap({
        'resultStatus': 'ERROR',
        'errorCode': 'SE20005',
        'additionalDataTitle': 'Identification unsuccessful',
        'additionalDataMessage': '',
        'chipErrorData': {
          'attemptsRemainingUntilChipLocked': 9,
          'credentialType': 'VERIFICATION_CODE_A',
        },
      });

      expect(result.attemptsRemainingUntilChipLocked, 9);
      expect(result.chipErrorCredentialType, 'VERIFICATION_CODE_A');
    });

    test('pesan error My Number Card menyertakan sisa percobaan + risiko kunci', () {
      final result = ChipVerificationResult.fromMap({
        'resultStatus': 'ERROR',
        'errorCode': 'SE20005',
        'chipErrorData': {
          'attemptsRemainingUntilChipLocked': 9,
          'credentialType': 'VERIFICATION_CODE_A',
        },
      });

      final message = result.userFriendlyMessage;
      expect(message, contains('9 kali'));
      expect(message, contains('terkunci'));
      expect(message, contains('kantor kecamatan'));
    });

    test('error biasa nggak dikasih peringatan kunci kartu', () {
      final result = ChipVerificationResult.fromMap({
        'resultStatus': 'ERROR',
        'errorCode': 'SE80001',
      });

      expect(result.userFriendlyMessage, isNot(contains('terkunci')));
    });

    test('pesan dari SDK tetap dipakai utuh kalau ada', () {
      final result = ChipVerificationResult.fromMap({
        'resultStatus': 'ERROR',
        'errorCode': 'SE20005',
        'additionalDataMessage': 'Identification unsuccessful',
      });

      expect(result.userFriendlyMessage, startsWith('Identification unsuccessful'));
    });
  });
}
