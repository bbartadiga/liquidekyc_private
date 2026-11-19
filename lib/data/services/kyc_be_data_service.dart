import '../../core/services/app_logger.dart';
import '../../data/models/applicant_info_payload.dart';
import 'be/be_call_runner.dart';
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

  /// Jeda + retry antar panggilan BE (G01 API List).
  final BeCallRunner _runner;

  KycBeDataService({KycBeApi? beApi, BeCallRunner? runner})
      : _beApi = beApi ?? KycBeApi(),
        _runner = runner ?? BeCallRunner();

  /// 016_RegisterApplicationInfoAPI.
  ///
  /// Panggil **sesudah** activate() (G01 API List: "Calling this API
  /// immediately after executing the Activate Function may result in an error").
  Future<bool> registerApplicationInfo({
    required ApplicantInfoPayload payload,
  }) async {
    appLogger.i('[BE-1] Calling RegisterApplicationInfo...');

    final registerResult = await _runner.runWithRetry(
      () => _beApi.registerApplicationInfo(payload: payload),
      isTransient: (r) =>
          r == null || BeCallRunner.isTransientMessage(r.errorMessage),
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

    final result = await _runner.runWithRetry(
      () => _beApi.getVerificationResults(applicantId),
      isTransient: (r) =>
          r == null || BeCallRunner.isTransientMessage(r.errorMessage),
    );
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
      icCardInfo = await _runner.runWithRetry(
        () => _beApi.getICCardInfo(applicantId),
        isTransient: (r) =>
            r == null || BeCallRunner.isTransientMessage(r.errorMessage),
      );
      if (icCardInfo?.isSuccess == true) {
        appLogger.i('[BE] IC Card Info received: name=${icCardInfo?.name}');
      } else {
        appLogger.e('[BE] Failed to get IC Card Info: ${icCardInfo?.errorMessage}');
      }
    }

    appLogger.i('[BE-3] Calling getOcrResultsFromBe...');
    final ocrResults = await _runner.runWithRetry(
      () => _beApi.getOcrResultsFromBe(applicantId),
      isTransient: (r) =>
          r == null || BeCallRunner.isTransientMessage(r.errorMessage),
    );
    if (ocrResults?.isSuccess == true) {
      appLogger.i('[BE-3] getOcrResultsFromBe → SUCCESS | name=${ocrResults?.name}');
    } else {
      appLogger.e('[BE-3] getOcrResultsFromBe → FAILED | ${ocrResults?.errorMessage}');
    }

    appLogger.i('[BE-4] Calling getLivenessImages...');
    final livenessImages = await _runner.runWithRetry(
      () => _beApi.getLivenessImages(applicantId),
      isTransient: (r) =>
          r == null || BeCallRunner.isTransientMessage(r.errorMessage),
    );
    if (livenessImages?.isSuccess == true) {
      appLogger.i('[BE-4] getLivenessImages → SUCCESS | count:${livenessImages?.livenessImages?.length ?? 0}');
    } else {
      appLogger.e('[BE-4] getLivenessImages → FAILED | ${livenessImages?.errorMessage}');
    }

    appLogger.i('[BE-5] Calling getPhotos...');
    final photos = await _runner.runWithRetry(
      () => _beApi.getPhotos(applicantId),
      isTransient: (r) =>
          r == null || BeCallRunner.isTransientMessage(r.errorMessage),
    );
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

    final registered = await _runner.run(
      () => _beApi.registerKycResult(
        applicantId: applicantId,
        kycResult: '0', // 0 = OK, 1 = NG
        hasSensitiveInfo: true,
      ),
    );

    if (registered) {
      appLogger.i('[BE-6] registerKycResult → SUCCESS');
    } else {
      appLogger.e('[BE-6] registerKycResult → FAILED (non-critical)');
    }
    return registered;
  }
}
