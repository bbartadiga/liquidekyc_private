import 'dart:convert';

import '../../models/applicant_info_response.dart';
import '../../models/kyc_request_information_response.dart';
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

  /// Registrasi info applicant untuk proses KYC, lengkap dengan kana.
  Future<KycRequestInformationResponse?> registerKycRequestInformation({
    required String applicantId,
    required String lastName,
    required String firstName,
    String? middleName,
    String? lastNameKana,
    String? firstNameKana,
    String? middleNameKana,
    required String birthday,
    String? nationality,
    required String sex,
    String? zipCode,
    required String phoneNumber,
    required String address1,
    String? address2,
    String? address3,
    String? address4,
  }) async {
    log('registerKycRequestInformation - applicantId: $applicantId');
    log('URL: $baseUrl$bePathKycRequestInformations');
    onProgress?.call('KYC Request Info', true);

    try {
      final response = await sendPost(
        '$baseUrl$bePathKycRequestInformations',
        {
          'applicant_id': applicantId,
          'last_name': lastName,
          'first_name': firstName,
          'middle_name': ?middleName,
          'last_name_kana': ?lastNameKana,
          'first_name_kana': ?firstNameKana,
          'middle_name_kana': ?middleNameKana,
          'birthday': birthday,
          'nationality': ?nationality,
          'sex': sex,
          'zip_code': ?zipCode,
          'phone_number': phoneNumber,
          'address1': address1,
          'address2': ?address2,
          'address3': ?address3,
          'address4': ?address4,
        },
      );

      log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        log('registerKycRequestInformation SUCCESS');
        onProgress?.call('KYC Request Info', false);
        return KycRequestInformationResponse.fromMap(data);
      }
      log('ERROR: ${response.statusCode} - ${response.body}');
      onProgress?.call('KYC Request Info', false);
      return KycRequestInformationResponse.error(
        statusCode: response.statusCode,
        message: response.body,
      );
    } catch (e) {
      log('ERROR: $e');
      onProgress?.call('KYC Request Info', false);
      return KycRequestInformationResponse.error(
        statusCode: 0,
        message: e.toString(),
      );
    }
  }

  /// Registrasi info applicant untuk aplikasi (dipakai setelah data lengkap).
  Future<RegisterApplicationInfoResponse?> registerApplicationInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    String? phoneNumber,
    String? email,
  }) async {
    log('RegisterApplicationInfo - applicantId: $applicantId');

    final nameParts = applicantName.split(' ');
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final firstName = nameParts.isNotEmpty ? nameParts.first : applicantName;

    return postWithRetry<RegisterApplicationInfoResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, 'info'),
      endpoint: relativeApplicantPath(applicantId, 'info'),
      progressLabel: 'Register App Info',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'birthday': dateOfBirth.replaceAll('-', ''),
        'address1': address,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      },
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
