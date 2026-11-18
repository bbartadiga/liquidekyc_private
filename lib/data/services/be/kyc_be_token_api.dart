import 'dart:convert';

import '../../models/token_response.dart';
import 'be_api_base.dart';
import 'be_api_config.dart';

/// Endpoint token SDK: ambil token applicant & bikin applicant baru.
class KycBeTokenApi extends BeApiBase {
  KycBeTokenApi({super.client});

  Future<KycTokenResponse?> applyForSdkToken({
    required String applicantId,
    int operationPriority = 1,
  }) async {
    log('Fetching token from BE...');

    try {
      final response = await sendPost(
        '$baseUrl$bePathSdkApplications',
        {
          'applicant_id': applicantId,
          'operation_assignment_priority': operationPriority.toString(),
        },
      );

      log('Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return KycTokenResponse.fromMap(jsonDecode(response.body));
      }
      return KycTokenResponse.error(
        statusCode: response.statusCode,
        message: response.body,
      );
    } catch (e) {
      log('ERROR: $e');
      return KycTokenResponse.error(statusCode: 0, message: e.toString());
    }
  }

  Future<KycTokenResponse?> applyNewApplicant() async {
    log('Creating new applicant via BE...');

    try {
      final response = await sendPost(
        '$baseUrl$bePathSdkApplications',
        {'operation_assignment_priority': '1'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return KycTokenResponse.fromMap(jsonDecode(response.body));
      }
      return KycTokenResponse.error(
        statusCode: response.statusCode,
        message: response.body,
      );
    } catch (e) {
      log('ERROR: $e');
      return KycTokenResponse.error(statusCode: 0, message: e.toString());
    }
  }
}
