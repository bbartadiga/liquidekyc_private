import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/models/id_document_information_response.dart';
import 'package:module_liquid/data/models/ordering_information_draft.dart';
import 'package:module_liquid/data/models/processed_information_response.dart';
import 'package:module_liquid/data/services/kyc_be_api.dart';

/// API 007 (id_document_information) & API 027 (processed_information).
///
/// Spec 007 v1.6.8 hal.5-6: `GET /v1/applicants/{applicant_id}/id_document_information`
/// Spec 027 v1.0.0 hal.3-4: `GET /v1/applicants/{applicant_id}/processed_information`
void main() {
  final base = '${LiquidConfig.beUrl}/inbound-liquid';

  late List<http.BaseRequest> sent;

  KycBeApi apiWith(int statusCode, {String body = '{}'}) {
    sent = [];
    final client = MockClient((request) async {
      sent.add(request);
      // Body dicek UTF-8 + charset (nggak latin-1) supaya karakter Jepang valid.
      return http.Response.bytes(
        utf8.encode(body),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    return KycBeApi(client: client);
  }

  group('API 007 — id_document_information', () {
    test('path + parse response', () async {
      final api = apiWith(
        200,
        body: jsonEncode({
          'id_document_type': '01',
          'id_number': '000000000000',
          'expire_date': '20200101',
          'name': ' 力戸  花子 ',
          'birthday': '20010101',
          'address': ' 東京都 ....',
          'stay_expire_date': '20200101',
          'resident_status': ' 留学生 ',
        }),
      );

      final result = await api.getIdDocumentInformation('APP-1');

      expect(sent.single.method, 'GET');
      expect(sent.single.url.toString(),
          '$base/v1/applicants/APP-1/id_document_information');
      expect(result?.isSuccess, isTrue);
      expect(result?.name, ' 力戸  花子 ');
      expect(result?.birthday, '20010101');
      expect(result?.stayExpireDate, '20200101');
      expect(result?.residentStatus, ' 留学生 ');
    });

    test('dipakai mapper sbg sumber resident_status + stay_expire_date', () {
      final draft = OrderingInformationMapper.fromKycData(
        idDocumentInformation: IdDocumentInformationResponse(
          isSuccess: true,
          stayExpireDate: '20300709',
          residentStatus: '永住者',
          birthday: '19980215',
        ),
      );

      expect(draft.periodToStayDate, DateTime(2030, 7, 9));
      expect(draft.visaStatus, 'PERMANENT RESIDENT');
      expect(draft.dateOfBirth, DateTime(1998, 2, 15));
    });
  });

  group('API 027 — processed_information', () {
    test('path + parse latin_name', () async {
      final api = apiWith(
        200,
        body: jsonEncode({
          'latin_name': {
            'is_available': true,
            'last_name': 'tanaka',
            'first_name': 'hanako',
            'middle_name': null,
          },
        }),
      );

      final result = await api.getProcessedInformation('APP-1');

      expect(sent.single.method, 'GET');
      expect(sent.single.url.toString(),
          '$base/v1/applicants/APP-1/processed_information');
      expect(result?.latinNameAvailable, isTrue);
      expect(result?.latinFullName, 'TANAKA HANAKO');
    });

    test('latin_name gak tersedia -> null', () {
      final response = ProcessedInformationResponse.fromMap({
        'latin_name': {'is_available': false},
      });

      expect(response.latinFullName, isNull);
    });

    test('dipakai mapper sbg sumber nama latin', () {
      final draft = OrderingInformationMapper.fromKycData(
        processedInformation: ProcessedInformationResponse.fromMap({
          'latin_name': {
            'is_available': true,
            'last_name': 'dhika',
            'first_name': 'pratama',
          },
        }),
      );

      expect(draft.orderingCustomerNameEnglish, 'DHIKA PRATAMA');
    });
  });
}
