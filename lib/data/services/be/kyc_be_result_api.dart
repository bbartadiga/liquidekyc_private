import 'dart:convert';

import '../../models/token_response.dart';
import 'be_api_base.dart';
import 'be_api_config.dart';

/// Endpoint hasil KYC: kirim hasil verifikasi ke BE & trigger orchestration.
class KycBeResultApi extends BeApiBase {
  KycBeResultApi({super.client});

  /// Kirim hasil akhir KYC applicant ke BE.
  ///
  /// Return `true` kalau BE terima (2xx). Kegagalan di-return sebagai `false`
  /// karena hasilnya non-critical — tidak menggagalkan flow utama.
  Future<bool> registerKycResult({
    required String applicantId,
    required String kycResult,
    required bool hasSensitiveInfo,
  }) async {
    log('registerKycResult - applicantId: $applicantId, result: $kycResult');

    return postWithRetry<bool>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubKycResult),
      endpoint: relativeApplicantPath(applicantId, beSubKycResult),
      progressLabel: 'Register KYC Result',
      body: {
        'result': kycResult,
        'reason': hasSensitiveInfo ? 'has_sensitive_info' : 'All verification passed',
      },
      onSuccess: (_) => true,
      errorFactory: (_, _) => false,
    );
  }

  /// Trigger proses KYC orchestration di BE.
  Future<KycOrchestrationResponse?> processKycOrchestration({
    required String applicantId,
    required String firstName,
    required String lastName,
    required String birthday,
    String? nationality,
    String? sex,
    String? zipCode,
    String? phoneNumber,
    String? address1,
  }) async {
    log('processKycOrchestration - applicantId: $applicantId');
    log('URL: $baseUrl$bePathOrchestration/$applicantId/process-kyc');
    onProgress?.call('KYC Orchestration', true);

    try {
      final response = await sendPost(
        '$baseUrl$bePathOrchestration/$applicantId/process-kyc',
        {
          'first_name': firstName,
          'last_name': lastName,
          'birthday': birthday,
          'nationality': ?nationality,
          'sex': ?sex,
          'zip_code': ?zipCode,
          'phone_number': ?phoneNumber,
          'address1': ?address1,
        },
      );

      onProgress?.call('KYC Orchestration', false);

      log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        log('processKycOrchestration SUCCESS');
        return KycOrchestrationResponse.fromMap(data);
      }
      log('processKycOrchestration ERROR: ${response.statusCode} - ${response.body}');
      return KycOrchestrationResponse.error(
        statusCode: response.statusCode,
        message: response.body,
      );
    } catch (e) {
      log('ERROR: $e');
      onProgress?.call('KYC Orchestration', false);
      return KycOrchestrationResponse.error(statusCode: 0, message: e.toString());
    }
  }
}
