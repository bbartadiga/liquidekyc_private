import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_liquid/data/models/applicant_info_payload.dart';
import 'package:module_liquid/data/services/kyc_be_api.dart';

/// 016 RegisterApplicationInfo (BE-1).
///
/// Di log user, POST pertama dijawab **201 (Created)** — artinya record
/// applicant SUDAH dibuat — tapi app tetap retry dan akhirnya lapor FAILED
/// dengan 409. Penyebabnya parsing body 201 yang lempar exception.
void main() {
  KycBeApi apiWith(int statusCode, String body, {List<int>? calls}) {
    final client = MockClient((request) async {
      calls?.add(statusCode);
      return http.Response(body, statusCode);
    });
    return KycBeApi(client: client);
  }

  final payload = ApplicantInfoPayload(
    applicantId: 'APP-1',
    firstName: 'PRATAMA',
    lastName: 'DHIKA',
    birthday: '19980215',
    nationality: 'ID',
    sex: '1',
    zipCode: '1000001',
    address1: '東京都',
    address2: '品川区',
    address3: '上大崎2丁目10番11号',
    idNumber: 'ZO254207410B',
  );

  group('BE-1 RegisterApplicationInfo', () {
    test('201 dengan body JSON → sukses', () async {
      final calls = <int>[];
      final api = apiWith(201, '{"application_id":"APP-1"}', calls: calls);

      final result = await api.registerApplicationInfo(payload: payload);

      expect(result?.isSuccess, isTrue);
      expect(result?.applicationId, 'APP-1');
      expect(calls, hasLength(1));
    });

    test('201 dengan body KOSONG → tetap sukses, nggak di-retry', () async {
      final calls = <int>[];
      final api = apiWith(201, '', calls: calls);

      final result = await api.registerApplicationInfo(payload: payload);

      expect(result?.isSuccess, isTrue);
      // Pointohnya: cuma 1 request, nggak ada retry storm.
      expect(calls, hasLength(1));
    });

    test('201 dengan body bukan JSON → tetap sukses, nggak di-retry', () async {
      final calls = <int>[];
      final api = apiWith(201, '<html>ok</html>', calls: calls);

      final result = await api.registerApplicationInfo(payload: payload);

      expect(result?.isSuccess, isTrue);
      expect(calls, hasLength(1));
    });

    test('201 dengan body JSON array (bukan object) → tetap sukses', () async {
      final calls = <int>[];
      final api = apiWith(201, '[1,2,3]', calls: calls);

      final result = await api.registerApplicationInfo(payload: payload);

      expect(result?.isSuccess, isTrue);
      expect(calls, hasLength(1));
    });

    // Catatan: kasus 409 sengaja nggak di-test di sini — postWithRetry
    // retry dengan backoff 1/2/4/8s, jadi test-nya bakal makan >15 detik.
    // Mapping 409 → error dicek di level service (KycBeDataService).
  });
}
