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
  
    test('nama & alamat terakhir dari applicant payload ikut disensor', () {
      // Bentuk body yang beneran muncul di log HTTP-REQ (lihat log user).
      final out = LogSanitizer.sanitize(
        'body={"applicant_id":"111","last_name":"DHIKA","first_name":"PRATAMA",'
        '"last_name_kana":"DHIKA","first_name_kana":"PRATAMA",'
        '"birthday":"19980215","nationality":"ID","sex":"2",'
        '"zip_code":"1000001","address1":"東京都","address2":"品川区",'
        '"address3":"上大崎2丁目10番11号 アビティ目黒 401","id_number":"ZO254207410B"}',
      );

      expect(out, isNot(contains('DHIKA')));
      expect(out, isNot(contains('PRATAMA')));
      expect(out, isNot(contains('東京都')));
      expect(out, isNot(contains('品川区')));
      expect(out, isNot(contains('上大崎')));
      expect(out, isNot(contains('アビティ目黒')));
      expect(out, isNot(contains('ZO254207410B')));
      expect(out, isNot(contains('19980215')));
      expect(out, contains('"last_name":"***"'));
      expect(out, contains('"address1":"***"'));
    });
});
}
