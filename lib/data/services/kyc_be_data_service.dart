import '../../core/services/app_logger.dart';
import '../models/ic_card_info_response.dart';
import '../models/liveness_images_response.dart';
import '../models/ocr_results_response.dart';
import '../models/photos_response.dart';
import '../models/verification_results_response.dart';
import 'kyc_be_api.dart';

/// Kumpulan data yang diambil dari Connector API setelah verifikasi selesai.
class KycBeDataBundle {
  final VerificationResultsResponse? verificationResults;
  final OcrResultsBeResponse? ocrResults;
  final ICCardInfoResponse? icCardInfo;
  final LivenessImagesResponse? livenessImages;
  final PhotosResponse? photos;

  const KycBeDataBundle({
    this.verificationResults,
    this.ocrResults,
    this.icCardInfo,
    this.livenessImages,
    this.photos,
  });
}

/// Pengambilan data dari Connector API (BE).
class KycBeDataService {
  final KycBeApi _beApi;

  KycBeDataService({KycBeApi? beApi}) : _beApi = beApi ?? KycBeApi();

  /// Wajib dipanggil sebelum activate() — Liquid butuh data applicant terdaftar.
  Future<bool> registerApplicationInfo({
    required String applicantId,
    required String applicantName,
    required String dateOfBirth,
    required String address,
  }) async {
    appLogger.i('[BE-1] Calling RegisterApplicationInfo...');

    final registerResult = await _beApi.registerApplicationInfo(
      applicantId: applicantId,
      applicantName: applicantName,
      dateOfBirth: dateOfBirth,
      address: address,
    );

    if (registerResult?.isSuccess == true) {
      appLogger.i('[BE-1] RegisterApplicationInfo → SUCCESS | appId:${registerResult?.applicationId}');
      return true;
    }

    appLogger.e('[BE-1] RegisterApplicationInfo → FAILED | ${registerResult?.errorMessage ?? "unknown"}');
    return false;
  }

  /// Face match score + liveness result.
  Future<VerificationResultsResponse?> fetchVerificationResults(String applicantId) async {
    appLogger.i('[BE-2] Calling getVerificationResults...');

    final result = await _beApi.getVerificationResults(applicantId);
    if (result?.isSuccess == true) {
      appLogger.i('[BE-2] VerificationResults → SUCCESS | score:${result?.faceMatchScore}, liveness:${result?.livenessResult}');
    } else {
      appLogger.e('[BE-2] VerificationResults → FAILED | ${result?.errorMessage}');
    }
    return result;
  }

  /// Data resmi dari BE — diambil setelah activate() sukses.
  /// [includeICCardInfo] false kalau data chip sudah didapat dari SDK.
  Future<KycBeDataBundle> fetchPostActivationData(
    String applicantId, {
    bool includeICCardInfo = true,
  }) async {
    ICCardInfoResponse? icCardInfo;
    if (includeICCardInfo) {
      appLogger.i('[BE] Fetching IC Card Info from BE...');
      icCardInfo = await _beApi.getICCardInfo(applicantId);
      if (icCardInfo?.isSuccess == true) {
        appLogger.i('[BE] IC Card Info received: name=${icCardInfo?.name}');
      } else {
        appLogger.e('[BE] Failed to get IC Card Info: ${icCardInfo?.errorMessage}');
      }
    }

    appLogger.i('[BE-3] Calling getOcrResultsFromBe...');
    final ocrResults = await _beApi.getOcrResultsFromBe(applicantId);
    if (ocrResults?.isSuccess == true) {
      appLogger.i('[BE-3] getOcrResultsFromBe → SUCCESS | name=${ocrResults?.name}');
    } else {
      appLogger.e('[BE-3] getOcrResultsFromBe → FAILED | ${ocrResults?.errorMessage}');
    }

    appLogger.i('[BE-4] Calling getLivenessImages...');
    final livenessImages = await _beApi.getLivenessImages(applicantId);
    if (livenessImages?.isSuccess == true) {
      appLogger.i('[BE-4] getLivenessImages → SUCCESS | count:${livenessImages?.livenessImages?.length ?? 0}');
    } else {
      appLogger.e('[BE-4] getLivenessImages → FAILED | ${livenessImages?.errorMessage}');
    }

    appLogger.i('[BE-5] Calling getPhotos...');
    final photos = await _beApi.getPhotos(applicantId);
    if (photos?.isSuccess == true) {
      appLogger.i('[BE-5] getPhotos → SUCCESS | docs:${photos?.idDocumentPhotos?.length ?? 0}');
    } else {
      appLogger.e('[BE-5] getPhotos → FAILED | ${photos?.errorMessage}');
    }

    return KycBeDataBundle(
      verificationResults: null,
      ocrResults: ocrResults,
      icCardInfo: icCardInfo,
      livenessImages: livenessImages,
      photos: photos,
    );
  }

  /// Register hasil KYC — memicu auto-masking di sisi Liquid.
  Future<bool> registerKycResult(String applicantId) async {
    appLogger.i('[BE-6] Calling registerKycResult...');

    final registered = await _beApi.registerKycResult(
      applicantId: applicantId,
      kycResult: '0', // 0 = OK, 1 = NG
      hasSensitiveInfo: true,
    );

    if (registered) {
      appLogger.i('[BE-6] registerKycResult → SUCCESS');
    } else {
      appLogger.e('[BE-6] registerKycResult → FAILED (non-critical)');
    }
    return registered;
  }
}
