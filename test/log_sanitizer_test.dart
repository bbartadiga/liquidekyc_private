import 'package:flutter_test/flutter_test.dart';
import 'package:module_liquid/core/services/log_sanitizer.dart';

/// Sensor data sensitif untuk file export yang di-share ke CS/user.
void main() {
  group('LogSanitizer', () {
    test('token disensor', () {
      final out = LogSanitizer.sanitize(
        '  token: d1f8337ec504e2d06bd9ef6dd9f4ca4800a4f469105e8eb90e4f9d467893fa18',
      );
      expect(out, contains('token=***'));
      expect(out, isNot(contains('d1f8337ec504e2d')));
    });

    test('API key disensor', () {
      final out = LogSanitizer.sanitize(
        "headers: {'X-Ekyc-Api-key': 'FAKE-API-KEY-VALUE-FOR-TEST-ONLY'}",
      );
      expect(out, isNot(contains('FAKE-API-KEY-VALUE-FOR-TEST-ONLY')));
      expect(out, contains('***'));
    });

    test('applicantId 12 digit disensor', () {
      final out = LogSanitizer.sanitize('applicantId: 111902224425');
      expect(out, isNot(contains('111902224425')));
      expect(out, contains('****'));
    });

    test('nama & alamat disensor', () {
      final out = LogSanitizer.sanitize(
        'name: 山田 太郎 | address: 東京都新宿区西新宿1-2-3 | birthday: 19900102',
      );
      expect(out, isNot(contains('山田')));
      expect(out, isNot(contains('新宿区')));
      expect(out, contains('name=***'));
      expect(out, contains('address=***'));
    });

    test('email disensor', () {
      final out = LogSanitizer.sanitize('contact: taro.yamada@example.co.jp');
      expect(out, isNot(contains('taro.yamada')));
      expect(out, contains('***@***'));
    });

    test('log biasa nggak dirusak', () {
      const msg = '[STEP 11] IC Card (NFC) → FAILED | code:SE20005';
      expect(LogSanitizer.sanitize(msg), msg);
    });

    test('string kosong aman', () {
      expect(LogSanitizer.sanitize(''), '');
    });
  });
}
