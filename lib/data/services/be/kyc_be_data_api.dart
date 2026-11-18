import '../../models/ic_card_info_response.dart';
import '../../models/liveness_images_response.dart';
import '../../models/ocr_results_response.dart';
import '../../models/photos_response.dart';
import '../../models/verification_results_response.dart';
import 'be_api_base.dart';
import 'be_api_config.dart';

/// Endpoint baca data applicant: IC card, verifikasi, OCR, foto, liveness.
///
/// Semua endpoint di sini GET sub-resource applicant dan pakai pola retry
/// yang sama: backoff eksponensial + jitter, lalu antre ke retry queue
/// kalau gagal total.
class KycBeDataApi extends BeApiBase {
  KycBeDataApi({super.client});

  Future<ICCardInfoResponse?> getICCardInfo(String applicantId) async {
    log('Getting IC Card Info from BE...');
    log('URL: ${applicantUrl(applicantId, beSubIcInfo)}');

    return getWithRetry<ICCardInfoResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubIcInfo),
      endpoint: relativeApplicantPath(applicantId, beSubIcInfo),
      progressLabel: 'IC Card Info',
      parse: ICCardInfoResponse.fromMap,
      errorFactory: (statusCode, message) =>
          ICCardInfoResponse.error(statusCode: statusCode, message: message),
      successLog: (data) => 'IC Card Info received: name=${data['name']}',
    );
  }

  Future<VerificationResultsResponse?> getVerificationResults(
    String applicantId,
  ) async {
    log('Getting Verification Results from BE...');

    return getWithRetry<VerificationResultsResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubVerificationResults),
      endpoint: relativeApplicantPath(applicantId, beSubVerificationResults),
      progressLabel: 'Verification Results',
      parse: VerificationResultsResponse.fromMap,
      errorFactory: (statusCode, message) => VerificationResultsResponse.error(
        statusCode: statusCode,
        message: message,
      ),
    );
  }

  Future<OcrResultsBeResponse?> getOcrResultsFromBe(String applicantId) async {
    log('getOcrResultsFromBe - applicantId: $applicantId');

    return getWithRetry<OcrResultsBeResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubOcrResults),
      endpoint: relativeApplicantPath(applicantId, beSubOcrResults),
      progressLabel: 'OCR Results',
      parse: OcrResultsBeResponse.fromMap,
      errorFactory: (statusCode, message) =>
          OcrResultsBeResponse.error(statusCode: statusCode, message: message),
      successLog: (_) => 'getOcrResultsFromBe SUCCESS',
    );
  }

  Future<PhotosResponse?> getPhotos(String applicantId) async {
    log('getPhotos - applicantId: $applicantId');

    return getWithRetry<PhotosResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubPhotos),
      endpoint: relativeApplicantPath(applicantId, beSubPhotos),
      progressLabel: 'Document Photos',
      parse: PhotosResponse.fromMap,
      errorFactory: (statusCode, message) =>
          PhotosResponse.error(statusCode: statusCode, message: message),
      successLog: (_) => 'getPhotos SUCCESS',
    );
  }

  Future<LivenessImagesResponse?> getLivenessImages(String applicantId) async {
    log('getLivenessImages - applicantId: $applicantId');

    return getWithRetry<LivenessImagesResponse>(
      applicantId: applicantId,
      url: applicantUrl(applicantId, beSubLivenessImages),
      endpoint: relativeApplicantPath(applicantId, beSubLivenessImages),
      progressLabel: 'Liveness Images',
      parse: LivenessImagesResponse.fromMap,
      errorFactory: (statusCode, message) => LivenessImagesResponse.error(
        statusCode: statusCode,
        message: message,
      ),
      successLog: (_) => 'getLivenessImages SUCCESS',
    );
  }
}
