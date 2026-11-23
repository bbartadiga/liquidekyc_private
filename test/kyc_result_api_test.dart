import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/services/kyc_be_api.dart';

/// 014 RegisterKYCResult (BE-6).
///
/// Spec "014_RegisterKYCResultAPI v1.4.2" hal.1:
///   Staging/Production: https://{Unique URL for each organization}/v1/kyc_results
/// hal.2 body:
///   { "applicant_id": "...", "kyc_result": "0", "has_sensitive_info": false }
///
/// Path lama `/v1/applicants/{id}/kyc-result` nggak ada di spec → BE balas
/// 403 "Missing Authentication Token" (lihat log user 20 Nov).
void main() {
  final base = '${LiquidConfig.beUrl}/inbound-liquid';

  late List<http.BaseRequest> sent;

  KycBeApi apiWith(int statusCode, {String body = '{}'}) {
    sent = [];
    final client = MockClient((request) async {
      sent.add(request);
      return http.Response(body, statusCode);
    });
    return KycBeApi(client: client);
  }

  Map<String, dynamic> bodyOf(http.BaseRequest request) =>
      jsonDecode((request as http.Request).body) as Map<String, dynamic>;

  group('BE-6 registerKycResult', () {
    test('path + body sesuai spec 014', () async {
      final api = apiWith(201);

      final ok = await api.registerKycResult(
        applicantId: 'APP-1',
        kycResult: '0',
        hasSensitiveInfo: false,
      );

      expect(ok, isTrue);
      expect(sent.single.method, 'POST');
      expect(sent.single.url.toString(), '$base/v1/kyc_results');
      expect(bodyOf(sent.single), {
        'applicant_id': 'APP-1',
        'kyc_result': '0',
        'has_sensitive_info': false,
      });
    });

    test('403 (path/salah) nggak di-retry — gagal sekali langsung', () async {
      final api = apiWith(403, body: '{"message":"Missing Authentication Token"}');

      final ok = await api.registerKycResult(
        applicantId: 'APP-1',
        kycResult: '0',
        hasSensitiveInfo: false,
      );

      expect(ok, isFalse);
      expect(sent, hasLength(1));
    });

    test('409 dengan kode transien tetap di-retry', () async {
      final api = apiWith(
        409,
        body: '{"error_code":"CE00004","error_message":"operation is not completed"}',
      );

      await api.registerKycResult(
        applicantId: 'APP-1',
        kycResult: '0',
        hasSensitiveInfo: false,
      );

      expect(sent.length, greaterThan(1));
    });

    test('409 dengan kode permanen (CE00019) nggak di-retry', () async {
      final api = apiWith(
        409,
        body: '{"error_code":"CE00019","error_message":"ocr is not available"}',
      );

      await api.registerKycResult(
        applicantId: 'APP-1',
        kycResult: '0',
        hasSensitiveInfo: false,
      );

      expect(sent, hasLength(1));
    });
  });

  group('Retry policy GET', () {
    test('409 permanen (CE00019 OCR nggak tersedia) nggak di-retry', () async {
      final api = apiWith(
        409,
        body: '{"error_code":"CE00019","error_message":"ocr is not available"}',
      );

      await api.getOcrResultsFromBe('APP-1');

      expect(sent, hasLength(1));
    });

    test('409 transien (CE00004) di-retry', () async {
      final api = apiWith(
        409,
        body: '{"error_code":"CE00004","error_message":"operation is not completed"}',
      );

      await api.getOcrResultsFromBe('APP-1');

      expect(sent.length, greaterThan(1));
    });
  });
}
