import 'package:flutter/material.dart';

import '../../../data/models/ic_card_info_response.dart';
import '../../../data/models/kyc_result.dart';
import '../../../data/models/liveness_images_response.dart';
import '../../../data/models/ocr_results_response.dart';
import '../../../data/models/photos_response.dart';
import '../../../data/models/verification_results_response.dart';
import 'kyc_result_screen.dart';

/// Wrapper ringkas untuk kasus sukses — semua data diteruskan ke [KycResultScreen].
class KycSuccessScreen extends StatelessWidget {
  final KycResult? result;
  final VoidCallback onDone;
  final DocumentResult? documentResult;
  final FaceResult? faceResult;
  final ChipVerificationResult? chipResult;
  final ICCardInfoResponse? beICCardInfo;
  final VerificationResultsResponse? beVerificationResults;
  final OcrResultsBeResponse? beOcrResults;
  final PhotosResponse? bePhotos;
  final LivenessImagesResponse? beLivenessImages;
  final bool? isRegisterApplicationInfoSuccess;
  final String? ocrName;
  final String? ocrAddress;
  final String? ocrDateOfBirth;
  final String? ocrDocumentNumber;
  final String? ocrNationality;
  final String? ocrResidenceStatus;

  const KycSuccessScreen({
    super.key,
    this.result,
    required this.onDone,
    this.documentResult,
    this.faceResult,
    this.chipResult,
    this.beICCardInfo,
    this.beVerificationResults,
    this.beOcrResults,
    this.bePhotos,
    this.beLivenessImages,
    this.isRegisterApplicationInfoSuccess,
    this.ocrName,
    this.ocrAddress,
    this.ocrDateOfBirth,
    this.ocrDocumentNumber,
    this.ocrNationality,
    this.ocrResidenceStatus,
  });

  @override
  Widget build(BuildContext context) {
    return KycResultScreen(
      isSuccess: true,
      title: 'Verifikasi Berhasil!',
      message: 'Identitas Anda telah berhasil diverifikasi.',
      result: result,
      onDone: onDone,
      documentResult: documentResult,
      faceResult: faceResult,
      chipResult: chipResult,
      beICCardInfo: beICCardInfo,
      beVerificationResults: beVerificationResults,
      beOcrResults: beOcrResults,
      bePhotos: bePhotos,
      beLivenessImages: beLivenessImages,
      isRegisterApplicationInfoSuccess: isRegisterApplicationInfoSuccess,
      ocrName: ocrName,
      ocrAddress: ocrAddress,
      ocrDateOfBirth: ocrDateOfBirth,
      ocrDocumentNumber: ocrDocumentNumber,
      ocrNationality: ocrNationality,
      ocrResidenceStatus: ocrResidenceStatus,
    );
  }
}

/// Wrapper ringkas untuk kasus gagal.
class KycErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final String? errorCode;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const KycErrorScreen({
    super.key,
    this.title,
    this.message,
    this.errorCode,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return KycResultScreen(
      isSuccess: false,
      title: title ?? 'Verifikasi Gagal',
      message: message ?? 'Terjadi kesalahan dalam proses verifikasi. Silakan coba lagi.',
      errorCode: errorCode,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }
}
