import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/services/kyc_be_api.dart';

/// Ngunci shape request ke Liquid Connector API (BE):
/// method, URL, header auth, dan body.
///
/// Tujuannya ngejaga refactor KycBeApi jadi facade + domain API ga
/// diam-diam ngubah kontrak ke BE.
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

  group('KycBeApi request shape', () {
    test('applyForSdkToken → POST /v1/sdk/applications', () async {
      final api = apiWith(200, body: '{"token":"abc"}');

      await api.applyForSdkToken(applicantId: 'APP-1');

      expect(sent, hasLength(1));
      expect(sent.single.method, 'POST');
      expect(sent.single.url.toString(), '$base/v1/sdk/applications');
      expect(bodyOf(sent.single), {
        'applicant_id': 'APP-1',
        'operation_assignment_priority': '1',
      });
    });

    test('getPhotos → GET sub-resource applicant', () async {
      final api = apiWith(200, body: '{"photos":[]}');

      await api.getPhotos('APP-1');

      expect(sent.single.method, 'GET');
      expect(sent.single.url.toString(), '$base/v1/applicants/APP-1/photos');
    });

    test('registerApplicationInfo → POST /v1/applicants/{id}/info', () async {
      final api = apiWith(200, body: '{"status":"ok"}');

      await api.registerApplicationInfo(
        applicantId: 'APP-1',
        applicantName: 'Budi Santoso',
        dateOfBirth: '1990-01-02',
        address: 'Jl. Merdeka 1',
        phoneNumber: '08123456789',
      );

      expect(sent.single.method, 'POST');
      expect(sent.single.url.toString(), '$base/v1/applicants/APP-1/info');
      expect(bodyOf(sent.single), {
        'first_name': 'Budi',
        'last_name': 'Santoso',
        'birthday': '19900102',
        'address1': 'Jl. Merdeka 1',
        'phone_number': '08123456789',
      });
    });

    test('registerKycResult → POST /kyc-result dengan reason', () async {
      final api = apiWith(200);

      final ok = await api.registerKycResult(
        applicantId: 'APP-1',
        kycResult: 'PASS',
        hasSensitiveInfo: true,
      );

      expect(ok, isTrue);
      expect(
        sent.single.url.toString(),
        '$base/v1/applicants/APP-1/kyc-result',
      );
      expect(bodyOf(sent.single), {
        'result': 'PASS',
        'reason': 'has_sensitive_info',
      });
    });

    test(
        'processKycOrchestration → POST /v1/orchestration/{id}/process-kyc',
        () async {
      final api = apiWith(200, body: '{"status":"ok"}');

      await api.processKycOrchestration(
        applicantId: 'APP-1',
        firstName: 'Budi',
        lastName: 'Santoso',
        birthday: '19900102',
      );

      expect(
        sent.single.url.toString(),
        '$base/v1/orchestration/APP-1/process-kyc',
      );
      expect(bodyOf(sent.single), {
        'first_name': 'Budi',
        'last_name': 'Santoso',
        'birthday': '19900102',
      });
    });

    test('registerKycRequestInformation → field opsional dibuang', () async {
      final api = apiWith(200, body: '{"status":"ok"}');

      await api.registerKycRequestInformation(
        applicantId: 'APP-1',
        lastName: 'Santoso',
        firstName: 'Budi',
        birthday: '19900102',
        sex: 'M',
        phoneNumber: '08123456789',
        address1: 'Jl. Merdeka 1',
      );

      expect(sent.single.url.toString(), '$base/v1/kyc_request_informations');
      final body = bodyOf(sent.single);
      expect(body.containsKey('middle_name'), isFalse);
      expect(body.containsKey('nationality'), isFalse);
      expect(body['applicant_id'], 'APP-1');
      expect(body['first_name'], 'Budi');
    });

    test('header auth + content-type selalu dikirim', () async {
      final api = apiWith(200, body: '{}');

      await api.getPhotos('APP-1');

      expect(sent.single.headers['Content-Type'], 'application/json');
      expect(
        sent.single.headers['X-Ekyc-Api-key'],
        LiquidConfig.connectorApiKey,
      );
    });

    test('error response → model error, bukan exception', () async {
      final api = apiWith(500, body: 'boom');

      final result = await api.getPhotos('APP-1');

      expect(result, isNotNull);
      expect(result!.isSuccess, isFalse);
      expect(result.statusCode, 500);
      expect(result.errorMessage, contains('boom'));
    });
  });
}
