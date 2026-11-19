import 'dart:convert';

import '../../models/applicant_info_payload.dart';
import '../../models/applicant_info_response.dart';
import 'be_api_base.dart';
import 'be_api_config.dart';

/// Endpoint registrasi applicant: data applicant & KYC request information.
class KycBeApplicantApi extends BeApiBase {
  KycBeApplicantApi({super.client});

  /// Registrasi data dasar applicant (nama, lahir, alamat, telepon).
  ///
  /// Error HTTP langsung dikembalikan tanpa retry — caller yang memutuskan
  /// mau lanjut atau gagal.
  Future<ApplicantInfoResponse?> registerApplicantInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    String? email,
  }) async {
    log('Registering applicant info to BE...');
    log('URL: ${applicantUrl(applicantId, 'info')}');

    final nameParts = applicantName.split(' ');
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final firstName = nameParts.isNotEmpty ? nameParts.first : applicantName;

    for (int attempt = 1; attempt <= beMaxRetries + 1; attempt++) {
      try {
        final response = await sendPost(
          applicantUrl(applicantId, 'info'),
          {
            'first_name': firstName,
            'last_name': lastName,
            'birthday': dateOfBirth.replaceAll('-', ''),
            'address1': address,
            if (phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ApplicantInfoResponse.fromMap(jsonDecode(response.body));
        }
        return ApplicantInfoResponse.error(
          statusCode: response.statusCode,
          message: response.body,
        );
      } catch (e) {
        log('ERROR (attempt $attempt): $e');
        if (attempt <= beMaxRetries) {
          log('Retrying...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return ApplicantInfoResponse.error(statusCode: 0, message: 'Failed after retries');
  }

  /// Registrasi info applicant (016_RegisterApplicationInfoAPI).
  ///
  /// Path & body mengikuti spec `LIQUID_eKYC_016 v1.3.4`:
  /// `POST /v1/kyc_request_informations`.
  ///
  /// Catatan: path lama `POST /v1/applicants/{id}/info` **nggak ada** di
  /// spec — BE balas "Missing Authentication Token".
  Future<RegisterApplicationInfoResponse?> registerApplicationInfo({
    required ApplicantInfoPayload payload,
  }) async {
    log('RegisterApplicationInfo - applicantId: ${payload.applicantId}');

    return postWithRetry<RegisterApplicationInfoResponse>(
      applicantId: payload.applicantId,
      url: '$baseUrl$bePathKycRequestInformations',
      endpoint: bePathKycRequestInformations,
      progressLabel: 'Register App Info',
      body: payload.toBody(),
      onSuccess: (response) =>
          RegisterApplicationInfoResponse.fromMap(jsonDecode(response.body)),
      errorFactory: (statusCode, message) =>
          RegisterApplicationInfoResponse.error(
        statusCode: statusCode,
        message: message,
      ),
      successLog: (_) => 'RegisterApplicationInfo SUCCESS',
    );
  }
}
