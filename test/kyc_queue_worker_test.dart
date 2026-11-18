import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:module_liquid/core/constant/liquid_constants.dart';
import 'package:module_liquid/data/services/kyc_queue_worker.dart';
import 'package:module_liquid/data/services/kyc_retry_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ngunci cara retry queue mengirim ulang request ke BE.
///
/// Endpoint di queue disimpan sebagai path relatif, jadi worker wajib
/// menggabungkannya dengan base URL BE. Kalau lupa, `Uri.parse` nggak punya
/// scheme dan semua retry gagal diam-diam.
void main() {
  final base = '${LiquidConfig.beUrl}/inbound-liquid';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await KycRetryQueue.init();
    await KycRetryQueue.clearQueue();
  });

  test('retry GET pakai URL absolut + header auth', () async {
    final sent = <http.BaseRequest>[];
    KycQueueWorker.initialize(
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', 200);
      }),
    );

    await KycRetryQueue.enqueue(KycQueuedRequest(
      applicantId: 'APP-1',
      endpoint: '/v1/applicants/APP-1/photos',
      method: 'GET',
    ));

    await KycQueueWorker.processQueue();

    expect(sent, hasLength(1));
    expect(
      sent.single.url.toString(),
      '$base/v1/applicants/APP-1/photos',
    );
    expect(sent.single.headers['X-Ekyc-Api-key'], LiquidConfig.connectorApiKey);
    expect(await KycRetryQueue.getPendingCount(), 0);
  });

  test('retry POST kirim body sebagai JSON', () async {
    final sent = <http.BaseRequest>[];
    KycQueueWorker.initialize(
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', 200);
      }),
    );

    await KycRetryQueue.enqueue(KycQueuedRequest(
      applicantId: 'APP-1',
      endpoint: '/v1/applicants/APP-1/info',
      method: 'POST',
      body: {'first_name': 'Budi', 'last_name': 'Santoso'},
    ));

    await KycQueueWorker.processQueue();

    expect(sent, hasLength(1));
    final body = jsonDecode((sent.single as http.Request).body);
    expect(body, {'first_name': 'Budi', 'last_name': 'Santoso'});
  });

  test('retry gagal → request tetap di queue & retryCount naik', () async {
    KycQueueWorker.initialize(
      client: MockClient((request) async => http.Response('boom', 500)),
    );

    await KycRetryQueue.enqueue(KycQueuedRequest(
      applicantId: 'APP-1',
      endpoint: '/v1/applicants/APP-1/photos',
      method: 'GET',
    ));

    await KycQueueWorker.processQueue();

    final pending = await KycRetryQueue.getPendingRequests();
    expect(pending, hasLength(1));
    expect(pending.single.retryCount, 1);
  });
}
