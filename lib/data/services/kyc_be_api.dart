import 'package:http/http.dart' as http;

import '../models/applicant_info_response.dart';
import '../models/ic_card_info_response.dart';
import '../models/kyc_request_information_response.dart';
import '../models/liveness_images_response.dart';
import '../models/ocr_results_response.dart';
import '../models/photos_response.dart';
import '../models/token_response.dart';
import '../models/verification_results_response.dart';
import 'be/be_api_base.dart';
import 'be/kyc_be_applicant_api.dart';
import 'be/kyc_be_data_api.dart';
import 'be/kyc_be_result_api.dart';
import 'be/kyc_be_token_api.dart';
import 'liquid_http_client.dart';

export 'be/be_api_base.dart' show ProgressCallback;

/// Facade tunggal untuk semua endpoint Liquid Connector API (BE).
///
/// Implementasinya dipecah per domain di folder `be/`:
/// - [KycBeTokenApi] — token SDK & applicant baru
/// - [KycBeApplicantApi] — registrasi data applicant & KYC request info
/// - [KycBeDataApi] — baca data applicant (IC card, verifikasi, OCR, foto, liveness)
/// - [KycBeResultApi] — kirim hasil KYC & trigger orchestration
class KycBeApi {
  final KycBeTokenApi _token;
  final KycBeApplicantApi _applicant;
  final KycBeDataApi _data;
  final KycBeResultApi _result;

  /// Satu HTTP client dipakai bersama semua domain API.
  factory KycBeApi({http.Client? client}) {
    final shared = client ?? LiquidHttpClient();
    return KycBeApi._(
      token: KycBeTokenApi(client: shared),
      applicant: KycBeApplicantApi(client: shared),
      data: KycBeDataApi(client: shared),
      result: KycBeResultApi(client: shared),
    );
  }

  KycBeApi._({
    required KycBeTokenApi token,
    required KycBeApplicantApi applicant,
    required KycBeDataApi data,
    required KycBeResultApi result,
  })  : _token = token,
        _applicant = applicant,
        _data = data,
        _result = result;

  ProgressCallback? _onProgress;

  /// Callback progress status buat UI loading.
  ProgressCallback? get onProgress => _onProgress;

  set onProgress(ProgressCallback? value) {
    _onProgress = value;
    _token.onProgress = value;
    _applicant.onProgress = value;
    _data.onProgress = value;
    _result.onProgress = value;
  }

  // --- Token ---

  Future<KycTokenResponse?> applyForSdkToken({
    required String applicantId,
    int operationPriority = 1,
  }) =>
      _token.applyForSdkToken(
        applicantId: applicantId,
        operationPriority: operationPriority,
      );

  Future<KycTokenResponse?> applyNewApplicant() => _token.applyNewApplicant();

  // --- Registrasi applicant ---

  Future<ApplicantInfoResponse?> registerApplicantInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    String? email,
  }) =>
      _applicant.registerApplicantInfo(
        applicantId: applicantId,
        applicantName: applicantName,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        email: email,
      );

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
  }) =>
      _applicant.registerKycRequestInformation(
        applicantId: applicantId,
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
        lastNameKana: lastNameKana,
        firstNameKana: firstNameKana,
        middleNameKana: middleNameKana,
        birthday: birthday,
        nationality: nationality,
        sex: sex,
        zipCode: zipCode,
        phoneNumber: phoneNumber,
        address1: address1,
        address2: address2,
        address3: address3,
        address4: address4,
      );

  Future<RegisterApplicationInfoResponse?> registerApplicationInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
    String? phoneNumber,
    String? email,
  }) =>
      _applicant.registerApplicationInfo(
        applicantId: applicantId,
        applicantName: applicantName,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        email: email,
      );

  // --- Baca data applicant ---

  Future<ICCardInfoResponse?> getICCardInfo(String applicantId) =>
      _data.getICCardInfo(applicantId);

  Future<VerificationResultsResponse?> getVerificationResults(
    String applicantId,
  ) =>
      _data.getVerificationResults(applicantId);

  Future<OcrResultsBeResponse?> getOcrResultsFromBe(String applicantId) =>
      _data.getOcrResultsFromBe(applicantId);

  Future<PhotosResponse?> getPhotos(String applicantId) =>
      _data.getPhotos(applicantId);

  Future<LivenessImagesResponse?> getLivenessImages(String applicantId) =>
      _data.getLivenessImages(applicantId);

  // --- Hasil KYC ---

  Future<bool> registerKycResult({
    required String applicantId,
    required String kycResult,
    required bool hasSensitiveInfo,
  }) =>
      _result.registerKycResult(
        applicantId: applicantId,
        kycResult: kycResult,
        hasSensitiveInfo: hasSensitiveInfo,
      );

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
  }) =>
      _result.processKycOrchestration(
        applicantId: applicantId,
        firstName: firstName,
        lastName: lastName,
        birthday: birthday,
        nationality: nationality,
        sex: sex,
        zipCode: zipCode,
        phoneNumber: phoneNumber,
        address1: address1,
      );
}
