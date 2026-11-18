import '../../core/constant/liquid_constants.dart';
import '../../core/services/app_logger.dart';
import 'kyc_be_api.dart';

/// Hasil pengambilan credential (applicantId + token) dari Connector API.
class KycCredentials {
  final String applicantId;
  final String token;
  final String? sdkUrl;
  final bool applicantInfoRegistered;
  final String? errorMessage;

  const KycCredentials({
    required this.applicantId,
    required this.token,
    this.sdkUrl,
    this.applicantInfoRegistered = false,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

/// Ambil credential SDK (017 SDKApply API) + daftar applicant info.
class KycCredentialsService {
  final KycBeApi _beApi;

  KycCredentialsService({KycBeApi? beApi}) : _beApi = beApi ?? KycBeApi();

  /// Token baru untuk applicant ID yang diberikan.
  /// [applicantInfoRegistered] false berarti register applicant info gagal —
  /// itu langkah opsional, token tetap valid.
  Future<KycCredentials> fetch({
    String? applicantId,
    String? beBaseUrl,
    String? applicantName,
    String? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? email,
  }) async {
    final targetApplicantId = applicantId ?? LiquidConfig.applicantId;
    final sdkUrl = beBaseUrl ?? LiquidConfig.url;

    appLogger.i('[STEP 1] Requesting token from BE...');
    final tokenResponse =
        await _beApi.applyForSdkToken(applicantId: targetApplicantId);

    if (tokenResponse == null ||
        !tokenResponse.isSuccess ||
        tokenResponse.token == null) {
      final message = tokenResponse?.errorMessage ?? 'Failed to get token from BE';
      appLogger.e('[STEP 1] Failed to get token: $message');
      return KycCredentials(
        applicantId: targetApplicantId,
        token: '',
        sdkUrl: sdkUrl,
        errorMessage: message,
      );
    }

    final resolvedApplicantId = tokenResponse.applicantId ?? targetApplicantId;
    appLogger.i('[STEP 1] Token received from BE | applicantId=$resolvedApplicantId');

    // Register applicant info — langkah opsional, token tetap dipakai walau gagal
    appLogger.i('[STEP 2] Registering applicant info to BE...');
    final registerResponse = await _beApi.registerApplicantInfo(
      applicantId: resolvedApplicantId,
      applicantName: applicantName ?? 'TARO YAMADA',
      dateOfBirth: dateOfBirth ?? '1990-05-15',
      address: address ?? 'Tokyo-to, Chiyoda-ku, Marunouchi 1-1-1',
      phoneNumber: phoneNumber ?? '08123456789',
      email: email ?? 'taro.yamada@example.com',
    );

    final registered = registerResponse?.isSuccess == true;
    if (registered) {
      appLogger.i('[STEP 2] Applicant registered: ${registerResponse?.applicationId}');
    } else {
      appLogger.w('[STEP 2] Failed to register applicant info (optional step): ${registerResponse?.errorMessage}');
    }

    return KycCredentials(
      applicantId: resolvedApplicantId,
      token: tokenResponse.token!,
      sdkUrl: sdkUrl,
      applicantInfoRegistered: registered,
    );
  }

  /// Applicant baru — Connector yang generate applicant ID.
  Future<KycCredentials> createNewApplicant({String? beBaseUrl}) async {
    final sdkUrl = beBaseUrl ?? LiquidConfig.url;
    final response = await _beApi.applyNewApplicant();

    if (response != null && response.isSuccess && response.token != null) {
      appLogger.i('[STEP 1] New applicant created | applicantId=${response.applicantId}');
      return KycCredentials(
        applicantId: response.applicantId ?? '',
        token: response.token!,
        sdkUrl: sdkUrl,
      );
    }

    final message = response?.errorMessage ?? 'Failed to create applicant';
    appLogger.e('[STEP 1] Failed to create applicant: $message');
    return KycCredentials(
      applicantId: '',
      token: '',
      sdkUrl: sdkUrl,
      errorMessage: message,
    );
  }
}
